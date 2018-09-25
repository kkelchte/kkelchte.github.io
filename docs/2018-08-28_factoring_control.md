---
title: Factoring Control
layout: default
---


# This blog describes the experimental part of control factorization

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

## Grouping corridor settings and defining fragmented datasets

The radiator and poster objects are spawned in a corridor with one segment on left or right wall. 
The extension config is defined for both left and right in order adjust the variations in yaw, xpos and ypos of the oracle.

The vary primal exp configuration tries to place 10 posters and 10 radiators of different sizes and different shapes.
The width, height and bends of the variance corridor are kept the same as the have an influence on the control which would introduce a great advantage over the other models and so an unfair comparison.

 
| type of corridor | corridor_length | corridor_bends | corridor_width | corridor_height | corridor_type | extension_config | lights          | texture         |
|------------------|-----------------|----------------|----------------|-----------------|---------------|------------------|-----------------|-----------------|
| Goal corridor    |              10 |              5 |              3 |               3 |       normal  |      primal_exp  | default_light   | Gazebo/White    |
|Different corridor|              10 |              5 |            2.5 |               2 |       normal  |      primal_exp  | default_light   | Gazebo/White    |
| Straight         |               1 |              0 |              3 |               3 |       normal  |      empty       | default_light   | Gazebo/White    | 
| Bend             |               1 |              1 |              3 |               3 |       normal  |      empty       | default_light   | Gazebo/White    |
| Radiator_right   |               1 |              0 |              3 |               3 |       empty   | radiator_right   | default_light   | Gazebo/White    |
| Radiator_left    |               1 |              0 |              3 |               3 |       empty   | radiator_left    | default_light   | Gazebo/White    |
| Poster_right     |               1 |              0 |              3 |               3 |       empty   | poster_right     | default_light   | Gazebo/White    |
| Poster_left      |               1 |              0 |              3 |               3 |       empty   | poster_left      | default_light   | Gazebo/White    |
| Variance corridor|              10 |              5 |              3 |               3 |       normal  | vary_primal_exp  | default_light,  | Gazebo/White,   |
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

The factored controls are spread over different datasets:
radiator, poster, corridor, ceiling, arc, doorway, blocked_hole and floor.

The drone spawns in the first tile with some variance over its initial positions:

| normal  |  P | Uniform(-V:+V)  |
|---------|----|-----------------|
|x        |0   | 0.5             |
|y        |0   | 0.7             |
|z        |1.5 | 0.3             |
|yaw      |1.57| 0.523 or 30degr |

| left    |  P | Uniform(-V:+V)  |
|---------|----|-----------------|
|x        |-.2 | 0.25            |
|y        |0.3 | 1.0             |
|z        |1.5 | 0.3             |
|yaw      |2.09| 0.523 or 30degr |

| right   |  P | Uniform(-V:+V)  |
|---------|----|-----------------|
|x        |0.2 | 0.25            |
|y        |0.3 | 1.0             |
|z        |1.5 | 0.3             |
|yaw      |1.05| 0.523 or 30degr |

For each factor of control a dataset is collected of 100 runs for training and 10 for test and validation.
Some datasets have to be collected in different groups due to different settings.

Some are objects left and right each requiring 60 successfull runs:

* radiator
* poster
* blocked hole

Other types of extensions are divided according to straight vs bended corridors

* corridor
* ceiling
* floor

Or some types don't require any division

* arc
* doorway

The segmented dataset in numbers:

```bash
$ cdpilotdata
$ for world in combined_corridor ; do echo "| $world | $(while read l ; do echo $l ; done < $world/train_set.txt | wc -l) | $(while read l ; do ls $l/RGB ; done < $world/train_set.txt | wc -l) | "; done
```

| name | runs (train) | rgb (train) | 
|-|-|-|
| ceiling_straight | 36 | 1389 | 
| ceiling_bended | 34 | 1059 | 
| ceiling_total | 70 | 2448 | 
|-|-|-|
| corridor_straight | 36 | 1352 | 
| corridor_bended | 72 | 2712 | 
| corridor | 108 | 4064 |
|-|-|-|
| floor_straight | 12 | 1360 | 
| floor_bended | 105 | 2056 | 
| floor | 117 | 3416 | 
|-|-|-|
| radiator_right | 54 | 1022 | 
| radiator_left | 54 | 971 | 
| radiator_total | 108 | 1993 | 
|-|-|-|
| poster_right | 54 | 844 | 
| poster_left | 54 | 867 | 
| poster_total | 108 | 1711 | 
|-|-|-|
| blocked_hole_right | 54 | 1096 | 
| blocked_hole_left | 54 | 1049 | 
| blocked_hole_total | 108 | 2145 | 
|-|-|-|
| arc | 48 | 1309 | 
| doorway | 48 | 1296 |
|-|-|-|
| factorized_corridor | 705 | 16188 |
| combined_corridor | 976 | 285058 |
| small_combined_corridor | 55 | 17406 |
| varied_corridor | 1156 | 337756 |
| small_varied_corridor | 56 | 16270 |


