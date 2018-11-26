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

## Generate combined corridor

```
cd simulation_supervised_tools/python/generators
for texture in  Red Bricks WoodFloor White Grass; do python world_generator.py --output_file $texture --extension_config vary_exp --corridor_bends 5 --texture Gazebo/$texture ; done
```


## Experimental description


### Varying Corridor Sequence

_Broader idea_
Monocular collision avoidance is the task in which a robot navigates through its environment avoiding obstacles aimlessly.
This task can be trained in a self-supervised manner given a simple heuristic based on extra sensors who serves as an expert.
The deep neural network learns to imitate the expert by predicting the control of the expert, namely cloning its behavior.
Again, hardware or legal constraints might prevent the collection of all data seen at training time, urging the need for an online continual learning fashion.
Obvisously, the task of collision avoidance is best demonstrated in a variety of environments.
However, the network tends to forget what it has learned over time, especially when passing through new environments.
This impediment makes current setup excellent test for continual life-long learning.

_Architecture_
The network takes an RGB frame of 128x128 as input and outputs three discrete steering directions.
The architecture consists of 2 convolutional and 2 fully-connected layers with relu activations. 
The training starts with random initialization of the weights and continues with gradient descent on a cross-entropy loss without regularization.

_Simulation_
The experiment is done in a Gazebo simulated environment with the Hector Quadrotor model.
The heuristic is reading scans from a Lazer Range Finder and turns towards the direction with the highest depth-reading.
The demonstration goes through a sequence of different corridors that differ in texture, obstacles and turns, as visible in figure ....

_Training_
Different networks are trained over this sequence of data in a continual manner.
Every 10 steps a backward pass occurs and a loss is added to the loss window for detecting a loss plateau.
On a loss plateau, the importance weights are updated with a running average.
The hyperparameters are listed in the supplementary materials.
Figure ... demonstrates such plateaus as well as the updates of the importance weights. 

_Test_
<!-- Each experiment is run three times with different seeds-->
The performance of the different networks are validated on the total data sequence.
As shown in figure ..., the accuracy of the environment increases while the network is training on data from that environment.
However, it also demonstrates how online learning without continual learning tends to forget what it has learned in a previous environment.

### Real-World Proof Of Concept

In a final proof-of-concept experiment, we apply online continual learning on a turtlebot in a small arena in our lab.
A network pretrained on a similar simulated environment learns to circle around the barrel.
So far lifelonglearning methods has proven to be advantageous when big differences occur in the data.
However in this setup we show that the methods can have stabilizing effect when training online and on-policy.
So far the training occured off-policy which means that the network is not providing its own data while training.
In the current setup we let the trained network steer the robot.
In the mean time, an expert based on a Lazer Range Finder is providing steering directions.

On-policy learning tends to be more difficult as the data contains a lot of "stupid" states visited by the network rather than relevant states visited by the expert.
For example, if the network collides on the left side, the recent data teaches the network to turn right more often.
However, after crossing the arena and bumping on the right side, you still want the network to remember its mistakes made earlier.
Preserving acquired knowledge over time is crucial for on-policy online learning.

In figure ... is shown how indeed our method helps to learn faster as the average number of collisions are dropping faster than without continual learning.

### Baseline model:


__Initial scratch__ --> add validation step before online training and copy accuracies.


__Offline__ --> add validation step after offline learning

```
python main.py --load_data_in_ram --network tiny_v2 --discrete --learning_rate 0.01 --optimizer 'gradientdescent' --speed 1.3 --action_bound 1 --discrete --batch_size 60 --continue_training True --checkpoint_path 'tiny_v2_scratch' --owr --max_episodes 300 --log_tag online_off_policy/final_5a_offline --dataset online_test_sequence_5a 
```

__Online Joint__

```
python online_learning_3.py
```


### Debugging data inbalance of corridor:

Online accuracies of 'good' sequence averaged over different controls.

Corridor sequence 4A: Red - Brick - Wood - White

__LL__

| accuracy_left_A 0.846153846154 |  accuracy_right_A 0.581818181818 | accuracy_straight_A 0.900900900901 | accuracy_total_A 0.7762909762909763 |
| accuracy_left_B 0.30612244898  |  accuracy_right_B 0.266666666667 | accuracy_straight_B 0.985849056604 | accuracy_total_B 0.5195460574166774 |
| accuracy_left_C 0.901960784314 |  accuracy_right_C 1.0            | accuracy_straight_C 0.977168949772 | accuracy_total_C 0.959709911361805  |
| accuracy_left_D 0.875          |  accuracy_right_D 0.190476190476 | accuracy_straight_D 0.947368421053 | accuracy_total_D 0.6709482038429407 |

