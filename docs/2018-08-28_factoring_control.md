---
title: Factoring Control
layout: default
---


# This blog describes a primal experiment of control factorization

The goal is fly through a corridor of length 10m, width 3m, height 3m and 5 bends. 
The corridor is decorated with radiators (3) and posters (5) of grey and blue color respectively.
This basic corridor is a primal goal.

A typical baseline model would generate these types of corridor models at random all combined, creating a big dataset upon which a DNN is trained with SL. 
We call this **direct base** as it is a baseline model that is directly trained on variants of the goal corridor.

In fact, it is recommended in literature to vary as much as possible to improve the generalization power of the DNN model.
To research this statement we introduce another baseline called **vary base** that is trained on variants of the goal corridor but with more variety by for instance varying over lighting and texture.

What we want to research is, whether we can train a DNN model on factorized environments that are more easily created, without a signifcance performance drop.
We hypothesize that a significantly smaller model can be trained on significantly less data to perform a task almost as good as the other baselines.
The ease with which these simple models can be created as well as the win in training time and data are some of the benefits of factorizing control prediction.
The model trained in a factorized fashion is referred to as **fact model**.

<img src="/imgs/18-08-28_gz.jpg" alt="Corridor Model Outsied" style="width: 200px;"/>
<img src="/imgs/18-08-28_gz_1.jpg" alt="Corridor Model Inside" style="width: 200px;"/>
<img src="/imgs/18-08-28_gz_2.jpg" alt="Empty model with poster" style="width: 200px;"/>
<img src="/imgs/18-08-28_gz_3.jpg" alt="Full corridor" style="width: 200px;"/>

## Grouping corridor settings

The radiator and poster objects are spawned in a corridor with one segment on left or right wall. 
The extension config is defined for both left and right in order adjust the variations in yaw, xpos and ypos of the oracle.

The vary primal exp configuration tries to place 10 posters and 10 radiators of different sizes and different shapes.
The width, height and bends of the variance corridor are kept the same as the have an influence on the control which would introduce a great advantage over the other models and so an unfair comparison.

 
| type of corridor | corridor_length | corridor_bends | corridor_width | corridor_height | corridor_type | extension_config | lights          | texture         |
|------------------|-----------------|----------------|----------------|-----------------|---------------|------------------|-----------------|-----------------|
| Goal corridor    |              10 |              5 |              3 |               3 |       normal  |      primal_exp  | default_light   | Gazebo/Grey     |
|Different corridor|              10 |              5 |            2.5 |               2 |       normal  |      primal_exp  | default_light   | Gazebo/Grey     |
| Straight         |               1 |              0 |              3 |               3 |       normal  |      empty       | default_light   | Gazebo/Grey     | 
| Bend             |               1 |              1 |              3 |               3 |       normal  |      empty       | default_light   | Gazebo/Grey     |
| Radiator_right   |               1 |              0 |              3 |               3 |       empty   | radiator_right   | default_light   | Gazebo/Grey     |
| Radiator_left    |               1 |              0 |              3 |               3 |       empty   | radiator_left    | default_light   | Gazebo/Grey     |
| Poster_right     |               1 |              0 |              3 |               3 |       empty   | poster_right     | default_light   | Gazebo/Grey     |
| Poster_left      |               1 |              0 |              3 |               3 |       empty   | poster_left      | default_light   | Gazebo/Grey     |
| Variance corridor|              10 |              5 |              3 |               3 |       normal  | vary_primal_exp  | default_light,  | Gazebo/Grey,    |
|                  |                 |                |                |                 |               |                  | diffuse_light,  |Gazebo/White,    |
|                  |                 |                |                |                 |               |                  | spot_light,     | Gazebo/Red,     |
|                  |                 |                |                |                 |               |                  |directional_light|Gazebo/Black,    |
|                  |                 |                |                |                 |               |                  |                 |Gazebo/Bricks    |
|                  |                 |                |                |                 |               |                  |                 | Gazebo/Grass    |
|                  |                 |                |                |                 |               |                  |                 |Gazebo/WoodFloor |


```bash
# Test on alienware the creation of data in goal corridor and envs [straight, bend, radiator_right/left, poster_right/left] and variance corridor
$ roscd simulation_supervised/python
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_goal_corridor --extension_config primal_exp --corridor_bends 5
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_straight_corridor --corridor_length 1
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_bend_corridor --corridor_length 1 --corridor_bends 1
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_radiator_right --corridor_type empty --corridor_length 1 --extension_config radiator_right --x_var 0.5 --x_pos 0.5 --y_var 2 --yaw_var 0.785 --yaw_or 1.178
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_radiator_left --corridor_type empty --corridor_length 1 --extension_config radiator_left --x_var 0.5 --x_pos -0.5 --y_var 2 --yaw_var 0.785 --yaw_or 1.96
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_poster_right --corridor_type empty --corridor_length 1 --extension_config poster_right --x_var 0.5 --x_pos 0.5 --y_var 2 --yaw_var 0.785 --yaw_or 1.178
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_poster_left --corridor_type empty --corridor_length 1 --extension_config poster_left --x_var 0.5 --x_pos -0.5 --y_var 2 --yaw_var 0.785 --yaw_or 1.96
$ for texture in Grey White Red Black Bricks Grass WoodFloor ; do \
  	for light in default spot diffuse directional ; do \
  		python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation -ds --robot drone_sim -w corridor -t test_goal_corridor --extension_config vary_primal_exp --corridor_bends 5 --texture Gazebo/$texture --ligths ${light}_light \
		done \
	done

# Test oracle in reused goal corridor and reused different corridor
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation --robot drone_sim -t test_corridor -w corridor --reuse_default_world
$ python run_script.py -p params.yaml -n 2 -g --fsm oracle_drone_fsm -pe virtualenv --evaluation --robot drone_sim -t test_different_corridor -w different_corridor --reuse_default_world
```

