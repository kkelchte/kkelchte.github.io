---
title: Lifelong learning applied to multiple domains
layout: default
---

## Background

In this set of experiments we explore the benefit of lifelonglearning when a robot first learns a task, like collision avoidance, in one domain afterwhich it goes to a second and a third domain. We want to see if the performance drops a lot on the tasks learned earlier.

By switching the order of the tasks and comparing the distances in importance weights we can see different tasks are more or less related.


<img src="/imgs/18-10/18-10-29_doshico.png" alt="doshico environments" style="width: 800px;"/>

In this case we assume that the domain forest and canyon are more related than the sandbox domain.
It is then interesting to see whether the relative benefit of using lifelong learning is bigger on tasks when the domains are further apart. 

We assume that there is sufficient capacity of the network to learn different tasks in different domains without having to overwrite old behaviors. This we can ensure by plotting the distribution over the importance weights.


## Implementation notes and todos

Added importance weights away in python format that is easily read in by results_in_pdf to plot histogram and added this to the report formation.
Added plot of validation accuracy against training accuracy.

## Experiments:

Offline training on forest + online testing interactively

```
python main.py --discrete --dataset doshico_drone_forest --load_data_in_ram --log_tag LLL_doshico/forest --learning_rate 0.001 --optimizer gradientdescent --update_importance_weights --batch_size 64 --max_episodes 100 --network tiny_v4
# in singularity
python run_script.py -t testing -pe sing -pp pilot/pilot -m LLL_doshico/forest -w forest -p eva_params.yaml -n 1 --robot drone_sim --fsm oracle_nn_drone_fsm -e -g
```

Pretests: offline continuation of training in canyon and sandbox from pretrained forest model with lifelonglearning

```
## Canyon
# without lifelonglearning
python main.py --continue_training --load_config --checkpoint_path LLL_doshico/forest --dataset doshico_drone_forest_canyon --log_tag LLL_doshico/forest_canyon_noLL --learning_rate 0.001 --batch_size 64 --optimizer gradientdescent --update_importance_weights --max_episodes 500
# with lifelong learning
python main.py --continue_training --load_config --checkpoint_path LLL_doshico/forest --dataset doshico_drone_forest_canyon --log_tag LLL_doshico/forest_canyon_LL --learning_rate 0.001 --batch_size 64 --optimizer gradientdescent --update_importance_weights --max_episodes 500 --lifelonglearning --lll_weight 10
## Sandbox
# without lifelonglearning
python main.py --continue_training --load_config --load_data_in_ram --checkpoint_path LLL_doshico/forest --dataset doshico_drone_forest_sandbox --log_tag LLL_doshico/forest_sandbox_noLL --learning_rate 0.001 --batch_size 64 --optimizer gradientdescent --update_importance_weights --max_episodes 500
# with lifelong learning
python main.py --continue_training --load_config --load_data_in_ram --checkpoint_path LLL_doshico/forest --dataset doshico_drone_forest_sandbox --log_tag LLL_doshico/forest_sandbox_LL --learning_rate 0.001 --batch_size 128 --optimizer gradientdescent --update_importance_weights --max_episodes 500 --lifelonglearning --lll_weight 10
```

Due to the instability of normal gradient descent we are obliged to increase batchsizes from 32 to 128.

Learning curves training and validation accuracy with training accuracy in the new domain (canyon) and validation accuracy in the previous domain (forest).
<img src="/imgs/18-10/18-10-30_forest_canyon_learning_curve.png" alt="Learning curves training and validation accuracy" style="width: 600px;"/>

## Results:

### Pretrained on Forest

__Canyon__

As averages over 3 models, the table shows models initiated with a model that can fly 100% through the forest.

|    | offline accuracy canyon | offline accuracy forest | online success canyon | online success forest | online distance canyon | online distance forest |
|----|-------------------------|-------------------------|-----------------------|-----------------------|------------------------|------------------------|
| FT |  94.92 (0.12)           |           84.48 (2.06)  |   100%                |     0%                |     50.01 (0.01)       |      34.26 (13.77)     |
| LL1  |   93.5                |           87            |    62%                |      50%              |      37.2 (19.3)       |      42.93 (11.26)     |
| LL10 |  93.47  (0.13)        |           87.19 (0.77)  |    83%                |     67%               |     45.57 (16.64)      |      42.85 (12.53)     |
| LL20 |  nan                  |           nan           |    0                  |        0              |         nan            |         nan            |

training LL10 for longer time...

Rahafs comment stated that due to the data change from smooth no_break_and_turn to break and turn once close to an object, the task became more difficult.
This difficulty makes it harder for the model to really comprehend the problem and saturate in a good minima which it can remember.
The less the model is 'sure' of its reasoning the harder it is to remember the earlier task.
However it does not mean that it clearly forgets it, the model is just more confused.
With the previous data, there was a clear difference between the forgetting (finetuning) and lifelonglearning. However with the new data this is no longer the case.
This could indicate a malfunctioning of the new data and hard to train from a step-based heuristic. 
If I can get a model evaluated in a smooth way and trained on smooth data to perform well, we can still use the old and smooth data.
Hacks in order to bypass the step based approach:
- control_mapping.py: put frame rate at 5FPS so control mapping does not invoke a hover
- use eva_params_no_break_and_turn.yaml rather than eva_params.yaml avoiding the neuralnetwork to use zero speed when turning.
--> the model succeeded 4/10 which means that although the data seems clearer the online performance is much worse.

