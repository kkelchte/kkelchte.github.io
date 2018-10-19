---
title: Lifelong learning applied to Robotics
layout: default
---

## Background

The goal in this experiment is to demonstrate the benefit of learning without forgetting.
If a model is trained in domain A or for task A afterwhich it is learned to perform in domain B or task B, it is most likely to perform worse when taking the model back to task A unless the model can be learned jointly on the two tasks.
Training jointly however is often not feasible especially when you have a robot that gradually learns when going from one task or experimental setup to another.
You don't want your model to forget relevant parts of the first task when learning the second.
If there happens to be a rainy day and the model actually gets better at driving a car autonomously, you obviously don't want it to start performing worse on a sunny day.

In a primal experiment we look at how well lifelong learning can make the model robust to domain changes.

## Experiment 1: Circle around barrel in simulation

_general idea: lifelong learning in simulation_

In a first set of experiments a neural networks learns to perform monocular collision avoidance in a simulated environment.
The model gets correct steering angles from a heuristic based on a lidar range finder.

- In domain A the color of the barrel is yellow and the shape is cylindrical.
- In domain B the color of the barrel is carton-brown and the shape is a box.

A demonstration dataset for two domains are gathered upon which a feed-forward neural network is trained. 
The network learns to clone the behavior of the heuristic.

There are three baseline models that are compared:

- nn_A is trained in domain A and evaluated in A and B
- nn_A_B is trained in domain A afterwhich it is finetuned in domain B and evaluated in A and B
- nn_A_B_ll is trained in domain A afterwhich it is finetuned in domain B with lifelong learning and evaluated in A and B

We expect model nn_A to perform best is A in comparison to the other two models unless there is too few data.
But more importantly, we hope to see a clear performance drop in domain A for model nn_A_B which is much less severe for model nn_A_B_ll.
The performance drop of nn_A_B will probably depend on how long the model is trained, on how much data, and so on...

_extension_

The same idea can be taken further to different domain shifts in order to see the benefit of lifelong learning over different setups:

- domain C has a different color on the outer walls
- domain D has different texture and shape of outer walls
- domain E has different lighting in comparison to domain A
- domain F has a different camera location

We can gradually increase the domain shift and see whether the benefit of lifelong learning mainly applies in small or big variations.

Training a model to learn a new task invokes forgetting of the previous task.
In some case this forgetting is catastrophical which means that the performance in domain A deteriorates and we need lifelong learning to the rescue.
However there are some cases in which learning a new tasks actually makes to model forget all the overfitted knowledge from the first domain. 
In these cases the forgetting is actually beneficial in both the first and the second tasks as the model learns to generalize better.
In which case a model is actually overfitting to irrelevant data is hard to detect.
Either way in simulation the setup is very controlled which means that any overfitting to domain A is probably combined with a better performance in domain A.

I would expect that the larger the domain shift the more forgetting will apply and the bigger the difference in performance when going back to domain A.

If too few data is avaible, the model is more likely to overfit to data-specific features not occuring in new online scenarios, so this might lower the influence of lifelong learning.
Conclusion: enough data will be required to overcome this potential overfitting. This message is mainly important for the second experiment.

## Experiment 2: Circle around barrel in real world

_general idea: lifelong learing in the real world_

A model pretrained in simulation, namely nn_A, is tested in the real world.
Adjusting the real world experiment (domain Ar) in order to get the best performance of nn_A. This is similar to callibrating the real world (Ar) towards simulation (A).

Data is collected in the real world setting with a heuristic in domain Ar and domain Br. The small r stands for real world.
Domain Ar corresponds to a yellow barrel and domain Br corresponds to a carton box.

The performance of the following models is compared:

- nn_A trained in domain A and evaluated in domain Ar
- nn_A_Ar trained in domain A and finetuned in Ar and evaluated in domain Ar and Br
- nn_A_Ar_Br trained in domain A and finetuned in Ar and finetuned in Br and evaluated in domain Ar and Br
- nn_A_Ar_Br_ll trained in domain A and finetuned in Ar and Br with lifelong learning and evaluated in domain Ar and Br

The first experiment is just to see how much of the pretraining in simulation is applicable to the real world.
Potentially the finetuning to domain Ar is not necessary if the knowledge can be transferred directly.

<img src="/imgs/18-10-19_osb_yellow_barrel_world.jpg" alt="osb_yellow_barrel.world" style="width: 200px;"/>
<img src="/imgs/18-10-19_osb_yellow_barrel_blue_world.jpg" alt="osb_yellow_barrel_blue.world" style="width: 200px;"/>
<img src="/imgs/18-10-19_osb_carton_box_world.jpg" alt="osb_carton_box.world" style="width: 200px;"/>


## Experiment 3: Online training

## Notes on implementation

_creating new simulated environment: osb.world osb_yellow_barrel.world and osb_carton_box.world_

