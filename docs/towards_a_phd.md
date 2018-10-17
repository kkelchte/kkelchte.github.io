## 0. Summary / Abstract

In this work we explore the feasiblity of applying Deep Reinforcement Learning techniques to the task of monocular autonomous navigation of small robots in indoor environments.
In IROS 2018 more than one out of four papers were related to deep learning. 
After speech and computer vision, deep learning is finaly becoming a valid tool in robotics. 
Deep learning methods enable the robotics community to enrich there vision algorithms towards better understanding of the current state of the robot, for instance by estimating the egomotion of the robot.
On the other hand reinforcement learning allows the training of a control algorithm based on a reward signal without the need of accurate dynamic models.
However the amount of success stories combining deep learning as state extractor with end-to-end reinforcement learning is limited due to a number of challenges.
These challenges are researched in this work resulting in guidelines and good practices when designing deep neural network controller.
The first collection of design decisions tackle the implementation of the learning algorithm as well as how to use neural networks to represent an agent or controller.
In the second part we dive deeper in architectural decisions.
After exploring the first two regimes in simulation, a third strenuous part of this work handles on the step from simulation to the real world. 
Different techniques can be applied to transfer the knowledge from one domain, namely simulation, to the very different domain, namely the real world.
These three regimes of design decisions are taken together in a final proof-of-concept before we conclude this thesis with an extended discussion on the application of DRL in monocular navigation tasks.

## 1. Introduction

_General drones and general DRL_

Lightweight drones are becomming gradually more reliable and affordable. 

As they are not restricted to flat terrain as drivable robots, they are more agile and applicable in a wider range situations.

Indoor environments are especially difficult due to several reasons for instance narrow passages, turbulence from wind reflection and lack of GPS signal.

Building an autonomous controller that can navigate these drones with only limited computation power and limited sensor info is very challenging.

Collision avoidance is often solved with the use of extra sensors from which the depth of the obstacles can be estimated for example sonars, LIDARs or stereo-cameras. 

These extra sensors however limit the range of possible drones that can be used and decreases the maximum flight duration due to the battery limit.

In this work we will compare the benefits of different sensors over others.

In order to get usefull information from the high dimensional camera input, we rely on the deep convolutional neural network to extract a lower dimensional state representation.

Neural networks have the benefit to be trainable with any objective function with a simple gradient descent algorithm. 

_Autonomous Navigation split up_

Autonomous navigation is a broad concept that can be split into different tasks. 
Firstly collision avoidance makes the drone turn away from near obstacles like walls or chairs. 
A second task consists of maintaining a direction despite deviations from turbulences or obstacles.
The direction is often defined by intermediate waypoints along a planned trajectory.
The trajectory is the result of a path planning algorithm given a map of its environment and the coordinates of the destination.

Each intermediate task is usually solved in a classic control optimization problem but can be substituted by a trained neural network.
We will mainly focus on the first task, collision avoidance, because this task lies at the core of autonomous navigation.
Besides, the other task have a higher complexity resulting in more data and time required for training a neural network solving these tasks.

Our framework however is general enough to be applicable to the full autonomous navigation task which we will demonstrate in the penultimate chapter.
Because of the high amount of experiments required to finetune hyperparameters, it is best to start from one smaller task like collision avoidance.

_ambiguity of collision avoidance_

Although collision avoidance might seem straightforward and well defined, the task is surprisingly demanding.
Due to the variety of types and appearances of obstacles, as well as the variety of possible paths to pass these obstacles, the required training data becomes immense.
Only with the use of prior knowledge we are able to simplify this state space.


_specifications_

Bebop drone, turtlebot, singularity, ROS, gazebo, condor, ... 

## 2. Background and Related Work

_Drones and their dynamics for visual navigation_

TODO: follow TUM course and write required system dynamics of a quadcopter
It should contain:

- general idea of movements linked with the different speeds of the rotors.
- basic definition of low level PID controller?

_Learning algorithms_

- definition of general reinforcement learning
- definition of policy value function and markov decision process
- imitation learning (behavioral cloning, supervised learning)

_Deep Learning_

- Complex universal function approximators
- Overview of popular architectures: mobilenet, inception, alexnet, ...
- CNN and RNN nomenclature

_Technical setup_

- ROS - Gazebo - Tensorflow - Docker/Singularity - Xpra - Condor

## 3. Experimental Setup

In the introduction I explained how we will focus on training a robot to avoid collisions with the assumption that the differences in training algorithms and architectural design will be applicable to more complex tasks. 

There are two measures to define the difficulty of avoiding collisions in these environments. One is _traversability_ which corresponds to the average distance crossed before collision.
The other one is _..._.


__Collision Avoidance Environments__

_the box_
_the room_
_ESAT corridor_
_the canyon, forest and sandbox_
_the corridor_

__Performance Measures__

_success rate_
_collision free distance_
_imitation accuracy_

? more: minimum distance to an object ?

__Visualizations__




## 4. Learning Algorithms

## 5. Deep Architectural Engineering

## 6. Shifting to the Real World

## 7. Project X

A higher level control task like trajectory following for surveillance or inspection.
Creating a heuristic that can handle way points. Specifying a desired route between different obstacles. 
Taking for instance the rectangles for the autonomous indoor challenge as a reference.
The full autonomous navigation task demonstrated



## 8. Conclusions
