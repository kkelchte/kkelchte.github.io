---
title: Lifelong learning applied to Robotics
layout: default
---

## Online learning

There are different consensusses on online learning. The general idea is that there is a stream of data coming in which can not be stored so upon which a method is learned. In reinforcement learning one of the main contribution of DQNetworks was the use of a replay buffer. In this case the data is stored temporarily. Let's say the last 100 experiences (30FPS * 1/4 experience per frame * 100 / 60 = 13min). In the original work of DQN the replay buffer was 1M frames corresponding to 8 days of playing break out.
This is obviously quite some memory. In this setting we would like to work with smaller buffers and always updating the most recent frames.


## Discussion on online learning?

<!-- <img src="/imgs/18-10-19_osb_yellow_barrel_world.jpg" alt="osb_yellow_barrel.world" style="width: 200px;"/> -->


So there are two general open questions in the comparison of online learning and replay buffering:

One is how often do you take a gradient step: 
- after each frame, 
- after each set of frames filling a minibatch
- after each roll out.
Depending on how often you take a gradient step you might want to take multiple ones.

The other question covers given a replay buffer with multiple rollouts, how to sample a batch from this.
This can be done randomly or giving more recent experience prior or giving more difficult examples priority.

Rahafs implementation is a combination of both.
On the one hand it updates more often, namely each set of frames filling a minibatch.
On the other hand it keeps a second buffer with hard examples.

This combination should combine the advantage on one side of less data to be stored and being able to learn online. On the other hand a stability measure to keeping rare and informative examples a bit longer in the buffer allowing some more gradient steps in that direction.

I would like to have setup that smoothly can switch between the different setups. 
This means having one argument defining the gradient update: 'each frame', 'each batch' or 'each rollout'.

`--online_gradient_update frame/batch/time/rollout`

The core concept of having one replay buffer that stores the info and throws away old/unprioritized examples remains. If the replay buffersize == recency batchsize each batch will contain only most recent examples. However if we make the buffersize much larger and update at each rollout we get our current implementation.

`--buffersize 32 --batchsize 32`

Adding a hard replay buffer is an extension that can be seen appart in both situation. It does not directly relate with the original paper (prioritized experience replay) as it does not require batches to be sampled from large replay buffers.

`--hard_replay_buffer --buffersize_hard 32 --batchsize_hard 32`


_Conclusion_

The moment for a gradient update is intrinsically related to task. 
For faces recognition it occurs each time there is an unsupervised signal.
For learning to drive without collision it makes more sense to do it after a collision as that moment was very informative.
Each rollout some data is gathered upon which the network learns to act better. 
The goal is to have it not collide for some time. This minimum time could increment.
Whether the drive-back service is driving the robot to a stable state again or the simulated environment is restarted, gives a good moment to update the weights.

## Implementation steps for lifelonglearning

Adding a lifelonglearning situation means:

- detecting when the network has learned something
  - when loss variance is under a certain threshold as well as the value itself
  - when time before collision is above a certian threshold
- storing the star variables at 'freeze' moment
- calculating new importance weights
- averaging the new importance weights with the previous ones

Starting off from a test_branch that should be merged back to the main branch to avoid interference with current running condor jobs.


## First set of experiments

### Incremental collision avoidance updating at minimum time between collisions

After each success the importance weights are updated. By adding the lifelonglearning weight update you ensure the model keeps good information.
However you could make it incremental learning by incrementally increasing the minimum success time without collision.
For example defining 1 minute: `--minimum_collision_free_duration 60`. 
In order to speed up training you could increment this minimum dynamically online incrementally making the task harder and harder.

If this works in simulation it could be performed in the real world with a drive back service.
```
# via train_in_singularity.sh
sing_exec_train_pilot
# interactively within singularity without lifelonglearning
python run_script.py -t test_train_online -pe sing -pp pilot/pilot -w osb_yellow_barrel -pe train_params.yaml -n 3 --robot turtle_sim --fsm nn_turtle_fsm -g --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
# interactively within singularity with lifelonglearning
python run_script.py -t test_train_online -pe sing -pp pilot/pilot -w osb_yellow_barrel -pe LLL_train_params.yaml -n 30 --robot turtle_sim --fsm nn_turtle_fsm -g --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
```

