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


The method is the following: it adds a regularization term in the loss that overcomes a large change in weights that were important in the first task. Each parameter/variable of the network receives an importance weight which is defined by looking at the gradients over all the data of domain A. 
At starting to learn on domain B, the difference between the initial value and changed value for this parameter is weighted with its importance weight and added as a regularization. In other words it penalizes a strong variation of weight values that are important for domain A.

In a primal experiment we look at how well lifelong learning can make the model robust to domain changes.

## Implementation in tensorflow

The implementation entails several steps:

- add variables for the importance weights and save them with the model
- calculate the importance weights on data of domain A based on the calculated gradients
- save and load the importance weights with the model
- get the initial weights of the 'optimal' values for domain A
- add the regularization loss term corresponding to a weighted sum of the differents with original values.

In order to calculate the regularization term in the loss the network needs one set of importance weights and a copy of the old variable weights.
The importance weights are saved at the end of training in one domain and saved within the checkpoint.
The set of 'old' variables correspond to the optimal variables of all previous domains and are copied at the beginning of training a model for a new task.
The lifelong learning regularization loss term then punishes any differentiation from these optimal values in correspondence with the importance weight.

At the end of training a new domain the importance weights are added to the earlier importance weights.
They represent how much the capacity of the network is filled up while learning to perform in new domains.


## Discussion on an online version 

The power of inceremental learning is best visible in an online learning setting. 
In this case the network is adapting towards a self-supervised learning task for instance video prediction or control prediction. Because it does not have access to all the data seen previously, it is best that it remembers things learned earlier. For example a robot learning to navigate within an office, afterwards it adapts to a corridor but without forgetting the navigation skills in the office.

The hardest part in applying lifelong learning in an online setting is the split between different tasks. It is clear that when a network is learning, you don't want it to remember everything. There should be a period of adapting as good as possible to a new environment before it is seeing this adaptation as too important because in the last case you are actually regularizing to bad knowledge.

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


<img src="/imgs/18-10/18-10-19_osb_yellow_barrel_world.jpg" alt="osb_yellow_barrel.world" style="width: 200px;"/>
<img src="/imgs/18-10/18-10-19_osb_yellow_barrel_blue_world.jpg" alt="osb_yellow_barrel_blue.world" style="width: 200px;"/>
<img src="/imgs/18-10/18-10-19_osb_carton_box_world.jpg" alt="osb_carton_box.world" style="width: 200px;"/>



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

## Experiment 3: Online training

```
sing_exec_train_pilot
# or go into singularity simsup/python project to run script:
python run_script.py -t test_train_online -pe sing -pp pilot/pilot -w osb_yellow_barrel -pe train_params.yaml -n 3 --robot turtle_sim --fsm nn_turtle_fsm -g --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
```


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
Training curves in domain A (yellow barrel OSB) with and without action normalization:
<img src="/imgs/18-10/18-10-20_training_curve_domain_A_with_and_without_action_norm.png" alt="offline training curves domain A" style="width: 200px;"/>

There is no need for action normalization as the data is well spread over the different actions. There is also no need to train more than 300 epochs as the validation accuracy is well saturated.

Evaluate model in simulation:

```
# within singularity
$ python run_script.py -t testing -pe sing -pp pilot/pilot -m lifelonglearning/domain_A -w osb_yellow_barrel -p eva_params_slow.yaml -n 1 --robot turtle_sim --fsm nn_turtle_fsm -e -g --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
```

Evaluate model in the real world:

```

```

Try it all out on condor

```
$ python dag_train_and_evaluate.py -t lifelonglearning/domain_A --wall_time_train $((3*60*60)) --wall_time_eva $((2*60*60)) --number_of_models 3 --load_data_in_ram --learning_rate 0.1 --dataset domain_A --max_episodes 1000 --discrete --paramfile eva_params_slow.yaml --number_of_runs 3 -w osb_yellow_barrel --robot turtle_sim --fsm nn_turtle_fsm --evaluation --speed 0.3 --x_pos 0.45 --x_var 0.15 --yaw_var 1 --yaw_or 1.57 
```

