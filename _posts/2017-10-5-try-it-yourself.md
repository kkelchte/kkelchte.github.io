---
layout: post
author: K. Kelchtermans
title: Try it yourself!
permalink: try
---

In order to use DoShiCo as a benchmark we made everything accessible. In the following steps we explain first how to get the general required software packages. The second step describes the comunication with the drone either in simulator or in the real world. The final step explains how you can reproduce our results published in [our paper]({{ "/assets/paper.pdf" | absolute_url }}).

<h2>1. Install ROS, Gazebo, Tensorflow, Nvidia</h2>
DoShiCo requires a combination of ROS (kinetic), Gazebo (7) and Tensorflow-gpu (1.11). Installing ROS is most convenient on a Ubuntu (16.4) operating system. The full installation can be tedious. Therefore we supply a docker image that can easily be pulled from the dockerhub page.

In order to run the docker image it is necessary to have a linux computer with docker installed. Preferrably the computer has a Nvidia GPU with the latest drivers (required for Tensorflow-gpu). If not, a local Tensorflow version should be installed for instance in a virtual environment. The docker image is labelled indicating it requires nvidia-drivers. <!-- In case you can't start it without, please contact me. -->

In case you have a Nvidia-GPU the <a href="https://github.com/NVIDIA/nvidia-docker" target="_blank">Nvidia-docker plugin</a> should be installed. 

Running the docker image with your home folder mounted and the local graphical session forwarded:
{% highlight bash %}
$ nvidia-docker run ...
# test docker image
# two $$ are use to indicate the bash within a docker image
$$ ls
{% endhighlight %}

The docker image has Xpra installed. This makes it possible to run applications without using a graphical session. The latter is especially suited in combination with a computing cluster where graphical sessions are often not allowed. In order to start the Xpra, you'll have to adjust the entrypoint in order to set the correct environment variables.
{% highlight bash %}
$ nvidia-docker run ... call entrypoint
{% endhighlight %}


<h2>2. Install ROS- and Tensorflow-packages</h2>
If all big software packages (ROS, Gazebo, Tensorflow) are installed or you could run the docker image successfully, you have the environment ready to clone the local ROS- and Tensorflow-packages for flying the drone with a DNN policy. The packages are depicted bellow and are grouped in the following way:

* <a href="https://github.com/kkelchte/hector_quadrotor" target="_blank">Drone Simulator</a> is a simulated version of the bebop 2 drone based on the Hector quadrotor package of TU Darmstad.
* <a href="https://github.com/kkelchte/simulated-supervised" target="_blank">Simulated-Supervised</a> is a ROS package forming the interface between the simulated drone and the DNN policy
* <a href="https://github.com/kkelchte/pilot_online" target="_blank">Online Training</a> represents the code block for training the DNN policy in an online fashion with tensorflow. The checkpoints are used and kept in a log folder.
* <a href="https://github.com/kkelchte/pilot_offline" target="_blank">Offline Training</a> represents the code block for training the DNN policy offline from offline data.
* <a href="https://homes.esat.kuleuven.be/~kkelchte/checkpoints/offl_mobsm_test.zip" target="_blank">Log</a> is a folder containing the latest checkpoints and is used during offline and online training.
* <a href="https://homes.esat.kuleuven.be/~kkelchte/pilot_data/data.zip" target="_blank">data</a> is a folder containing data captured by the expert in the DoShiCo environments and used for offline training.


![frontpage]({{ "/assets/img/project.png" | absolute_url }}){: .center-image }



<h4>Drivers</h4>



<h2>3. Reproduce Results</h2>

<!-- In order to reproduce the results there is a big package of ROS required called DoShiCo? / simulation-supervised. This package groups the DoShiCo environments in simulation-supervised-demo, the behavior arbitration control for supervision in a control subpackage and extra tools. The main simulation-supervised package contains scripts required to run the training over different training methods.... -->
<h3>Install DoShi</h3>

<h3>DoShiCo environments</h3>
Demo package of simulation-supervised

<h3>Simulation-Supervision</h3>
Behavior arbitration package and how to use it

<h3>Simulation-Supervision</h3>

![frontpage]({{ "/assets/img/frontpage.png" | absolute_url }}){: .center-image }
