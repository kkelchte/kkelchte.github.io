---
title: Variance
layout: default
---

# Variance research on Canyon task

It is impossible to draw conclusions in the setting where variance is cluttering all the results.
Some variance on performance can be due to which machine it is running. Delays in tensorflow are different at different machines depending on graphics card, RAM, ... .

The reference model is a mobile-0.25 network trained from scratch with seed 123 offline on the canyon data with n_fc false and no auxiliary task.

```
for i in $(seq 0 9) ; do
	./condor_task_offline.sh -t variance_ref_$i  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc False --random_seed 512" 
	./condor_task_offline.sh -t variance_seed_$i  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc False --random_seed $((3+$i))"
	./condor_task_offline.sh -t variance_auxd_$i  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth True --n_fc False --random_seed 512" 
	./condor_task_offline.sh -t variance_imgnet_$i -m mobilenet_025  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc False --random_seed 512" 
	./condor_task_offline.sh -t variance_nfc_$i  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc True --random_seed 512" 
done

```

### Types of models:

* Reference: In the reference track a model of mobilenet 025 is trained from scratch. Differences among the models are for instance the evaluation on different machines.
* Different seeding: Instead of keeping the seed fixed at 123, here we use different seeds for the same architecture.
* Auxiliary Depth: The network is made more complex by adding an auxiliary depth prediction task.
* Imagenet pretrained: Instead of training from scratch the feature extraction part is pretrained with imagenet weights.
* Multiple frames in n_fc: The model is made more complex by predicting the control based on 3 consecutive features.

### Primal results

First test is checking whether doshico performs the same as during summer. In green you see the NAUX model and in blue the AUXD. The performance seems to be a bit worse than over the population in the paper, though the auxiliary depth is again a clear overall improvement.

\![Doshico variance]({{ "/imgs/17-12-20-doshico_auxd_naux.png" | absolute_url }})

The first results on different parameters as mentioned above with the color indicating what kind of model. It is remarkable to see that changing over different seeds seems to have a positive influence on the variance. Which does not make sense. The models of the different seeds where also evaluated on different condor machines resulting in different delays while the reference models were all evaluated on the same machine.

It is also remarkable to see how the imagenet pretrained weights has an overall good influence on the performance though a very bad impact on the variance.

\![Performance over population]({{ "/imgs/17-12-20-performance_over_population.png" | absolute_url }})

\![Variance in histograms]({{ "/imgs/17-12-20-variance_in_histograms.png" | absolute_url }})


### Flying throught 1 type of canyon

By Seeding both the canyon generator and the OUNoise file to a fixed number, we can make sure that the same canyon is generated. The experiment of above is repeated but with more models per parameter and only 1 canyon to fly through. Comparing the different trajectories in the same canyon might give a better intuition over the vairance of the different models.

\![the canyon for evaluation]({{ "/imgs/17-12-20-canyon.png" | absolute_url }})

The variance can also be due to severe overfitting. In that case a super simple model with only 3 conv layers might improve the stability a lot.

### Secondary results

The models learned from scratch over 80 episodes converge to a loss of 0.3 while the loss of the model initialized with imagenet converges to 0.17. This might explain the bad performance of all the models except the imagenet initialized model. Redo experiments with training for 160 instead of 80 episodes the models that are trained from scratch. 

### Gridsearch over reference model to see how much results can improve:

**Different learning rates vs weight decay vs dropout keep probability**

TODO: check convergence over different parameter settings
TODO: get scatterplots over results
=======
The variance seemed to be killed by: seeding from the same seed during offline training, evaluating in only **1 canyon**, ensuring that all models successfully trained over the **max number of episodes**. (The overwrite check often killed the offline training too early)

I trained 10 offline models with parameters (lr 0.1, bs 32). The offline training and validation loss were very similar. Varying over a range of 0.2 to 0.4, which corresponds to the variance 1 run experiences over different episodes. The variance in the online performance was due to **different delays on different physical machines**. Running all the 10 models on garnet (average delay of 0.007) made them fly 20 times successfully through the canyon.

**Online evaluation is now solely done on machine with very low delay: citrine, pyrite, opal, kunzite, iolite, hematite, amethyst, nickeline, garnet**

### Different validation canyons

The different basic models, starting from same seed, all successfully flew through different canyons.

| model | distance |
|-|-|
| redo_in_diff_canyons_0 | 44.7619722459 | 
| redo_in_diff_canyons_1 | 44.752768864 | 
| redo_in_diff_canyons_2 | 44.7220505948 | 
| redo_in_diff_canyons_3 | 44.729201301 | 
| redo_in_diff_canyons_4 | 44.7254554614 | 
| redo_in_diff_canyons_5 | 44.7355742225 | 
| redo_in_diff_canyons_6 | 44.7808028844 | 
| redo_in_diff_canyons_7 | 44.752506359 |

### Going over different models

| model | success rate|
|-|-|
|ref|10/10|
|auxd|7/7|
|n_fc|4/4|
|imgnet|3/3|
|auxdn|3/3|
|can_for_sac|62.86%|


Taking a side track with a gridsearch for each training task.

The gridsearch ended with these hyperparameters for the n_fc 3 architecture (naux):

* learning rate: 0.5
* batch size: 32
* drop out keep prob: 0.5
* gradient multiplier: 0.01

The variance over the success rate of models with different seeding is not resolved yet. The variance can be due to suboptimality of the hyperparameters, which can be due to strong overfitting. It does not relate to delays as for all forest and sandbox runs the average delays were 0.014, 0.015, 0.016, 0.017. Although in the forest case this might have lead to very different trajectories of which some resulted in a bump.

None of the networks were overfitting on the validation set.

| -----san  | success rate |
| variance_san_0 | 10 / 20 |
| variance_san_1 | 14 / 20 |
| variance_san_2 | 17 / 17 |
| variance_san_4 | 10 / 20 |
| -----for  | success rate |
| variance_for_0 | 15 / 20 |
| variance_for_2 | 9 / 11  |
| variance_for_4 | 17 / 20 |
| -----can  | success rate |
| variance_can_0 | 20 / 20 |
| variance_can_3 | 20 / 20 |
| variance_can_4 | 20 / 20 |

Redo with new hyperparameters specific to the environment:
sandbox: LR 0.1, BS 32, DO 0.75, GM 0.
forest: LR 0.5, BS 32, DO 0.25, GM 0.
Note that both are not training end-to-end anymore due to gradient multiplier 0.


### Redo doshico challenge with better evaluation

```
for i in $(seq 0 49) ; do
	WT=$(( 3*60*60*4 ))
	ME=$(( 3*5*100 ))
	./condor_task_offline.sh -q $WT -t doshico_auxd/doshico_$i -m mobilenet_025 -e true -n 20 -w "esat_v1 esat_v2" -p "--batch_size 64 --max_episodes $ME --learning_rate 0.1 --dataset overview --random_seed $(( 3000*$i+1539)) --n_fc True --auxiliary_depth True" 
done
```

Unfortunately, this turned out to work not so well:

|model|average distance|
|-|-|
|1-fc|3.600332783|
|naux|3.895112222|
|auxd|6.662699795|

Using multiple frames (n-fc) and auxiliary depth improves the average flying distance. The performance is still very low.

Using lower gradient multiplies, decreasing the learning rate for the imagenet-initialized feature extracting layers seems to be a good direction for generalization.


Difference from this summer: --> maybe this batchnorm fixing **did** help.
* no_batchnorm_learning True (TODO: implement)
* depth_weight 0.99 (TODO: implement)
* control_weight 0.01 (TODO: implement)
* lr 0.5
* do 0.5
* bs 16