In order to work with OSB and carton I added two materials to the gazebo.material file in /usr/share/gazebo-7/media/materials/scripts combined with the necessary pictures in the ../textures directory. I tested this first on the alienware laptop. Afterwhich I replaced the gazebo.material file in the singularity image by copying it to /root/... and moving it from /root to /../gazebo within the writeable singularity image. 

_slippery turtlebot_

I added a strong friction on the surface in order to overcome the strong slips and strange turns when the turtlebot is breaking. Though this does not seem to have a great influence.

```
<surface>
  <friction>
    <ode>
      <mu>100000.0</mu>
      <mu2>100000.0</mu2>
      <slip1>0.0</slip1>
      <slip2>0.0</slip2>
    </ode>
  </friction>
</surface>
```

_creating data with turtlebot steered by heuristic_

Create config files for the osb_carton_box and osb_yellow_barrel world. Max duration is set to 300s or 5min. X position varies from 0.3 to 0.6.
Ensure that one set of experts starts off in clockwise and the other counter clockwise. The heuristic moves at 0.3m/s.

```
$ python run_script.py -t test_turtle -n 1 -g -e --robot turtle_sim -pe sing -w osb_yellow_barrel -p params.yaml --fsm oracle_turtle_fsm --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 -ds
$ python run_script.py -t test_turtle -n 1 -g -e --robot turtle_sim -pe sing -w osb_yellow_barrel -p params.yaml --fsm oracle_turtle_fsm --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 4.71 -ds
```
Put it on condor:

```
for i in 0 1 2; do
 python condor_online.py -t rec_barrel_cw_$i --wall_time $((2*60*60)) -w osb_yellow_barrel --robot turtle_sim --fsm oracle_turtle_fsm -n 6 --paramfile params.yaml -ds --save_only_success --evaluation --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
 python condor_online.py -t rec_barrel_ccw_$i --wall_time $((2*60*60)) -w osb_yellow_barrel --robot turtle_sim --fsm oracle_turtle_fsm -n 6 --paramfile params.yaml -ds --save_only_success --evaluation --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 4.71
done
```

Combine it in a clean dataset:

```
$ python clean_dataset.py --startswith rec_barrel --destination domain_A --val_len 1 --test_len 1 --min_distance 1
$ python clean_dataset.py --startswith rec_box --destination domain_B --val_len 1 --test_len 1 --min_distance 1
$ python clean_dataset.py --startswith rec_blue_barrel --destination domain_C --val_len 1 --test_len 1 --min_distance 1
```

_Sidetrack for state-space shift_

If the networks dont perform well because of the state space shift from expert to student and lack of domain randomization, it will be good to gather data from a random policy with heuristic labels.

```
$ python run_script.py -t test_turtle -n 1 -g -e --robot turtle_sim -pe sing -w osb_yellow_barrel_blue -p random_slow.yaml --fsm nn_turtle_fsm --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 -ds
```

It is important however to remember that when creating a dataset from the random pilot the correct labels are in __supervised_info__ instead of __control_info__.
On the other hand it is also possible to define the label file in tensorflow with `--control_file supervised_info.txt`.

_Train on dataset and test in environment_

Once the data looks big enough and clean enough we can look at the network to train.
We train a discrete network of architecture mobilenet-0.25, initialized with pretrained imagenet weights.

The heuristic clips its turns at 0.6 instead of 1 and goes straight at 0.3m/s. It is only fair to apply the same types of turns and speeds when evaluating and training the networks.

Potential required extra parameter is `--normalize_over_actions`. 
I should check if I can load the data in my RAM (it should be as the task is simple), if so I should add `--load_data_in_ram`
Note that adding the speed and action_bound wont affect the learning as the networks just puts three outputs to one or zero.

```
$ python main.py -t test_nn_A --dataset domain_A --discrete --speed 0.3 --action_bound 0.6 --learning_rate 0.1 --max_episodes 500
$ python main.py -t test_nn_A_action_norm --dataset domain_A --discrete --speed 0.3 --action_bound 0.6 --learning_rate 0.1 --max_episodes 500
$ python main.py -t test_nn_B --dataset domain_B --discrete --speed 0.3 --action_bound 0.6 --learning_rate 0.1 --max_episodes 500
$ python main.py -t test_nn_B_action_norm --dataset domain_B --discrete --speed 0.3 --action_bound 0.6 --learning_rate 0.1 --max_episodes 500
```

Try it all out on condor

```
$ python dag_train_and_evaluate.py -t lifelonglearning/domain_A --wall_time_train $((3*60*60)) --wall_time_eva $((2*60*60)) --number_of_models 3 --loss mse --load_data_in_ram --learning_rate 0.1 --dataset domain_A --max_episodes 1000 --discrete --paramfile eva_params_slow.yaml --number_of_runs 3 -w osb_yellow_barrel --robot turtle_sim --fsm nn_turtle_fsm --evaluation --speed 0.3 --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
```