An alternative solution would be to add noise in the depth heuristic of the forest and see if this makes the data better?
Or adding more data to it?


__Sandbox__

I made the dataset of the sandbox half the size so it fits in 32g ram.
If I add a weight decay regularization I can train a model (1 model) on the sandbox that performs 100% (5/5) success flights in the sandbox.
However if I train the sandbox with a forest-pretrained network with a normal learning rate (10E-3) finetuning outperforms lifelonglearning on both sandbox and canyon.
Finetuning for 1000 episodes reaches 100% success in the sandbox and 67% in the forest. If I train longer, the forgetting will probably be worse... .
However training for 1000 episodes with lifelonglearning reaches 0% success in sandbox and 20% in forest.

|1000| offline accuracy sandbox | offline accuracy forest | online success sandbox | online success forest | online distance sandbox | online distance forest |
|----|--------------------------|-------------------------|------------------------|-----------------------|------------------------|-------------------------|
| FT |         92               |           81            |    100%                |       67%             |     10                 |       48.22             |
| LL1  |       81.5             |           85            |     0%                 |      _33%_            |      6.3               |       38.05             |
| LL10 |       75.1             |           84.84         |     0%                 |       _0%_            |      8.75              |       42.22             |

Previous experiment is only done with one model instead of 3.

|3000| offline accuracy sandbox | offline accuracy forest | online success sandbox | online success forest | online distance sandbox | online distance forest |
|----|--------------------------|-------------------------|------------------------|-----------------------|------------------------|-------------------------|
| FT |         98.5             |           78            |     57%                |      _40%_            |      9.7               |       35.09             |
| LL1  |       90               |           82            |     57%                |       _0%_            |      9.2               |       _29.38_           |

Training for 3000 episodes makes the finetuned model overfit towards the training data performing worse in online evaluation of both sandbox and forest.
The performance drop in the forest doesn't seem to come from forgetting but rather from overfitting as the drop is of similar size in sandbox as in forest.

The LLL model succeeds at learning to perform better in the sandbox when trained for a longer time. Reaching a success rate of 60% which was 0% after 1000 episodes.
However it did forget how to perform in the forest significantly dropping much lower than the finetuning case.

The general trend of the two experiments is clearly that adding the lifelonglearning regularization term has a negative impact on training. 
The explanation for this comes from the notion that you can see the sandbox as kind of a more generic set of environment while the forest is more specific.

If you learn to perform well in the sandbox you grasped the notion of turning away from anything near and you might perform well in the canyon or the forest.
However if you learn to perform well in the forest, a very simple gray environment, and you train on the sandbox afterwards, having to keep the features that activate in the forest is actually causing you to remember unrelevant things. Things that are for instance related to the data seen at task one but not required to perform well on task one. 
You could say that you are overfitting to this first domain in such a way that learning the new domain becomes very difficult causing the model to learn something inbetweenish that is bad in both domains.
This inbetweenish learning is what causes the performance drop for having an LL term in the sandbox.

In order to verify this assumption we do the same setup in the other way around, namely from general to specific. 
A classic way where the new domain leaves out some information seen in the old domain.

A fast check is to see a model trained and performing well in the sandbox reaches already a 4/10 success rate (and not circling around) in the forest while the other way around only gets 3/10 success.
This is not a significant difference but the forest model could have some lucky shots in sandbox while this is harder the other way around.


### Pretrained on Sandbox

__canyon__

|1000  | offline accuracy canyon  | offline accuracy sandbox | online success canyon | online success sandbox| online distance canyon | online distance sandbox |
|------|--------------------------|-------------------------|------------------------|-----------------------|------------------------|-------------------------|
| FT   |         96               |           74            |    100%                |       0%              |      50                |       6                 |
| LL1  |         93               |           79            |    100%                |      67%              |      50                |       9.7               |
| LL10 |         92.7             |           78.3          |    100%                |      100%             |      50                |       9.99              |

__forest__

|1000  | offline accuracy forest  | offline accuracy sandbox| online success forest  | online success sandbox | online distance forest| online distance sandbox |
|------|--------------------------|-------------------------|------------------------|-----------------------|------------------------|-------------------------|
| FT   |         98.4             |           80            |    100%                |       33%             |     50                 |        8                |
| LL1  |         95.6             |           79.5          |     67%                |       50%             |     48                 |        9.6              |
| LL10 |         95.3             |           85            |    100%                |      100%             |     50                 |        9.99             |



### Pretrained on Canyon

__sandbox__

|1000  | offline accuracy sandbox | offline accuracy canyon | online success sandbox | online success canyon | online distance sandbox| online distance canyon  |
|------|--------------------------|-------------------------|------------------------|-----------------------|------------------------|-------------------------|
| FT   |         93               |           88            |    50 %                |       0 %             |      9                 |       31                |
| LL1  |         84.8             |           80            |    67 %                |       0 %             |      8                 |        9                |
| LL10 |         84.5             |           89            |    67 %                |       0 %             |      8.5               |       18                |

__forest__

|1000  | offline accuracy forest  | offline accuracy canyon | online success forest  | online success canyon | online distance forest | online distance canyon  |
|------|--------------------------|-------------------------|------------------------|-----------------------|------------------------|-------------------------|
| FT   |         97.7             |           83.6          |    100%                |        33%            |      50                |       40                |
| LL1  |         96.3             |           89.4          |     67%                |         67%           |      47                |       41                |
| LL10 |         96               |           91            |     67%                |         33%           |      45                |       28                |
