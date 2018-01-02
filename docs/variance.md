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

![Doshico variance]({{ "/imgs/17-12-20-doshico_auxd_naux.png" | absolute_url }})

The first results on different parameters as mentioned above with the color indicating what kind of model. It is remarkable to see that changing over different seeds seems to have a positive influence on the variance. Which does not make sense. The models of the different seeds where also evaluated on different condor machines resulting in different delays while the reference models were all evaluated on the same machine.

It is also remarkable to see how the imagenet pretrained weights has an overall good influence on the performance though a very bad impact on the variance.

![Performance over population]({{ "/imgs/17-12-20-performance_over_population.png" | absolute_url }})

![Variance in histograms]({{ "/imgs/17-12-20-variance_in_histograms.png" | absolute_url }})


### Flying throught 1 type of canyon

By Seeding both the canyon generator and the OUNoise file to a fixed number, we can make sure that the same canyon is generated. The experiment of above is repeated but with more models per parameter and only 1 canyon to fly through. Comparing the different trajectories in the same canyon might give a better intuition over the vairance of the different models.

![the canyon for evaluation]({{ "/imgs/17-12-20-canyon.png" | absolute_url }})

The variance can also be due to severe overfitting. In that case a super simple model with only 3 conv layers might improve the stability a lot.

### Secondary results

The models learned from scratch over 80 episodes converge to a loss of 0.3 while the loss of the model initialized with imagenet converges to 0.17. This might explain the bad performance of all the models except the imagenet initialized model. Redo experiments with training for 160 instead of 80 episodes the models that are trained from scratch. 
