---
title: Unit Tests with shell commands
layout: default
---

# Simulation Supervised Unit Tests

Simulation-supervised is a package of ROS-Gazebo-Tensorflow I maintain for my experiments. But as the package grows, it becomes more and more difficult to keep track of all different test settings.

As I just restructured an important part and gradually test all the different parts, I decided to keep track of each setting combined with the necessary shell commands.

The tests are performed in a developing stage so default settings might change along the way, but it is probably already very indicative for future debugging purposes.

Each of the four launch files (a simulated and real-world file for both the turtlebot and the drone) has extra lines to command out that will start extra visualization nodes for instace rqt_gui. 

For each environment parameters are loaded that evaluate a success/failure (maximum distance/duration). You can avoid this from happening by loading the debug.yaml file in config/environments in your launch file.

## 1. Turtlebot in simulated Canyon environment controlled by user console

Make sure that the user console is plugged in.
Package dependency: simulation_supervised, joy_node, klaas_robots, turtlebot3_description...
Node dependency: control mapping, fsm, load_params

```bash
# Load the parameters of the robot: turtlebot in simulation
$ roslaunch simulation_supervised load_params.launch robot_config:=turtle_sim.yaml
# In a new screen and after plugging the console
$ roslaunch simulation_supervised_demo turtle_sim.launch
```

## 2. Turtlebot in simulated Sandbox environment controlled by oracle

Dependency: simulation_supervised, klaas_robots, turtlebot3_description...
Node dependency: control mapping, fsm, load_params, depth heuristic

```bash
# Load the parameters of the robot: turtlebot in simulation
$ roslaunch simulation_supervised load_params.launch robot_config:=turtle_sim.yaml
# In a new screen and after plugging the console
$ roslaunch simulation_supervised_demo turtle_sim.launch world_name:=sandbox fsm_config:=oracle_turtle_fsm
```

## 3. Turtlebot in simulated Forest environment controlled by nn with depth heuristic as supervision

Dependency: simulation_supervised, klaas_robots, turtlebot3_description, tensorflow...
Node dependency: control mapping, fsm, load_params, rosinterface, depth heuristic

```bash
# Load the parameters of the robot: turtlebot in simulation
$ roslaunch simulation_supervised load_params.launch robot_config:=turtle_sim.yaml
# Go to tensorflow environment and load neural network in gpu
$ source $HOME/tensorflow/bin/activate && export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cudnn/lib64:/usr/local/cuda/lib64:/opt/ros/kinetic/lib && cd $HOME/tensorflow/pilot/pilot
$ python main.py --checkpoint mobilenet_025 --continue_training --online --log_tag test_coll_pred --network coll_q_net
# In a new screen 
$ roslaunch simulation_supervised_demo turtle_sim.launch world_name:=forest fsm_config:=nn_turtle_fsm
```

## 4. Turtlebot in simulated forest environment controlled first with console after which the oracle iterates with the drive back service

Dependency: simulation_supervised, klaas_robots, turtlebot3_description, joy_node...
Node dependency: control mapping, fsm, load_params, depth heuristic, drive back.

```bash
# Load the parameters of the robot: turtlebot in simulation
$ roslaunch simulation_supervised load_params.launch robot_config:=turtle_sim.yaml
# In a new screen and after plugging the console
$ roslaunch simulation_supervised_demo turtle_sim.launch world_name:=forest fsm_config:=console_oracle_db_turtle_fsm
```

## 5. Turtlebot in simulated canyon environment controlled by nn with depth heuristic as supervision while saving data.

Dependency: simulation_supervised, klaas_robots, turtlebot3_description, joy_node...
Node dependency: control mapping, fsm, load_params, depth heuristic, create dataset.

