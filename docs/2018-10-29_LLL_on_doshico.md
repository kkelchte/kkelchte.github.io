---
title: Lifelong learning applied to multiple domains
layout: default
---

## Background

In this set of experiments we explore the benefit of lifelonglearning when a robot first learns a task, like collision avoidance, in one domain afterwhich it goes to a second and a third domain. We want to see if the performance drops a lot on the tasks learned earlier.

By switching the order of the tasks and comparing the distances in importance weights we can see different tasks are more or less related.


<img src="/imgs/18-10-29_doshico.png" alt="doshico environments" style="width: 200px;"/>

In this case we assume that the domain forest and canyon are more related than the sandbox domain.
It is then interesting to see whether the relative benefit of using lifelong learning is bigger on tasks when the domains are further apart. 

We assume that there is sufficient capacity of the network to learn different tasks in different domains without having to overwrite old behaviors. This we can ensure by plotting the distribution over the importance weights.


## Implementation notes and todos

Added importance weights away in python format that is easily read in by results_in_pdf to plot histogram and added this to the report formation.
Added plot of validation accuracy against training accuracy.

## Pre tests:

Offline training on forest + online testing interactively

```
python main.py --discrete --dataset doshico_drone_forest --load_data_in_ram --log_tag LLL_doshico/forest --learning_rate 0.0001 --optimizer gradientdescent --update_importance_weights --batch_size 64 --max_episodes 100 --network tiny_v2
# in singularity
python run_script.py -t testing -pe sing -pp pilot/pilot -m LLL_doshico/forest -w forest -p eva_params.yaml -n 1 --robot drone_sim --fsm oracle_nn_drone_fsm -e -g
```

Offline continuation of training in canyon from pretrained forest model with lifelonglearning and testing online interactively

```
# without lifelonglearning
python main.py --continue_training --load_config --checkpoint_path LLL_doshico/forest --dataset doshico_drone_forest_canyon --log_tag LLL_doshico/forest_canyon_noLL --learning_rate 0.001 --optimizer gradientdescent --update_importance_weights --max_episodes 500
# with lifelong learning
python main.py --continue_training --load_config --checkpoint_path LLL_doshico/forest --dataset doshico_drone_forest_canyon --log_tag LLL_doshico/forest_canyon --learning_rate 0.001 --optimizer gradientdescent --update_importance_weights --max_episodes 500 --lifelonglearning --lll_weight 10
```


Learning curves training and validation accuracy with training accuracy in the new domain (canyon) and validation accuracy in the previous domain (forest).
<img src="/imgs/18-10-30_forest_canyon_learning_curve.png" alt="Learning curves training and validation accuracy" style="width: 200px;"/>