See how finetuning forgets the previous domain:

```
cdpilotdata && mkdir domain_AB
cp domain_B/train_set.txt domain_AB
cp domain_A/val_set.txt domain_AB
cdpilot && python main.py --dataset domain_AB --checkpoint_path lifelonglearning/domain_A --load_data_in_ram --log_tag lifelonglearning/domain_AB --continue_training --max_episodes 300 --discrete --learning_rate 0.1
```

Implement LLL

_calculate importance weights on pretrained models_

In order to allow the model trained withouth calculating importance weights,
uncomment following line in __init__ function of model.py:
list_to_exclude = ["Omega"]


```
python main.py --update_importance_weights --max_episodes 1 --checkpoint_path lifelonglearning/domain_A --dataset domain_A --log_tag lifelonglearning/domain_A_omega --continue_training --load_config --owr
```

_load pretrained model with importance weights and train in new domain with lifelonglearning_

```
python main.py --update_importance_weights --max_episodes 300 --checkpoint_path lifelonglearning/domain_A --dataset domain_A --log_tag lifelonglearning/domain_A_omega --continue_training --load_config --owr
```


_train models on domain A from scratch without batch normalization_



```
python main.py --update_importance_weights --network tiny --max_episodes 500 --dataset domain_A --log_tag lifelonglearning/domain_A_tiny_lr001 --discrete --speed 0.3 --action_bound 0.6 --learning_rate 0.01 --load_data_in_ram
python main.py --update_importance_weights --network alex --max_episodes 500 --dataset domain_A --log_tag lifelonglearning/domain_A_alex --discrete --speed 0.3 --action_bound 0.6 --learning_rate 0.01 --load_data_in_ram
```

_finetune models in domain C (with validation from A) with and without LL_

```
python main.py --update_importance_weights --max_episodes 300 --dataset domain_AC --checkpoint_path lifelonglearning/domain_A_tiny --continue_training --load_config --log_tag lifelonglearning/domain_AC_tiny_LL --lifelonglearning
python main.py --update_importance_weights --max_episodes 300 --dataset domain_AC --checkpoint_path lifelonglearning/domain_A_tiny --continue_training --load_config --log_tag lifelonglearning/domain_AC_tiny_noLL
``` 

It seems that LL has not really an impact on training a tiny network for domain A and than C.

Debugging LLL :

| Tiny Version 0||
|---------------|-------------------------------|
| conv_1/kernel | 34.4516143799 (1677.64331055) |
| conv_1/bias | 56.5730171204 (3882.03662109) |
| conv_2/kernel | 83.1608657837 (13948.9580078) |
| conv_3/kernel | 0.488836139441 (0.681142449379) |
| outputs/kernel | 30.3255310059 (1789.23754883) |

Version 1:

- adding biases at layer 2 and 3,
- increasing conv3 from 20 to 60 channels from version 0.

|version 1      | 1 %               | 50 %             | 100 %         |
|---------------|-------------------------------|---|---|
| conv_1/kernel:0 | 0.0 | 0.0209853337146 | 13.4104738235 | 
| conv_1/bias:0 | 0.000116533400724 | 0.068588513881 | 26.4526062012 | 
| conv_2/kernel:0 | 0.0 | 2.8729316e-05 | 34.4239120483 | 
| conv_2/bias:0 | 0.0 | 1.25800824165 | 19.7109375 | 
| conv_3/kernel:0 | 0.0 | 0.0 | 20.0884895325 | 
| conv_3/bias:0 | 0.0 | 1.24238663912 | 4.42420768738 | 
| outputs/kernel:0 | 0.0 | 7.85297513008 | 39.6474113464 |

All the importances has decreased with an increase in complexity of the network on average as well as the variance.
The mean importance is dropped from 0.5 to 0.13 and the variance from 0.68 to 0.04.
It is of course unclear how much of the decrease of importance is due to the increase of the channel and how much is due to adding the biases.