With specific tensorflow arguments:

```
network: tiny_v2
epsilon: 0.
learning_rate: 0.01
optimizer: gradientdescent
speed: 0.3
action_bound: 0.6
discrete: True
empty_buffer: True
buffer_size: -1
batch_size: -1
break_and_turn: True
epsilon: 0.5
epsilon_decay: 0.1
#--- with lifelonglearning
lifelonglearning: True
update_importance_weights: True
minimum_collision_free_duration: 10
```


_Extenstion (only in the recent batch implementation)_

In the same way as hard negative mining of prioritized sweeping, you can keep the hard examples in a separate replay buffer for later.
This stabilizes the training as the final gradient is for some part influenced by some difficult examples.
The functionality is added with the `--hard_replay_buffer` flag and `--hard_batch_size 100` defining the number of hard examples kept.
The buffer used at training time creates a batch combining all the hard replay buffer with the recent samples in the normal buffer.

--> hard replay buffer could also be used to update importance weights

In case of a bigger replay buffer, I can apply prioritized keeping (similar to sweeping).


### experiments

_tests on Tuesday_
Training with a big replay buffer from which multiple batches are samples tends to learn. After 200 runs one model could drive for 12m without collision.
Earliest successes occur after 50 runs. 

Big buffer with lifelonglearning crashed due to no labels in buffer. Crash only occurs on condor. Not on Opal.

With emptying recent-buffer and keeping hard buffer, the model can learn a decent collision avoidance driving for 8m collision free after 52 runs.
It seems to train faster than with the big replay buffer though there is no longterm general trend towards longer collision free driving.
Including lifelonglearning in this setting had no clear influence but the weights were also not updated in a correct way (summing rather than averaging over the last two).

_test on Wednesday_
Found one bug that saved targets `[]` causing the model to crash.
A second tweak was the update of importance weights that now takes the average over current and previous version instead of summing up.
A third bug was that the star variables were not updated so only the initial params were maintained.

... redoing experiments on condor.

Overview of tensorflow parameter files:
- train_params_old.yaml: big buffer, no lifelonglearning
- LLL_train_params_old.yaml: big buffer, with lifelonglearning
- train_params.yaml: recent buffer, no lifelonglearning
- LLL_train_params.yaml: recent buffer, with lifelonglearning
- train_params_hard_replay.yaml: recent buffer, no lifelonglearning, with extra hard buffer
- LLL_train_params_hard_replay.yaml: recent buffer, with lifelonglearning, with extra hard buffer

Models are trained with epsilon 0.5 exploration which decays at a rate of 0.1.

## Paper set of experiments

In order to demonstrate the lifelonglearning setup we created a long circular corridor with three domains that transition smoothly.
A tiny_v2 network is pretrained on a dataset with large variance offline:

```
# Train
python main.py  --network tiny_v2 --discrete --speed 0.3 --action_bound 0.6 --load_data_in_ram --learning_rate 0.001 --optimizer gradientdescent --dataset varied_corridor_turtle --max_episodes 1000 --scratch --log_tag pretrain_varied_corridor
# Test online
python run_script.py -t testing -pe sing -pp pilot_online/pilot -m pretrain_varied_corridor -n 3 -w corridor --robot turtle_sim --fsm nn_turtle_fsm -p eva_params_slow.yaml -g -e --corridor_bends 5 --extension_config vary_exp
```
Online model performs pretty bad. Also turtlebot in simulation performs anyong counter steering that network fails to cope with. 
It is uncertain how much influence comes from the crappy distorted camera.

Continue training in this specific corridor with domain_ABC online using pretrained model.

