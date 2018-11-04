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
If this works in simulation it could be performed in the real world with a drive back service.

```
# via train_in_singularity.sh
sing_exec_train_pilot
# interactively within singularity
python run_script.py -t test_train_online -pe sing -pp pilot/pilot -w osb_yellow_barrel -pe train_params.yaml -n 3 --robot turtle_sim --fsm nn_turtle_fsm -g --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
```

With specific tensorflow arguments:

```
epsilon: 0.
learning_rate: 0.01
optimizer: gradientdescent
speed: 0.3
action_bound: 0.6
discrete: True
empty_buffer: True
buffer_size: -1
```


### Incremental collision avoidance updating at loss plateau

If the loss is stable given the last X batches it means that the model is probably converged.
This can be checked first with the previous setup. See if a success is most likely at a loss plateau.


