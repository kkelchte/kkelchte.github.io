# Personnal ToDo for writing my PhD.

## short overview:

1. Brainstorm on different potential topics.
2. Order topics according to what is most required and link them with clear contributions.
3. Start writing a minimalistic thesis of parts I'm certain that should be included.
4. Build up a list of most required experiments supporting the contributions.
5. Go over the core and iteratively fill in gaps of research questions.

## 1. Potential topics / messages / contributions ranked

_Core messages + extensions_

- software implementation / integration with overview of required & potential modules in both real-world and simulation.
	- Definition of different test environments
	- Linking current framework with ROS-openAI

- General imitation learning: offline/online on-policy/off-policy supervised/reinforced: Stabilization of the learning method
	- Stabilization from offline to online with continual learning and MAS
	- Stabilization from off-policy to on-policy with policy mixing and recovery behavior:
		- Use of different noise models on the controls
		- Handling data imbalances in the labels with enough exploration / smart replay sampling / smart data-keeping
		- Link MAS with exploration/exploitation to stabilize online and on-policy reinforcement learning
	- Impacts of different experts vs no expert (collision / future depth)

- Architectural impacts: inputs, recurrency, discrete/continuous/representation-output, width, depth, pretraining fashion.
	- Linking the task complexity with architectural decision and validating with visualizations
	- Debugging guidebook: where it all can go wrong and how to avoid it using smart visualizations & regularizations & performance measures.

- Decreasing domain-depency with auxiliary tasks, background noise, domain randomization.
	- Learn to focus on what matters instead of to generalize over all that doesn't matter:
		- Use fancy noise masks to make policy learn to focus on wholes and fly through them while ignoring the front
		- Use fancy noise masks to make policy avoid obstacles while ignoring the background
		- See if a combination is possible and whether the models' focus is actually there were it should be
		- Explore influence of different noise models: uniform, OU, deep-dream

## 2. Linking chapter with clear contributions

1. Introduction
2. General setup and work flow: _explain working of our framework and link with tutorials_
	- (literature) Short overview of different simulators with advantages and disadvantages
	- Implementation: from tensorflow to ROS to real drone/turtle to gazebo to simulated robots to docker/singularity to condor
	- Basic simulation-supervised learning: (auto-)generate environment -> create expert with extra sensors -> generate data -> train offline -> test online without extra sensors
3. Learning Deep Policies: _compare imitation learning strategies with guidelines as results_
	- (literature) General to specific related work
	- Supervised/reinforced, Online/offline, On-policy/off-policy
	- Performance measures and task-difficulty measures
	- Concluding guidelines
	(- Learning multiple tasks sequencially vs jointly)
4. Architectural impact: _investigate influence of recurrency, inputs, outputs, depth, width, pretraining_
	- (literature) General deep learning and popular architectures, different types of outputs used
	- Go over variables and see impact on different types of tasks
	- Use visualization techniques to support your claims
	- Concluding guidelines
5. Step from simulation to the real-world: _compare different popular domain invariant techniques within your framework_
	- (literature) Related work handling domain shift and difference with domain adaptation
	- how does domain shifts differ
	- finding domain-independent policies by using auxiliary tasks, background noise, domain randomization
	- concluding guidelines
6. Discussion on applying end-to-end deep (reinforcement) learning on visual navigation tasks

Appendix: Proof-Of-Concept applying framework to autonomous rescue mission

## 3. Opening of different chapter -  linking the story

_Introduction_
Deep (Reinforcement) Learning is capable of outperforming humans on many games, recognizing over 1000 categories of objects with very high accuracy or even label each pixel of an image accordingly. This progress in combination with the continuous miniaturization of small robots provided with camera's, makes the question rise on how these wonderful AI techniques could be applied to small robots. Taking a step from the simulated games or static datasets to a real robot with all its restrictions. In this thesis we explore the feasibility of applying Deep Learnig to autonomous monocular navigation with such small robots like drones or cars.

_General Framework_
In order to apply Deep Learning methods on these robots we need a playground or simulator as well as a basic famework.
At the starting point of this PhD, few simulators were available combining DL with robotics: 
some were specific for autonomous driving (Udacity, GTA and later AirSim and CARLA); 
others for training RL algorithms on game-like environments (openAI Gym, DeepLab). 
However, at that time, none of them would provide enough freedom to easily create new environments and apply DL methods to different robots.
Therefore we build a framework ourselves combining ROS, Gazebo, Tensorflow and CUDA in a framework available as a docker/singularity image and ready to run on a cluster of computing machines. 
This framework is made publicly available combined with tutorials in the appendices for reproducing the results.

