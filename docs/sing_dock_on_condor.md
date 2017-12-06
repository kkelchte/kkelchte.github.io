---
title: Running jobs on condor with docker or singularity
layout: default
---

# Running jobs on condor with docker or singularity

In general is a running docker container much more heavy than a running singularity container. Docker has its own network managing as well as other inner processes while singularity is much lighter. This has the drawback that Singularity uses the local network ip adress which results in intereferences between jobs. If 2 singularity jobs are running on the same machines the ip addresses collide. This is not possible with Docker as it shields the inside network from the outside.

The main difference in running jobs on condor with docker or singularity are:

* Location of nvidia-drivers and nvidia-library
	* Singularity: /.singularity.d/libs
	* Docker: /usr/local/nvidia/lib
* How the condor job is submitted (see bellow)

Just for clarity we go over the different steps of invoking the ros_gazebo_tensorflow environment

### Submitting a job on condor

In case of **singularity**:

```bash
Universe         = vanilla
RequestCpus      = 4 
Request_GPUs     = 1 
RequestMemory    = 3G
RequestDisk      = 19G

+RequestWalltime = 10800

Initialdir       = $temp_dir
Executable       = /usr/bin/singularity
Arguments        = exec --nv /esat/qayd/kkelchte/singularity_images/ros_gazebo_tensorflow.img $shell_file

Log 	           = $condor_output_dir/condor_${description}.log
Output           = $condor_output_dir/condor_${description}.out
Error            = $condor_output_dir/condor_${description}.err

Notification = Error

Queue
```

In case of **docker**:

```bash
Universe         = docker
RequestCpus      = 4 
Request_GPUs     = 1 
RequestMemory    = 3G
RequestDisk      = 19G
Docker_Image     = kkelchte/ros_gazebo_tensorflow:latest

+RequestWalltime = 10800

Initialdir       = $temp_dir
Executable       = $shell_file

Log 	           = $condor_output_dir/condor_${description}.log
Output           = $condor_output_dir/condor_${description}.out
Error            = $condor_output_dir/condor_${description}.err

Notification = Error

Queue
```

### Using XPRA as virtual graphics server

In order to run a job on condor, differently than running it interactively you need xpra.
This is setup in docker and singularity in the exact same way and grouped in the .entrypoint_xpra file:

```bash
export HOME=/esat/qayd/kkelchte/docker_home

export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:$((1 + RANDOM % 254))

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LD_LIBRARY_PATH=''

xpra --xvfb="Xorg -noreset -nolisten tcp \
    -config /etc/xpra/xorg.conf\
    -logfile ${HOME}/.xpra/Xorg-${DISPLAY}.log" \
    start $DISPLAY

sleep 3

# test
if [ $(xdpyinfo | grep GLX | wc -w) -ge 2 ] ; then
	echo "started xpra with GL successfully"
else
	echo "ERROR: failed to start xpra with GLX."
	echo "------xdpyinfo"
	xdpyinfo 
	echo "------ps -ef | xpra"
	ps -ef | grep xpra
	echo "------printenv"
	printenv
	exit
fi
```

### Sourcing the ROS environment and cleaning up the log folder

Also the environment variables are indepent of the docker or singularity variables.
```bash
source /opt/ros/$ROS_DISTRO/setup.bash
source $HOME/simsup_ws/devel/setup.bash --extend
source $HOME/drone_ws/devel/setup.bash --extend

# ROS_PACKAGE_PATH uses 'hard' coded /home/klaas dir in devel/setup.bash instead of $HOME
export ROS_PACKAGE_PATH=$HOME/drone_ws/src:$HOME/simsup_ws/src:/opt/ros/kinetic/share

export PYTHONPATH=$PYTHONPATH:$HOME/tensorflow/pilot
export GAZEBO_MODEL_PATH=$HOME/simsup_ws/src/simulation_supervised/simulation_supervised_demo/models

# add cuda libraries for tensorflow, is added at start_python_docker
# export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64:/usr/local/cudnn/lib64:$LD_LIBRARY_PATH
# export PATH=/usr/local/nvidia/bin:$PATH

echo "###########################\
# Clear ros log folder if it exists"
if [ -e /tmp/.ros ] ; then
	rm -r /tmp/.ros
fi
export ROS_HOME=/tmp/.ros
```

### Starting python with nvidia drivers

As the drivers are mounted on different locations in docker and singularity, different paths need to be loaded in the LD_LIBRARY_PATH:

* **singularity**: 

```
export LD_LIBRARY_PATH=$HOME/simsup_ws/devel/lib:\
	$HOME/drone_ws/devel/lib:/opt/ros/kinetic/lib:\
	/usr/local/cuda-8.0/lib64:/usr/local/cudnn/lib64:\
	/.singularity.d/libs
```

* **docker**:

```
export LD_LIBRARY_PATH=$HOME/simsup_ws/devel/lib:\
	$HOME/drone_ws/devel/lib:/opt/ros/kinetic/lib:\
	/usr/local/cuda-8.0/lib64:/usr/local/cudnn/lib64:\
	/usr/local/nvidia/lib64
```

### Differences between running singularity with graphics and docker with xpra

* DISPLAY=:0 for graphics and :$((10 + RANDOM % 244)) on xpra
* Location of CUDA and nvidia drivers which is relevant for tensorflow
	* This is dealt with by calling start_python_docker.sh or start_python_sing.sh in your simulation_supervised script.