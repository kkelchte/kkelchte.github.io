---
title: Domain Free Autonomous Navigation
layout: default
---

## The Context of the Problem

Autonomous navigation for drones (land and aerial) is an open and quick evolving field. 
Drones are often equipped with camera's as they are lightweight, cheap and have no limited range.
Using the high dimensional camera input in a collision-free path planning algorithm requires a map building often based on SfM. 
These techniques however require robust feature tracking and no occludence of the camera.
Another approach is to estimate the desired control directly on the camera input.
In this setting reinforcement learning (RL) techniques can be applied in which the camera frame represents the current state.
A policy maps this state to a desired action, in our case a steering signal that avoids collision.
RL provides algorithms that train this policy to be optimal in that sense that it maximizes the cumulative future reward.
The policy however needs to be able to extract the state-space information from current and/or previous frames.
Because this input is high dimensional NxHxWxC (3x200x200x3=360000D), deep neural networks with convolutional layers are required to get a smaller (1000D) representation.
With the use of back propagation this smaller dimensional feature representation can be trained end-to-end. 
This means that the gradients that adjusts the policy or control prediction layers will flow back through the network all the way to the input.
The benefit of this end-to-end training is that the features will be most discriminative for having a good policy on the data the policy is trained.
The big drawback is that training both a good state-space representation as control prediction layers, makes training slow and data-hungry.
A second pitfall of the end-to-end training is the high chance to end up with features that are informative only on the data the policy is trained while incapable to generalize to new environments.
A direct solution to this problem could be to train on data obtained in the same environments used at test time.
This however would mean that a demonstrator has to collect a lot of data on that current location, which is often unpractible.
Besides that, a policy should not be trained solely in an offline manner as it will be doomed to recover from small mistakes at test time. 
On the other hand, letting an imperfect policy steer your robot in the real world is not a good idea due to the high chance of catastrophies to your robot as well as its environment.
Therefore we argue that _features relevant for the task and the environment should be extracted from the real-world demonstration, while the control prediction should be learned in a safe simulated environment._
Having a realistic simulated environment for a wide range of robotic control tasks, as they have for autonomous driving, is unrealistic when looking from a broader point of view.
Gazebo is for instance a simulator with strong physics engines behind it and a large variety of implemented robots. 
The provided environments however are very limited and far from environments we are looking for.
For example we want to train an office-assistant robot to navigate through the environment and look for things, guide people around, ... .
In this case it is still realistic to say that we overlay a floorplan and create a basic simulated environment.
It is however unrealistic to expect to generate the exact similar lighting conditions, textures, ... .
So we expect to have a basic 3D model that enforces the correct control on the robot to navigate successful around. 
However we don't expect to have an accurate distortion model of the camera sensor, lighting conditions or fancy graphical textures.
Due to the large domain shift between this training arena and the actual real world, we have to be carefull with training control end-to-end.
That is where this works comes in:
Are we capable of training control-prediction-networks end-to-end in a smart way so it can learn to understand the consequences of its actions in a training arena in such a way it will still take similar control decisions on very different appearing data.

In order to tackle this matter, we research two approaches:

1. By reasoning on the real environment we can extract basic important control relevant features like perspective lines or moving vertical lines. By exploiting the architecture we can make different decision layers focus on different types of features combined with an uncertainty prediction. Each policy then learns to focus on this specific link between detected potential catastroph and the required control. This is however not enough the cover the jump to a totally different domain. Therefore an embedding space is learned over the three different tasks with extra unsupervised learning, data augmentation and potentially the use of auxiliary tasks. Note that this approach has no idea of what the real world will look like. __The big assumption is that the embedding learned will actually find close enough mappings from the real world to simulated data. This is a great assumption and has to be researched, checking with nearest neighbor and t-sne the composition of this embedded space.__

2. In the other setting we assume that an expert has demonstrated a flight but we don't necessarily know what good features are to train your control prediction on, so we can't use strategy 1. In this case we want to adapt our features on the demonstrated data as much as possible and ideally learn to find a common embedded space between the demonstrated real-world data as well as simulated world. With the use of the recorded action sequence we can reenact the demonstration and find one-to-one mappings between the demonstration and a look-alike model in simulation. There is a big assumption here that we have a proper dynamics model of the real-world drone in simulation so providing the same action sequence actually results in similar flying behavior. GAN's allow us to learn auto-encoders and decoders that map from one domain to another. The same assumption and research question that this entails is how closely the learned embedding will be capable of mapping different control situations (ex near-collision) to the same location wether it comes from the simulated environment or from the real world. This has to be researched and can be evaluated quantitatively.

Comments:
The two approaches actually demands very different things from the embedding. 
In the first approach the embedding should emphasize certain types of dangers both in a simple simulator as well as the real world. The different policies are than expected to know how reliable this allerting feature is and what reactive control is most feasible. This expects a more generic low-level feature extraction that links simple control behavior to simple extracted collision-features with very basic cues. This makes me expect a shallow network with dense connections to do reasonably well. Auxiliary depth and optic flow prediction or pretraining will probably support the generalization of the embedding.
In the second approach higher level features will probably be acquired to reason on the demonstration and which control should be applicable to which moment in the task the robot is situated. In that sense, the main goal of the embedding is to get the look-alike simulation as similar as possible as real-world images. In this setting classic domain adaptation or transfer learning techniques could be applied with GAN's, CycleGans, variational auto-encoders. 

It will be important to further disentangle the two approaches to the same problem as the correct approach might be very different.


Personal remarque:
I think I should first 'solve' doshico on a turtlebot with an ensemble of policies, better pretraining and potentially using DAGGER again with maybe extra auxiliary tasks. This can at least demonstrate the benefits of training solely on low level features with simple models for tackling such a generic tasks as collision avoidance. The big smart-feature extraction research question does probably not lie in having the TCN pretraining step, but more the aspect of making the model as simple as possible but not simpler while still exploiting all pretraining/auxiliary data to urge the features to focus on what matters. 

In order to take the step from the turtlebot to a real drone an action-mapper should be created that learns to ideally map the action (+IMU) to a new action as to mimic the behavior of the turtlebot. This would require me to learn a bit more on the topic of drones dynamics and the dependency on how the turning speed should change, combined with the inclination, depending on the current speed. This again is a function approximator that could be learned in simulation and transfered to the real world given a good drone model.

In the second approach, the main research question/assumption lies in what can e2e dnn control prediction benefit from TCN-trained embeddings. What can and what can't it learn for the task of autonomous navigation.
In the same sense, it seems that it could be a direction to get the most out of a demonstration.


## Related Work

## Research Question

## Method

## Experiments

## Conclusion