Conv3 has 20x20 filters having 400 weights for all 60 channels. 
On the contrary conv1 and conv2 have 6x6 or 3x3 filters that corresponds to 36 or 9 weights for 10 and 20 channels correspondingly.

Version 2:

- change third conv layer into fully connected

|version 2|       | 1 %               | 50 %             | 100 %         |
|----|---|-|-|
| conv_1/kernel:0 | 0.0 | 2.0694159884 | 20.5786838531 | 
| conv_1/bias:0 | 0.000162490841467 | 2.78869257681 | 46.3988685608 | 
| conv_2/kernel:0 | 0.0 | 9.60830911936e-05 | 28.4184017181 | 
| conv_2/bias:0 | 0.0 | 3.85405147076 | 30.5794525146 | 
| conv_3/kernel:0 | 0.0 | 0.0 | 2.98759841919 | 
| conv_3/bias:0 | 0.0 | 0.242561176419 | 1.23395502567 | 
| outputs/kernel:0 | 0.0 | 2.13700377941 | 22.0174388885 |

<img src="/imgs/18-10/18-10-25_tiny_v2.png" alt="training curves domain forest with domain A as validation" style="width: 200px;"/>



Version 3:

- omitting third layer as it does not cary any importance.
|version 3        | 1 %               | 50 %           | 100 %         |
|----|---|-|-|
| conv_1/kernel:0 | 0.0               | 2.86850702763  | 24.1308441162 | 
| conv_1/bias:0   | 0.000353121575899 | 5.0508633852   | 22.3155937195 | 
| conv_2/kernel:0 | 0.0               | 0.262367263436 | 19.84623909   | 
| conv_2/bias:0   | 0.0129857982695   | 1.40598601103  | 16.2036933899 | 
| outputs/kernel:0 | 0.0              | 0.460116073489 | 9.48332977295 | 
| outputs/bias:0   | 0.618516955376   | 4.14057350159  | 4.93872261047 |


Learning curves:

-brown: no LL loss
-dark blue: 1w LL loss
-light blue: 10w LL loss
-pink: 100w LL loss

<img src="/imgs/18-10/18-10-26_accuracy_tiny3.png" alt="" style="width: 200px;"/>
<img src="/imgs/18-10/18-10-26_lll_loss_tiny3.png" alt="" style="width: 200px;"/>

Side track:
how much do the importance weights differ if I compute them on different data from the same domain.
The earlier table was on 100 batches of training data.

_validation data with batch one_
|version 3        | 1 %               | 50 %           | 100 %         |
|----|---|-|-|
| conv_1/kernel | 0.0 | 8.89598560333 | 73.1118545532 | 
| conv_1/bias:0 | 0.00180900966749 | 22.1998195648 | 67.0319061279 | 
| conv_2/kernel | 0.0 | 1.42106860876 | 45.9529457092 | 
| conv_2/bias:0 | 0.0529289674759 | 8.46519255638 | 39.4173278809 | 
| outputs/kernel | 0.0 | 2.17242789268 | 24.0413341522 | 
| outputs/bias:0 | 4.47321969986 | 11.6615533829 | 13.13048172 | 

_validation data with batch one_

|version 3        | 1 %               | 50 %           | 100 %         |
|----|---|-|-|
| conv_1/kernel:0 | 0.0 | 6.0346968174 | 53.2386322021 | 
| conv_1/bias:0 | 0.000681609995663 | 12.905441761 | 46.7749099731 | 
| conv_2/kernel:0 | 0.0 | 0.508252739906 | 43.0978088379 | 
| conv_2/bias:0 | 0.0164222687483 | 2.74863028526 | 34.4282493591 | 
| outputs/kernel:0 | 0.0 | 0.936828702688 | 20.2604408264 | 
| outputs/bias:0 | 1.07987051249 | 8.33191394806 | 10.6041984558 |




