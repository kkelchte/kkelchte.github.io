---
title: Open AI ROS
layout: default
---
## Links

[ROS documentation of package](http://wiki.ros.org/openai_ros)

## General Thoughts:

In this entry I would like to evaluate the ROS openai package in order to see which parts I might substitute in the simulation-supervised package.

The main advantages:

1. Step based gazebo interface that allows many open AI gym algorithms to plug in directly.
2. The opportunity to reset gazebo to a certain state avoiding the restart for each different simulation which makes in a lot of suboptimal error handling code obsolete as well as speed up the online training.
3. A general code structure that will be more generally accepted among researchers.
4. Step based usage of Gazebo will probably improve the stability of online learning.

My main concerns are:

1. The real world is parallel. By pauzing Gazebo you take a step further from the real world. Although this bigger bridge might not be my concern.
2. Using the structure of ROS-openAI will have to rearrage scripts as the training script seems to start it all. It is a bit unclear if this can be possible from a tensorflow-virtual environment. Or it will at least come with some environment debugging.

It would be most interesting to compare an RL algorithm in my setup with an RL algorithm in the openAI-ROS setting. 
In order to see if this gazebo-pauzing is really required. 
The advantage of my control-mapping steps is that it is directly applicable to the real world.
On the contrary, it does not allow a reset of the environment so it still requires a full shut down and restart of gazebo.

Looking at this, it appears that there is a great advantage of merging the two codes.
In this case, the gazebo-environment is used to pauze and reset the environment instead of just launching it.

In order to merge you can apply two strategies, namely going from feeding openAI-ROS into simulation-supervised or the other way around.
The benefit of the former is that you can gradually keep the code as it is.
On the contrary, the latter adapts the code to a structure that will be more accepted by overall research. 

## Playing around with OpenAI-ROS:

_installation_

Openai ROS is the core interace between the gym library which defines the environment conventions and gazebo.
The most important file is _gazebo_connection.py_ that makes the gazebo environment pauze inbetween steps.
Besides this file, the package also defines robot environments and task environments. 
The robot environments contain super classes with specific topics linked to a certain robot.
For example the parrotdrone_env defines the camera topics and links the land and takeoff command. 
But also some virtual commands are added which will be filled in by the task environment file.
In the task environments the initial pose and reward signal is defined for a specific task.
There is for instance a parrot_goto task translate the simulated task into a gym-environment in order to give the correct reward/done/init signals.

However besides the gazebo interface, robot - and task environment you need a few more things.
Most importantly you need a Gazebo description of your environment as well as robot which you can also download from bitbucket Public Simulations:
https://bitbucket.org/account/user/theconstructcore/projects/PS

And of course the training algorithms, which are grouped in the openai_examples_projects package on bitbucket:
https://bitbucket.org/theconstructcore/openai_examples_projects.git

It is a bit confusing that the demo models are not specifically mentioned as dependencies in the tutorials. 

```bash
$ start_sing
$ source .entrypoint_graph
# In singularity install openAI-ROS in a new catkin workspace on Opal
$ mkdir -p ros_open_ai_ws/src && cd ros_open_ai_ws && catkin_make
$ cd src
$ git clone https://bitbucket.org/theconstructcore/openai_ros.git 
$ git clone https://bitbucket.org/theconstructcore/openai_examples_projects.git
$ git clone https://bitbucket.org/theconstructcore/parrot_ardrone.git
$ cd ..
$ catkin_make
$ source devel/setup.bash --extend
# OpenAI GYM has to be installed into the singularity image in order to play around.
# Following the guidelines on the docker build blog.
$ pip install gym
```

_playing around with Parror AR Drone_


```bash
$ start_sing
$ source .entrypoint_graph
$ source ros_open_ai_ws/devel/setup.bash --extend
$ roslaunch my_parrotdrone_openai_example start_simulation.launch
$ roslaunch my_parrotdrone_openai_example start_training.launch
```

In order to make it work I had to explicitely define a type in the file:
parrotdrone_goto.py: `self.observation_space = spaces.Box(low, high,dtype=numpy.float32)`

For some reason the drone model would not load its mesh.

Reward evolution while training for 20 hours. 
There is a gradual increase in reward per episode though it is far from stable and 20 hours were not enough to reach the destination once.

<img src="/imgs/18-10/18-10-16_reward_my_parrot.png" alt="Reward evolution while training for 20 hours" style="width: 200px;"/>

