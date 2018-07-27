---
title: Future-Depth Real-world experiment
layout: default
---

# Future-Depth As Value Signal Real-World preparation
In the reviews for the workshop paper there was an urge for demonstrating the benefits of future-depth as value function in the real-world. 

My real-world experiments failed probably due to an unfortunate setting that was just too hard for the network to comprehend.

This time I want to take a different approach, namely, train online in simulation with the exact same setup/code as in the real-world on alien-ware.
If the network is small enough and the environment easy enough, this should be doable within a few hours.

## 1 Create new gazebo enviromnent of a circular arena of 1m around 1 obstacle and a turtlebot

```
# use builder of gazebo to create model
# adjust model in world from model.sdf
$ gazebo 
# launch turtlebot with model to finalize world and test round.yaml params interactively
$ roslaunch simulation_supervised_demo turtle_sim.launch full:=true graphics:=true world_name:=round
# see if depth heuristic can drive through successfully by tweaking the speed in depth_heuristic
$ roslaunch simulation_supervised_demo turtle_sim.launch full:=true graphics:=true world_name:=round fsm_config:=oracle_turtle_fsm
```

## 2 Start online training in tensorflow with correct branched code

Start run_script.py for online training.

```
# get code
$ cd ~/tensorflow
$ git clone -b q-learning --single-branch https://github.com/kkelchte/pilot
# Create paramfile with correct speed and tensorflow settings
$ roscd simulation_supervised/python
$ cat > prep_real_world.yaml
epsilon: 1
speed: 0.3
CTR+D
# ensure correct arguments for robot, python_environment, python_prjoject, world
# n (number of runs) =1 ensures simulation is not quit after 5min
$ python run_script.py --robot turtle_sim -pe virtualenv -pp q-learning/pilot -w round -n 1 --fsm console_nn_db_turtle_fsm -t train_round --paramfile prep_real_world.yaml
# press traingle on console or publish go
$ rostopic pub /go std_msgs/Empty "{}"
```