__FT__

| accuracy_left_A 0.974358974359 | accuracy_right_A 0.272727272727 | accuracy_straight_A 0.36036036036 | accuracy_total_A 0.5358155358155358 |
| accuracy_left_B 0.755102040816 | accuracy_right_B 0.0666666666667| accuracy_straight_B 0.63679245283 | accuracy_total_B 0.4861870534377273 |
| accuracy_left_C 0.980392156863 | accuracy_right_C 0.538461538462 | accuracy_straight_C 0.767123287671 | accuracy_total_C 0.7619923276651721 |
| accuracy_left_D 0.9            | accuracy_right_D 0.142857142857 | accuracy_straight_D 0.991228070175 | accuracy_total_D 0.6780284043441939 |

Corridor sequence 5A: Red - Brick - Wood - White - Green

| accuracy_left_A 0.692307692308 | accuracy_right_A 0.909090909091 | accuracy_straight_A 0.815315315315 | accuracy_total_A 0.8055713055713055 |
| accuracy_left_B 0.224489795918 | accuracy_right_B 0.833333333333 | accuracy_straight_B 0.915094339623 | accuracy_total_B 0.6576391562914474 |
| accuracy_left_C 0.764705882353 | accuracy_right_C 0.923076923077 | accuracy_straight_C 0.899543378995 | accuracy_total_C 0.8624420614750994 |
| accuracy_left_D 0.175          | accuracy_right_D 0.0            | accuracy_straight_D 0.978070175439 | accuracy_total_D 0.3843567251461988 |
| accuracy_left_E 0.84375        | accuracy_right_E 0.789473684211 | accuracy_straight_E 0.841628959276 | accuracy_total_E 0.8249508811621814 |

Corridor sequence 5D: Green - Wood - Brick - White - Red

| accuracy_left_A 0.46875        | accuracy_right_A 0.473684210526  | accuracy_straight_A 0.950226244344 | accuracy_total_A 0.630886818290069  |
| accuracy_left_B 0.960784313725 | accuracy_right_B 0.692307692308  | accuracy_straight_B 0.96803652968  | accuracy_total_B 0.873709511904516  |
| accuracy_left_C 0.448979591837 | accuracy_right_C 0.0333333333333 | accuracy_straight_C 0.97641509434  | accuracy_total_C 0.48624267316989683|
| accuracy_left_D 0.0            | accuracy_right_D 0.0             | accuracy_straight_D 1.0            | accuracy_total_D 0.3333333333333333 |
| accuracy_left_E 0.358974358974 | accuracy_right_E 0.0727272727273 | accuracy_straight_E 0.995495495495 | accuracy_total_E 0.4757323757323757 |


Corridor sequence 5E: White - Red - Wood - Brick - Green

| accuracy_left_A 0.025          | accuracy_right_A 0.0            | accuracy_straight_A 1.0            | accuracy_total_A 0.3416666666666666 | 
| accuracy_left_B 0.923076923077 | accuracy_right_B 0.4            | accuracy_straight_B 0.734234234234 | accuracy_total_B 0.6857703857703857 | 
| accuracy_left_C 0.960784313725 | accuracy_right_C 1.0            | accuracy_straight_C 0.872146118721 | accuracy_total_C 0.9443101441489837 | 
| accuracy_left_D 0.510204081633 | accuracy_right_D 0.933333333333 | accuracy_straight_D 0.900943396226 | accuracy_total_D 0.7814936037308006 | 
| accuracy_left_E 0.84375        | accuracy_right_E 0.947368421053 | accuracy_straight_E 0.882352941176 | accuracy_total_E 0.891157120743034  | 



Clean dataset to see if the control inbalance can overcome a lot:

