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

## 6. Test previous call from run_simulation_script.py loading params from local params.yaml file

Play with parameters: 

| tag | parameter |
|-|-|
| -t | log tag |
| -n | number of flights |
| -g | graphics |
| -ds | create dataset |
| -p | param file loaded with tensorflow |
| --robot | specify robot config file |
| -pe | specify python environment |
| -pp | specify python project |
| -w | canyon |
| -w | forest |
| --fsm | load the correct fsm configuration |
| -e | evaluate so no training of the network |

```bash
$ roscd simulation_supervised/python
# add tensorflow parameters in extra params.yaml
$ echo "epsilon: 1" > params.yaml
$ python run_simulation_script.py -t test_createds -n 5 -ds -p params.yaml --robot turtle_sim -pe virtualenv -pp q-learning/pilot -w canyon -w forest --fsm nn_turtle_fsm -e
```