currently training: blocked_hole, doorway, ceiling, combined_corridor

### Testing network in the real-world


Initial plan on Alienware:

```bash
$ update_git
$ sshfsopal
$ cp -r opal/docker_home/tensorflow/log/varied_corridor/mobile tensorflow/log/varied_corridor
$ cd tensorflow/log/varied_corridor
$ cat checkpoint
$ sed -i 's/esat\/opal\/kkelchte\/docker_home\/tensorflow\/log\/varied_corridor\/mobile/home\/klaas\/tensorflow\/log\/varied_corridor/' checkpoint
# try on alienware itself within gazebo environment
$ roscd simulation_supervised/python
$ python run_script.py -t test_online -g -e -p eva_params.yaml --robot drone_sim -m varied_corridor -pe virtualenv -w esatv1 --fsm console_interactive_fsm
```

Seems like drivers of nvidia are too old.

Switch to Sagarmatha with the aid of Bert. This runs fedora and mounts your own asgard home directory. Therefor the commands remain the same though now you are on a laptop with wifi to the drone.
Extra benefit is that the GPU has compute capability of 5 so it does not requires a tensorflow version compiled specifically for a slower gpu with compute capability 3.5.
A small note is that it does require you to manually activate the wifi from your keyboard (f2).

Because everything can run on ESAT you don't require two places for logging, two versions of your code, ... .

It however only has 4 cpu cores which makes running gazebo totally unfeasible, so only for testing on the real drone.

```bash
$ start_sing
$ source .entrypoint_graph
$ roscd simulation_supervised/python
$ python run_script.py -t real_world_test -g -e -p eva_params_slow.yaml --robot drone_real -m varied_corridor/mobile -pe sing --fsm key_nn_fsm -n 1

```

### Experimental results

It is so far unclear how good we can get with the ensemble v1 (dynamic) over different architectures. Therefore I group the results here:

Possible architectures mobile_imgnet, mobile_scratch, squeeze_v1, squeeze_v3, tiny, alex_v4. 
Each model is trained with 3 different seeds.

Now the models are trained with feature discriminator input and no action normalization.

For the best architecture the models are retrained with action normalization and potentially image discriminator input (this only fits now in tiny and mobile architecture).

Summarizing the results

__Offline results: accuracy test__

| architecture | Naive ensemble | Static ensemble | Dynamic Ensemble |
|--------------|----------------|-----------------|------------------|
|Mobile Scratch| 80%            | 75%             | 79%              |
|Mobile Imgnet | 86%            | 86%             | 88.5%            |
|Tiny          | 80%            | 79.5%           | 82%              |
|Alex_v4       | 85%            | 67%             | 84%              |
|Squeeze_v1    |                | 72%             | 80%              |
|Squeeze_v3    |                | 68%             | 70%              |


__Online results: corridor distance__

| architecture | Naive ensemble | Static ensemble | Dynamic Ensemble |
|--------------|----------------|-----------------|------------------|
|Mobile Scratch| 5.3            | 5.49            | 5.65             |
|Mobile Imgnet | 7.45           | 5.4             | 4.74             |
|Tiny          | 9.17           | 9.34            | 9.74             |
|Alex_v4       | 5.55           | 3.15            | 9.05             |
|Squeeze_v1    |                | 4.27            | 7.15             |
|Squeeze_v3    |                | 4.87            | 7                |

__Online results: esat distance__

| architecture | Naive ensemble | Static ensemble | Dynamic Ensemble |
|--------------|----------------|-----------------|------------------|
|Mobile Scratch| 12             | 11              | 9                |
|Mobile Imgnet | 18.4           | 17              | 13.99            |
|Tiny          | 20.74          | 27.9            | 17.33            |
|Alex_v4       | 23.4           | 7.16            | 10.8             |
|Squeeze_v1    |                | 3               | 14.4             |
|Squeeze_v3    |                | 3.94            | 17.2             |