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

# Troubleshoot

Singularity shares the local network of the machine. This is problematic on condor when multiple jobs each using the network is running on the same machine on condor.
One way to overcome this issue is by making ROS publish only on one ip address for instance by setting the $ROS_IP and $ROS_HOSTNAME variables. After some debugging it seemed that even though I was urging separate nodes to work with different IP or machine tag, they failed to have permission to read or write to sockets on this different ip address. (127.0.0.100 for instance).

This made me look for a different, though uglier work around. That is avoiding a job to start on a machine where singularity is already running. Let's say rescheduling your own jobs on condor. This is how it worked out for me:

* Add a pre and post-script in your condor description

```
Should_transfer_files = true
transfer_input_files = /users/visics/kkelchte/condor/prescript_sing.sh,/users/visics/kkelchte/condor/postscript_sing.sh
+PreCmd = "prescript_sing.sh"
+PostCmd = "postscript_sing.sh"
when_to_transfer_output = ON_EXIT_OR_EVICT
```
	
* Prescript checks if token (/tmp/singlebel) exists which means that a job is already running and this job should be put on hold
	
	```
	#!/bin/bash
	ClusterId=$(cat $_CONDOR_JOB_AD | grep ClusterId | cut -d '=' -f 2 | tail -1 | tr -d [:space:])
	ProcId=$(cat $_CONDOR_JOB_AD | grep ProcId | tail -1 | cut -d '=' -f 2 | tr -d [:space:])
	JobStatus=$(cat $_CONDOR_JOB_AD | grep JobStatus | head -1 | cut -d '=' -f 2 | tr -d [:space:])
	RemoteHost=$(cat $_CONDOR_JOB_AD | grep RemoteHost | head -1 | cut -d '=' -f 2 | cut -d '@' -f 2 | cut -d '.' -f 1)
	# if [[ true ]]; then
	if [[ -e /tmp/singlebel ]]; then
		echo "[$(date +%F_%H:%M)] Singlebel exists on $RemoteHost" >> /users/visics/kkelchte/condor/out/pre_post_script.out
		echo "[$(date +%F_%H:%M)] Hold: ${ClusterId}.${ProcId}" >> /users/visics/kkelchte/condor/out/pre_post_script.out
		# put job on idle or hold for reason X
		while [ $JobStatus = 2 ] ; do
			ssh qayd /usr/bin/condor_hold ${ClusterId}.${ProcId}
			# ssh qayd /usr/bin/condor_hold -reason 'singlebel is taken.' -subcode 0 ${ClusterId}.${ProcId}
			JobStatus=$(cat $_CONDOR_JOB_AD | grep JobStatus | head -1 | cut -d '=' -f 2 | tr -d [:space:])
			echo "[$(date +%F_%H:%M)] sleeping, status: $JobStatus" >> /users/visics/kkelchte/condor/out/pre_post_script.out
			sleep 10
		done
		echo "[$(date +%F_%H:%M)] done" >> /users/visics/kkelchte/condor/out/pre_post_script.out
	else
		echo "[$(date +%F_%H:%M)] Create singlebel on $RemoteHost." >> /users/visics/kkelchte/condor/out/pre_post_script.out
		touch /tmp/singlebel
	fi
	```

* Postscript cleans up the singlebel

	```
	RemoteHost=$(cat $_CONDOR_JOB_AD | grep RemoteHost | head -1 | cut -d '=' -f 2 | cut -d '@' -f 2 | cut -d '.' -f 1)
	echo "[$(date +%F_%H:%M)] Clean up singlebel on $RemoteHost." >> /users/visics/kkelchte/condor/out/pre_post_script.out
	rm /tmp/singlebel
	```

* Jobs put on hold should be released regularly which is possible with periodic_release in your condor_submit file:

```
periodic_release = HoldReasonCode == 1 && HoldReasonSubCode == 0
```

* Todo: you can further avoid condor to reuse computers where it has tried earlier by adding the following in your condor submit file:

```
job_machine_attrs = Machine
job_machine_attrs_history_length = 4
previous_machines="target.machine =!= MachineAttrMachine0 && \
   target.machine =!= MachineAttrMachine1 && \
   target.machine =!= MachineAttrMachine2 && \
   target.machine =!= MachineAttrMachine3"
requirements = $previous_machines
```

Note that you'll have to combine the requirements in 1 statement.