```
# train_params.yaml:
network: tiny_v2
learning_rate: 0.01
optimizer: gradientdescent
speed: 0.3
action_bound: 0.6
discrete: True
empty_buffer: True
buffer_size: -1
batch_size: -1
break_and_turn: True
epsilon: 0.7
epsilon_decay: 0.1
update_importance_weights: True
minimum_collision_free_distance: 9
continue_training: True
load_config: True
```

```
# in singularity
python run_script.py -t online_corridor_ABC/test -pe sing -pp pilot_online/pilot -m pretrain_varied_corridor -w domain_ABC_smooth -p $PARAMS -n 1 --robot turtle_sim --fsm console_nn_db_turtle_fsm -g --x_pos 0 --x_var 0 --yaw_or 1.57 

```

Current issue is that the model keeps on turning without a forward speed. A forward speed in combination with a turn results in severe slipping.
Best is to do gradient updates each time recency buffer is full. Added option: `--online_gradient_update batch`.

After implementing this my model succeeded at training without any collision using finetuning and no hard replay buffer after only 20min.
In this case the setup seems too easy. 
One sollution could be to make the environment harder with for instance different textures on the wall or train from scratch.

Plot trajectory:

```
pos=[(float(l.strip().split(',')[0]),float(l.strip().split(',')[1])) for l in open('pos.txt','r').readlines()]
for i,p in enumerate(pos): plt.scatter(p[0],p[1],color=(1-i*1./len(pos),0,i*1./len(pos),1))
plt.show()
```

Training with hard replay buffer makes training step take 1.7 seconds, while with only a recent buffer this takes 0.014 seconds.
Decreasing the hard and recent replay buffer to sizes 10 and 20 decrease the delay to 0.8, still 6x slower...

Plot losses per domain
```
import matplotlib.pyplot as plt
f=open('xterm_python_2018-11-12_0542.txt','r').readlines()
losses={}           
colors=['r','g','b']                
for i,d in enumerate(['A','B','C']):                                                                   
    plt.ylim((0,5)) 
    losses[d]=[float(l.split(',')[5].split(':')[1]) if 'domain '+d in l else 0 for l in f if l.startswith('Step')]                             
    plt.plot(range(len(losses[d])),losses[d], color=colors[i])
    plt.savefig('losses_domain_'+d)
```

## Online learning on corridor

```
python online_learning.py --log_tag online_off_policy/FT_0 --random_seed 123
python online_learning.py --log_tag online_off_policy/FT_1 --random_seed 245
python online_learning.py --log_tag online_off_policy/FT_2 --random_seed 651

# LLL
python online_learning.py --log_tag online_off_policy/LL_1_0 --random_seed 123 --loss_window_length 5 --lll_weight 1
python online_learning.py --log_tag online_off_policy/LL_1_1 --random_seed 245 --loss_window_length 5 --lll_weight 1
python online_learning.py --log_tag online_off_policy/LL_1_2 --random_seed 651 --loss_window_length 5 --lll_weight 1

python online_learning.py --log_tag online_off_policy/LL_5_0 --random_seed 123 --loss_window_length 5 --lll_weight 5
python online_learning.py --log_tag online_off_policy/LL_5_1 --random_seed 245 --loss_window_length 5 --lll_weight 5
python online_learning.py --log_tag online_off_policy/LL_5_2 --random_seed 651 --loss_window_length 5 --lll_weight 5

python online_learning.py --log_tag online_off_policy/LL_10_0 --random_seed 123 --loss_window_length 5 --lll_weight 10
python online_learning.py --log_tag online_off_policy/LL_10_1 --random_seed 245 --loss_window_length 5 --lll_weight 10
python online_learning.py --log_tag online_off_policy/LL_10_2 --random_seed 651 --loss_window_length 5 --lll_weight 10

python online_learning.py --log_tag online_off_policy/LL_20_0 --random_seed 123 --loss_window_length 5 --lll_weight 20
python online_learning.py --log_tag online_off_policy/LL_20_1 --random_seed 245 --loss_window_length 5 --lll_weight 20
python online_learning.py --log_tag online_off_policy/LL_20_2 --random_seed 651 --loss_window_length 5 --lll_weight 20
```

