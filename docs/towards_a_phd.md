## 0. Summary / Abstract

Although Deep Learning in robotics was viewed with scepticism compared to areas like speech or computer vision, it is rightfully becoming an accepted tool, as evidenced by one in four papers related to Deep Learning at the IROS conference 2018.
Deep learning methods enable the robotics community to enrich vision algorithms to better understand current robot state. Moreover, Deep learning combined with Reinforcement Learning, namely Deep Reinforcement Learning (DRL), allows control algorithms to be trained with a reward signal instead of accurate dynamic models. However DRL has had limited success due to a noumber of challenges, such as data hungeriness and local minima. Based on the analysis of these challenges, we provide guidelines and good practices for designing deep neural network policies.
The first set of design decisions described, compares versions of learning algorithms as well as how neural networks can represent an agent or controller.
The second set of design decisions identifies the networks architecture and hyperparameters.
A third design step handles on the knowledge transfer from simulation to the real world.
After bringing these three sets of design decision together in a final proof-of-concept, an extended discussion on the application of DRL in monocular navigation concludes this thesis.


## 1. Introduction

_drones are awesome and agile, autonomous controls are hard_
Drones are becomming more and more affordable and stable to fly. 
As they are not restricted to flat terrain as drivable robots, they are more agile and applicable in a wider range of situations.
Shark prevention at coastlines, building surveillance, victim search after natural disasters or bridge inspection are some classical examples.
Indoor environments have the difficulty of providing less free space, possible self-turbulence and often a lack of GPS coverage.
Outdoor environments on the contrary have natural wind turbulences, a wider range of textures and lighting, as well as more legal restrictions.
Building an autonomous controller that can navigate in this variety of situations remains very challenging. 
Especially because of a limited battery budget, the controller is only allowed to use limited computation power and lightweight sensors.
The camera with an IMU (inertia measurement system) is a popular combination of lightweight sensors.

_autonomous navigation has multiple layers of complexity_
Autonomous navigation is a broad concept that can be split into different tasks. 
Firstly collision avoidance makes the drone turn away from near obstacles like walls or objects. 
A second task consists of maintaining a direction despite deviations from turbulences or obstacles.
The direction is often defined by intermediate waypoints along a planned trajectory.
This trajectory is the result of a path planning algorithm given a map of its environment and the coordinates of the destination.

Autonomous navigation systems based on camera input traditionally build a map in which the robot tries to localize itself.
In combination with some points of interest selection within this map and path planning algorithm, the robot can follow waypoints along a trajectory. 
During the navigation, the robot simulatenously refines this map hand in hand with a better estimate of its own location.
In order to extract both the environment and its own movement within this environment, these algorithms use keypoints in the image to track.
However, tracking these keypoints and storing this map takes quite some processing time. 
Moreover in indoor environments it is often difficult to find proper features to track due to plain walls and narrow passages. 
Especially once the tracking is lost, the robot fails to localize itself within the map which results in having to start the map building all over again. 

In this thesis we explore whether we can substitute this metric based approaches with a machine learning approach based on deep neural networks.
Deep learning has demonstrated impressive results in fields like speech and computer vision. 
Task for which plenty of data is available, seems to be solved for example speech recognition or object detection.
Neural networks are capable of learning to extract those features most relevant for the task.
Moreover, if the network is recurrent, they are even capable of memorizing sequences and predicting the future based on the innerstate of the network.
These advantages make them very usefull for autonomous navigation. 
In this case we can look at it as a control prediction problem where a function is optimized to map the RGB input to a correct action.

Each intermediate task is usually solved in a classic control optimization problem but can be substituted by a trained neural network.
We will mainly focus on the first task, collision avoidance, because this task lies at the core of autonomous navigation.
Besides, the other task have a higher complexity resulting in more data and time required for training a neural network solving these tasks.

Our framework however is general enough to be applicable to the full autonomous navigation task which we will demonstrate in the penultimate chapter.
Because of the high amount of experiments required to finetune hyperparameters, it is best to start from one smaller task like collision avoidance.

Collision avoidance is often solved with the use of extra sensors from which the depth of the obstacles can be estimated for example sonars, LIDARs or stereo-cameras. 
These extra sensors however limit the range of possible drones that can be used and decreases the maximum flight duration due to the battery limit.
In this work we will compare the benefits of different sensors over others.

In order to get usefull information from the high dimensional camera input, we rely on the deep convolutional neural network to extract a lower dimensional state representation.
Neural networks have the benefit to be trainable with a simple gradient descent algorithm over an objective function. 

_Autonomous Navigation split up_



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

## 3. Simulation Supervised Learning - The Framework 

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