```
import os
# read in control file
ctr=[(l.split(' ')[0], l.split(' ')[1], l.split(' ')[6].strip()) for l in open('control_info.txt','r').readlines() if l.startswith('0000')]
# remove where turn and speed is 0
del_list=[]
for c in ctr: 
    if c[1] == c[2]:
        del_list.append(c)
for c in del_list:
    ctr.remove(c)
# count right, left and straights

print 'straight ',len([c for c in ctr if float(c[1])==1.3 and float(c[2])==0])/float(len(ctr))
print 'left ',len([c for c in ctr if float(c[1])==0 and float(c[2])==1])/float(len(ctr))
print 'right ',len([c for c in ctr if float(c[1])==0 and float(c[2])==-1])/float(len(ctr))
# get straight images
straight_images=[]
images=[os.environ['PWD']+'/RGB/'+f for f in sorted(os.listdir('RGB'))]
for index, img in enumerate(images):
    tag=os.path.basename(img).split('.')[0]
    for c in ctr:
        if c[0]==tag:
            break
    if float(c[1]) == 1.3 and float(c[2]) == 0:
        print c, tag
        straight_images.append(img)
subsample=2
# remove all subsampled
for index,im in enumerate(straight_images):                            
  if index%subsample == 0:        
      print 'remove ',im                 
      os.remove(im)
# Copy left over images
images=[os.environ['PWD']+'/RGB/'+f for f in sorted(os.listdir('RGB'))]
last_tag=int(os.path.basename(images[-1]).split('.')[0])

from shutil import copyfile
last_tag=int(os.path.basename(images[-1]).split('.')[0])
ctr_file=open('control_info.txt','a')
for img in images:
    tag=os.path.basename(img).split('.')[0]
    for c in ctr:
        if c[0]==tag:
            break
    last_tag+=1
    print "copy {0} ".format(img, last_tag)
    des="{0}/00000{1:05d}.jpg".format(os.path.dirname(img), last_tag)
    copyfile(img,des) 
    ctr_line="00000{0:05d} {1} 0 0 0 0 {2}\n".format(last_tag, c[1], c[2])
    ctr_file.write(ctr_line)
ctr_file.close()
```

Results on cleaned dataset.

Data proportions:

|       | turns/straight| proportion    |
|-------|----------|--------------------|
| Brick | 294./511 | 0.5753424657534246 |
| Green | 307./492 | 0.6239837398373984 |
| Red   | 391/493. | 0.7931034482758621 |
| White | 260/530. | 0.4905660377358490 |
| Wood  | 275/501. | 0.5489021956087824 |

Overall is wood performing the best in 'easy' learning while white is performing the worst.
The inbalance of too much straight in white could cause the model to fail to learn.

### Final (?) set of experiments: how does LL do on the long run:

Create 10 different long corridors with enough variation and obstacles to ensure a variety of controls and enough learning convergence:

Things we can loop over:
| name            | options                                                                   |
|-----------------|---------------------------------------------------------------------------|
| wall texture    | CeilingTiled Red Black Bricks WoodPallet WoodFloor Blue Purple OSB  Green |
| wall_decoration | posters, radiators, random, blocked wholes                                |
| passway         | nothing, doorway, arc                                                     |
| ceiling         | nothing, ceiling, pipes                                                   |
| obstacle        | human, closet                                                             |
| lights          | spot_light, directional_light                                             |
| floor           | DarkGrey, Grey, White

Define 10 corridors and name them according to the texture on the wall:

| name                | wall_decoration  | passway | ceiling | obstacle  | floor      | lights            |  texture       |
|---------------------|------------------|---------|---------|-----------|------------|-------------------|----------------|
| corridor_tiled      | blue posters     | nothing | pipes   | bookshelf | DarkGrey   | directional_light |  CeilingTiled  |
| corridor_red        | blocked wholes   | arc     | ceiling | human     | DarkGrey   | directional_light |  Red           |
| corridor_black      | grey radiators   | doorway | nothing | nothing   | DarkGrey   | directional_light |  Black         |
| corridor_bricks     | black posters    | nothing | ceiling | bookshelf | DarkGrey   | directional_light |  Bricks        |
| corridor_woodpallet | red radiators    | arc     | pipes   | human     | Grey       | directional_light |  WoodPallet    |
| corridor_woodfloor  | green radiators  | doorway | ceiling | nothing   | Grey       | spot_light        |  WoodFloor     |
| corridor_blue       | yellow posters   | nothing | nothing | human     | Grey       | spot_light        |  Blue          |
| corridor_purple     | white posters    | arc     | pipes   | bookshelf | White      | spot_light        |  Purple        |
| corridor_osb        | blocked wholes   | doorway | ceiling | nothing   | White      | spot_light        |  OSB           |
| corridor_green      | black radiators  | nothing | nothing | human     | White      | spot_light        |  Green         |
