---
title: Depth-Q-Net: Future Depth Prediction as Value Function
layout: default
---
# Creating a Singularity Image to Reproduce Results

## Intro

Trying to reproduce the same results with DoShiCo was a mess. Gazebo got updated with different shadings, my drone model would have different inertia, tensorflow could not parse my arguments... I learned that having a singularity image with code for ROS gazebo tensorflow all up to date was not exactly helping in reproducing research results that were 5months old. In order to do that the code combined with the version of all the libraries has to be frozen together.

This is exactly what I describe here to do for Depth-Q-Net.

A normal singularity image combines:

- ROS with depending ROS packages
- Gazebo
- Tensorflow
- CUDA and Cudnn
- xpra

In order to reproduce all the results of this paper I'll have to add the following python codes to it as well:

- q-learning branch of github.com/kkelchte/pilot
- simulation_supervised of github.com/kkelchte/simulation_supervised in catkin workspace
- klaas_robots of github.com/kkelchte/klaas_robots in catkin workspace
- hector_quadrotor of github.com/kkelchte/hector_quadrotor in catkin workspace
- bebop_autonomy of github.com/kkelchte/bebop_autonomy in catkin workspace
- add source file for xpra and graph


## Installing everything in a docker image

```
$ sudo nvidia-docker run -v /home/klaas:/home/klaas -it --rm --name rgt kkelchte/ros_gazebo_tensorflow:latest bash
# echo 'create homedir'
# mkdir -p /code
# cd /code
# echo "copy drone_ws in from build catkin_ws (as build failed in docker)"
# cp -r /home/klaas/drone_ws . 
# source /opt/ros/kinetic/setup.bash
# source /code/drone_ws/devel/setup.bash --extend
# echo "Install simulation supervised in catkin_ws"
# mkdir -p /code/simsup_ws/src ; cd /code/simsup_ws/src
# git clone https://github.com/kkelchte/simulation_supervised
# cd ..; catkin_make; cd /code
# source /code/simsup_ws/devel/setup.bash
# echo "Add pilot"
# mkdir /code/tensorflow; cd /code/tensorflow
# git clone --single-branch -b q-learning https://github.com/kkelchte/pilot ; cd
# echo "Copy entrypoint to codedir"
# cp /home/klaas/source_files/docker/.entrypoint* /code
```

## Update docker image and create singularity image

```
$ sudo docker commit rgt kkelchte/ros_gazebo_tensorflow:depth-q-net
$ sudo docker login
$ sudo docker push kkelchte/ros_gazebo_tensorflow:depth-q-net
$ singularity build ros_gazebo_tensorflow_depth_q_net.img docker://kkelchte/ros_gazebo_tensorflow:depth-q-net
$ singularity shell --nv ros_gazebo_tensorflow_depth_q_net.img
```

## Test in singularity image

Start the image: 

```
$ singularity shell --nv ros_gazebo_tensorflow_depth_q_net.img
$> cd /esat/opal/kkelchte/docker_home
$> source /code/.entrypoint_graph
```

Test offline training from dataset mounted at /esat/opal/kkelchte/docker_home/pilot_data and log directory at /esat/opal/kkelchte/docker_home/tensorflow/log.

```
$> cd /code/tensorflow/q-learning/pilot
$> export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cudnn/lib64
$> python main.py --data_root /esat/opal/kkelchte/docker_home/pilot_data --summary_dir /esat/opal/kkelchte/docker_home/tensorflow/log/ --log_tag my_new_model
```

Evaluate trained network online in a canyon.

```
$> roscd simulation_supervised/python
$> python run_script.py -pe sing -p eva_params.yaml -m my_new_model
```

Train model on real-world data without collision.

```
$> cd tensorflow/q-learning/pilot
$> python main.py --data_root /esat/opal/kkelchte/docker_home/pilot_data -t my_new_model_on_real_data --dataset real_maze_coll_free
```

Evaluate on real turtlebot (after connecting to turtlebots Hotspot). 
Change your ip address according to the hotspot from 10.42.0.203 to 10.42.0.xxx.
Connect also the joystick.

```
$> export ROS_MASTER_URI=http://10.42.0.203:11311 && export ROS_HOSTNAME=10.42.0.203
$> roscd simulation_supervised/python
$> python run_script_real_turtle.py -pe sing -m my_new_model_on_real_data -e -g 
# let nn steer by pressing traingle on joystick.
# if you dont have a joystick start the evaluation by publishing /go 
$> rostopic pub go std_msgs/Empty "{}"
```


# Extra examples

## Continue online training of pretrained depth_q_net on real_maze dataset:

Trained networks:

```
$ turtle
$ roscd simulation_supervised/python
$ python run_script_real_turtle.py -ds -p cont_slow.yaml -m depth_q_net_real/scratch_0_lr09_e2e -t depth_q_net_real/scratch_cont_train
# visualize depth prediction
```


## Test trained network interactively on real turtlebot

```
$ sshfsopal
$ cp opal/docker_home/tensorflow/log/.. tensorflow/log/..
$ adapt tensorflow/log/../checkpoint
$ turtle
$ roscd simulation_supervised/python
$ python run_script_real_turtle.py -p cont_slow.yaml -m ... -e --fsm console_nn_db_interactive_turtle_fsm -g
$ rosrun image_view image_view image:=/raspicam_node/image/ _image_transport:=compressed
```