In this first chapter, the building blocks of the framework is explained together with their interfaces and finally demonstrating the total pipeline.

_Learning Deep Policies_
Now that the framework is explained together with the pipeline, it is still unclear on how the training of such DNN is best performed. 
There are several trends that can be displayed over different orthogonal axes, as shown in figure X.
One axes opposes online versus offline learning, in other words how i.i.d. the data is distributed. 
Intermediate algorithms from online to offline, are plausible with the use of a replay buffer of increasing size.
A second axes differs between off-policy versus on-policy, defining whether the neural network being trained is also collecting the data.
Again, combinations can be thought off by mixing the policy being learned with a demonstrating policy or an exploring policy.
A third axes ranks algorithms on how restrictive the learning signal is. 
On the one hand, there are reinforcement learning signals that provide a reward which the policy tries to accumulate as much as possible without telling the policy how exactly this is done.
On the other hand, there is a supervised signal which demonstrates the desired behavior showing exactly what is expected.
The latter is obviously more restrictive on both the optimal policy being found, the DNN will be as good as its teacher, as well as what types of tasks can be provided.
How well could you demonstrate for instance an optimal chess move?
A third group of learning signals are called unsupervised learning. 
In this case the input later in time provides information allowing the DNN to grasp something new.
The last group of algorithms I see as even more restrictive in what potential tasks can be learned.
However it comes with a clear advantage that the DNN learns solely from its input data and does not require a supervised or reinforced signal.
On these three axes, many different learning algorithms have been developed.
Comparing all of them for each separate simulated environment would overload us with data without making us much wiser. 
However, we do investigate several extremes on the axes and see if there are some overall trends we can translate in guidelines and good practices.

state contribution more clearly:

- self-supervised RL for collision avoidance 
- stable online learning

_Architectural Impact_
As shortly mentioned in ... a deep neural network consists of convolutional, dense and possibly recurrent layers.
In this chapter we dive deeper in the potential and drawbacks of neural architectures for the task of autonomous navigation.
Some general trends in deep learning suggest that deeper is better in generalization though takes longer to learn. 
Gradual increase in the third dimension of the network hand-in-hand with the decrease of feature maps towards a lower dimensional represenation appears to be a good idea.
However how many layers are minimal for a task without making the network oversized.
Feature map representations later in the network can grasp more complex patterns than in the beginning. 
However which patterns are required for collision avoidance and are they more relevant in the beginning or in the end?
Recurrent connections give the network memory, allowing it to make decisions not only on its current input but also on its internal state.
Is this beneficial in a reactive behavior like collision avoidance? 
Can it be exploited for more complex tasks requiring mapping and planning?
These questions will be responded as good as possible in this chapter. 
As a sidenote, a lot of the internal working of a neural network remains unclear and based on speculation. 
However, to support our claims we explain and utilize several visualization techniques allowing some insight.

_From Simulation to the Real World_
Gradually the complexity of training these neural networks was unfolded in the previous chapters.
However one important step remains to look at before we can apply DL to real robotic applications, namely the step from simulation to the real-world.
The simulator is different from the real world in many ways. Different simulators were also build for different purposes, all having a different idea of being accurate.
For instance, Drake is build to be very accurate in computing forces at different joints of a robot dynamically, on the other hand the atari room in the OpenAI Gym is resembling games with much less realistic forces, or CARLA is build to look as realistic as possible with strong sensor models that apply similar distortions making the world as photorealistic as possible. Gazebo provides an inbetween with the highest flexibility. If a very accurate robot model is provided the simulator can compute forces very accurately given enough computation time. On the other hand, it does also provide several more realistic scenes and models for everyone to use.
However stepping from the simulator to the real-world still comes with two major changes.
One is the model of the robot itself which acts only as accurate as the physics engine behind the simulator allows. 
Luckily drones move in the air, suposedly avoiding any contact, allowing them to behave close to linearly.
The second and most drastic change is how the environment appears. 
As monocular navigation is based on a camera, changing from a very basic simulated environment to the real-world drastically changes the input and so the domain. 
This change is also referred to as a domain shift as the distribution of the input of the DNN changes. 
Handling with this shift can be done by transferring knowledge from one domain to another or adapting your network towards a new domain.
In this chapter we again compare different strategies on feasibility in an autonomous navigation setting.

_Discussion_
Well, that all depends obviously. :-)

_Proof-of-Concept_
Let's do this for real!