```bash
# Load the parameters of the robot: turtlebot in simulation
$ roslaunch simulation_supervised load_params.launch robot_config:=turtle_sim.yaml
# Go to tensorflow environment and load neural network in gpu
$ source $HOME/tensorflow/bin/activate && export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cudnn/lib64:/usr/local/cuda/lib64:/opt/ros/kinetic/lib && cd $HOME/tensorflow/pilot/pilot
$ python main.py --checkpoint mobilenet_025 --online --log_tag test_createds/tf --network coll_q_net
# In a new screen
$ roslaunch simulation_supervised_demo turtle_sim.launch world_name:=canyon fsm_config:=nn_turtle_fsm log_folder:=test_createds save_images:=true
```

## 6. Test previous call from run_script.py loading params from local params.yaml file

Play with parameters: 

| tag | parameter | note |
|-|-|-|
| -t | log tag |  |
| -n | number of flights |  |
| -g | graphics | fails due to animation object not shutting down |
| -ds | create dataset |  |
| -p | param file loaded with tensorflow |  |
| --robot | specify robot config file |  |
| -pe | specify python environment |  |
| -pp | specify python project |  |
| -w | canyon |  |
| -w | forest |  |
| --fsm | load the correct fsm configuration |  |
| -e | evaluate so no training of the network |  |

```bash
$ roscd simulation_supervised/python
# add tensorflow parameters in extra params.yaml
$ echo "epsilon: 1" > params.yaml
$ python run_script.py -t test_createds -n 5 -ds -p params.yaml --robot turtle_sim -pe virtualenv -pp q-learning/pilot -w canyon -w forest --fsm nn_turtle_fsm -e
```

## 6. Test previous call from run_script.py within singularity on fedora

In case of failure:

- ensure to load the sing environment
- if the robot fails to load probably a ros package is missing from the singularity image

```bash
# alias for next command: start_sing
$ cd /esat/opal/kkelchte/docker_home && singularity shell --nv /esat/opal/kkelchte/singularity_images/ros_gazebo_tensorflow.img
$ source .entrypoint_graph # or .entrypoint_xpra
$ roscd simulation_supervised/python
# add tensorflow parameters in extra params.yaml
$ echo "epsilon: 1" > params.yaml
# note that the python environment (-pe) is changed to sing
$ python run_script.py -t test_createds -n 5 -ds -p params.yaml --robot turtle_sim -pe sing -pp q-learning/pilot -w canyon -w forest --fsm nn_turtle_fsm -e
```

## 7. Create dataset with real turtlebot

Requirements: 

- test fsm config in simulation: `$ roslaunch simulation_supervised_demo turtle_sim.launch fsm_config:=console_nn_db_turtle_fsm full:=true graphics:=true`
- test run_script with nn with number_of_runs 1 (no interupt after 5min): `$ python run_script.py -t test_3state_fsm -p random_slow.yaml -ds --robot turtle_sim -pe virtualenv -pp q-learning/pilot -w maze --fsm console_nn_db_turtle_fsm -e -n 1 -g`
- run on real turtlebot

```
# setup correct environment
$ export ROS_MASTER_URI=http://10.42.0.203:11311 && export ROS_HOSTNAME=10.42.203
$ roscd simulation_supervised/python
$ python run_script_real_turtle.py -t test_real_turtle -n 1 -ds -p random_slow.yaml --fsm console_nn_db_turtle_fsm -e -g

```

## 8. Train and evaluate model on data

Train depth_q_net model with reference parameters: 

```
$ python --log_tag depth_q_net/ref --dataset canyon_turtle_scan
```

Evaluate in canyon:

```
# in singularity
$ python run_script.py -pe sing -p eva_params.yaml -n 10 -e -w canyon --fsm nn_turtle_fsm -m depth_q_net/ref -t depth_q_net/ref_eva
```


## 9. Create data in simulated maze but with driveback service

```
$ start_sing
$ source .entrypoint_xpra
$ roscd simulation_supervised/python
$ python run_script.py -t maze_simulated -n 1 -ds -p random_slow.yaml --fsm console_nn_db_turtle_fsm -e -w maze
# from new terminal and when everything is running
$ start_sing
$ source /opt/ros/$ROS_DISTRO/setup.bash
$ rostopic pub /go std_msgs/Empty "{}"
```