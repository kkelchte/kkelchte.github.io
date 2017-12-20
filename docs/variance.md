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
	./condor_task_offline.sh -t variance_ref_$i -m mobilenet_025  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc False --random_seed 123 --scratch True" 
	./condor_task_offline.sh -t variance_seed_$i -m mobilenet_025  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc False --random_seed $((115+$i)) --scratch True"
	./condor_task_offline.sh -t variance_auxd_$i -m mobilenet_025  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth True --n_fc False --random_seed 123 --scratch True" 
	./condor_task_offline.sh -t variance_imgnet_$i -m mobilenet_025  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc False --random_seed 123" 
	./condor_task_offline.sh -t variance_nfc_$i -m mobilenet_025  -e true -n 30 -w "canyon" -p "--dataset canyon --auxiliary_depth False --n_fc True --random_seed 123 --scratch True" 
done

```

### Types of models:

* Reference: In the reference track a model of mobilenet 025 is trained from scratch. Differences among the models are for instance the evaluation on different machines.
* Different seeding: Instead of keeping the seed fixed at 123, here we use different seeds for the same architecture.
* Auxiliary Depth: The network is made more complex by adding an auxiliary depth prediction task.
* Imagenet pretrained: Instead of training from scratch the feature extraction part is pretrained with imagenet weights.
* Multiple frames in n_fc: The model is made more complex by predicting the control based on 3 consecutive features.

### Primal results

![Doshico variance]({{ "/imgs/17-12-20-doshico_auxd_naux.png" | absolute_url }})
![Performance over population]({{ "/imgs/17-12-20-performance_over_population.png" | absolute_url }})
![Variance in histograms]({{ "/imgs/17-12-20-variance_in_histograms.png" | absolute_url }})


### Flying throught 1 type of canyon

By Seeding both the canyon generator and the OUNoise file to a fixed number, we can make sure that the same canyon is generated.