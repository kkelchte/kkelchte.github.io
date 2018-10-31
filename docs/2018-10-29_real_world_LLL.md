---
title: Lifelong learning applied to Robotics
layout: default
---

## Background


<img src="/imgs/18-10-19_osb_yellow_barrel_world.jpg" alt="osb_yellow_barrel.world" style="width: 200px;"/>


## Setup

Launch turtlebot and export correct rosmaster uri in the .bashrc file:

```
#for small alienware
export ROS_MASTER_URI=http://10.42.0.16:11311
#for big alienware
export ROS_MASTER_URI=http://10.42.0.203:11311
```

Launch small alienware which should connect to hotspot automatically. 
For big alienware no need to use singularity only to set correct host and master uri with 203 instead of 16.
Set correct master uri path and launch ros core within singularity image:

```
start_sing
source .entrypoint_graph
export ROS_MASTER_URI=http://10.42.0.16:11311 && export ROS_HOSTNAME=10.42.0.16
roscore
```

Connect to turtlebot with ssh (pw departement)
```
ssh turtlebot@10.42.0.1
****
# starts robot, remote and raspicam (corresponding to wide angle camera as in simulation)
roslaunch turtlebot3_bringup turtlebot3_klaas.launch
```

Start neural network in run script in singularity

```
start_sing
source .entrypoint_graph
export ROS_MASTER_URI=http://10.42.0.203:11311 && export ROS_HOSTNAME=10.42.203

#roslaunch simulation_supervised_demo turtle_real.launch full:=true graphics:=true

roscd simulation_supervised/python
python run_script.py ...


``` 

