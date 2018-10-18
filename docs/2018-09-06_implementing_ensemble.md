---
title: Ensemble Networks
layout: default
---

# Ensemble networks

If a network has to learn multiple tasks at once. You could train different networks together in an ensemble.
Training one network to perform all the tasks together might be suboptimal as for instance the control decision can be influenced by different aspects.
In this case you could separate the policy in different subpolicies that only learn to focus on a certain visual cue and try to get a best estimate given this visual cue.

There are different possibilities when creating an ensemble. 
We implement them in different branches of the github/kkelchte/pilot project.

### Preparation of a branched project

_Branching pilot from github_

```bash
$ cd /esat/opal/kkelchte/docker_home/tensorflow
$ git clone --single-branch -b ensemble_v0 git@github.com:kkelchte/pilot.git ensemble_v0
```

_Adjust scripts for default values_

Open the sublime project in the ensemble subfolder to ensure you are adjust the correct files.

In the launching scripts the default pilot-project arguments should change from pilot/pilot to ensemble_v0/pilot.
Besides the tensorflow/ensemble_v0 project should be loaded to python paths instead of tensorflow/pilot.

```bash
$ cd /esat/opal/kkelchte/docker_home/tensorflow/ensemble_v0/scripts
# see where pilot/pilot occurs
$ grep 'pilot/pilot' *.py *.sh
# change all occurences in shell and python files
$ for f in *.py *.sh ; do echo $f; sed -i 's/pilot\/pilot/ensemble_v0\/pilot/' $f; done
# test
$ grep 'pilot/pilot' *.py *.sh
# see where tensorflow/pilot occurs
$ grep 'tensorflow/pilot' *.py *.sh
# change all occurences in shell and python files
$ for f in *.py *.sh ; do echo $f; sed -i 's/tensorflow\/pilot/tensorflow\/ensemble_v0/' $f; done
# test
$ grep 'tensorflow/pilot' *.py *.sh
# change all occurences in shell and python files
$ for f in *.py *.sh ; do echo $f; sed -i 's/pilot\/scripts/ensemble_v0\/scripts/' $f; done
# test
$ grep 'pilot/scripts' *.py *.sh

```

_Make sure that the branch is updated_

See that you add ensemble_v0 to the list of updating directories in the .bashrc file.
You might want to add a 'cdpilot' alias for this branch with correct python path.

```
alias cdensemble="ldlib && source /users/visics/kkelchte/tensorflow_1.8/bin/activate && export PYTHONPATH=/users/visics/kkelchte/tensorflow_1.8/lib/python2.7/site-packages:/esat/opal/kkelchte/docker_home/tensorflow/ensemble_v0/pilot:/esat/opal/kkelchte/docker_home/tensorflow/tf_cnnvis; cd /esat/opal/kkelchte/docker_home/tensorflow/ensemble_v0/pilot; export HOME=/esat/opal/kkelchte/docker_home"
```

_Test locally on opal_

See that you adjust evaluate_in_singularity.sh to the correct model param.

```bash
$ ./test_train_evaluate.sh
```

_Test on condor from launch_

```bash
$ cdensemble
$ cd ../scripts
$ ./launch.sh
# python dag_train_and_evaluate.py -t test_canyon_tiny_mobile --not_nice --wall_time_train $((30*60)) --wall_time_eva $((60*60)) --number_of_models 1 --network mobile --normalize_over_actions --learning_rate 0.1 --dataset canyon_drone_tiny --max_episodes 30 --discrete --scratch --visualize_deep_dream_of_output --visualize_saliency_of_output --histogram_of_weights --histogram_of_activations --paramfile eva_params.yaml --number_of_runs 1 -w canyon --robot drone_sim --fsm oracle_nn_drone_fsm --evaluation --speed 1.3
```

### Ensemble V0

This is a mixture of experts setup with bagging (data splitting over different sets). 
The experts share the feature extracting part. They only differ in the last fully connected layer.
The number of outputs in the output layer is multiplied by the number of different factors.
When training different factors of control only the target output of that factor is non-zero while all other outputs are trained to be zero. 
This enforces the outputs that relate to a different control factor to remain zero at input from another factor.
At test time there are some ensemble options (statically) on how to extract the one output from the different experts.

- take overall maximum (unstable)
- average over the three discrete directions and take maximum taking all factor-outputs into account (too much variance)
- average over top 3 factors

_Implementation steps_

1. extract factors from dataset (data.py): `run_dir.split('/')[-2].split('_')`
2. increase number of outputs (model.py, main.py): `--n_factors 8`
3. adjust target according to factor (model.py): `factor_offsets={'radiator':0,'corridor':FLAGS.action_quantity, ...}`
4. extract final control at test time (model.py)

_Test current setup_

1. Train ensemble on radiator dataset (corresponding to one factor) if it saturates, compare online performance to original model trained on radiator. [ongoing]
2. Train ensemble on radiator and poster and see if performance is better or worse than radiator solely --> indicating potential of ensemble

_Extension_

`--non_expert_weight 0.1`

In the previous ensemble the different experts are trained to predict zero when it is not their expertise. 
This however might be confusing as 1 out of 8 gradients make the network predict 0. 
It might be better to have a loss that only calculates gradients for the output of the correct expert.
This is triggered with the `--single_loss_training` flag.
It weights all the losses of the outputs from the non-experts to zero for each sample in the batch.

This single loss training appeared to be a bad idea in the end. 
If an expert sees something during training that it predicts totally wrong it is not punished.
This means that at test time probably the largest outputs corresponds to the most wrong experts, which is of cours not what we want.
Besides the fact that having a separate softmax for each expert is not very convenient to implement. However implementing and testing did not show a big difference in results.

`--combine_factor_outputs max` or `weighted_output`

Max is defaults and listens only to the max output from all different experts. Weighted_output sums all 'left', 'right' and 'straight' together giving more weight to the experts that are more certain. Evaluating a primal model did not show any significant difference in online performance.


_Research Thought_

The selection of activations in the output layer is also not so trivial. There are 4 popular options, I list my thought for each one of them:

1. _No activation_ layer has the benefit that it does not pushes any hard prior to the network and allows it to learn anything. The disadvantage is that the one control-decision layer becomes linear which might be a strong restriction. The latter could be countered with an extra output layer.
2. _Tanh_ layer is ideal for the regression case where each expert should pick a value between -1 and 1. This is a correct hard prior that will probably speed up the training.
3. _Sigmoid_ layer squeezes the logits between 0 and 1 which makes comparison of different outputs from different experts easier while being non-linear. If an expert becomes very wrong by outputting a very large value, this will not be visible for the final decision layer.
4. _ReLu_ layer is very popular within the network, it however only is non-linear on '0' so does not really make the control decision that 'non-linear'. It does enforce a hard prior that the outputs should be positive which makes sense in the discrete case. But besides that there is not much influence over 'no activation'. Thinking further on clipping at zero, this might not be a good idea in my setup. Actually each expert learn collision avoidance. This means that over the different possible controls, the expert should become good at knowing which control _not_ to take. Therefore extreme negative values are actually informative. Clipping them away might be a loss of crucial information.

Conclusion, for the continuous control case I prefer the tanh layer. 
In the discrete case I will use _no activation_.

In the discrete case it is unclear whether it makes sense to use a softmax cross-entropy loss over all experts. 
The softmax normally makes from logits, probabilities by squeezing them between 0 and 1. 
Each expert should in theory predict a probability for picking a certain control. 
However if an expert is uncertain for each direction it is preferred that this expert predicts a low probability for all control values. 
In that case you want each expert to output a large value solely when it is certain. 
Looking from this point of view, having a loss that enforces this quiteness over uncertain experts and only enforcing one expert to predict the correct value with a _softmax cross-entropy loss_ can be a good idea.
Whether the output is normalized between 0 and 1 or 0 and number_of_factors does not matter as at test time the values are extracted in a discrete manner so the scaling is lost.

As an alternative you could maybe make all non-expers perdict -1 while the correct expert predicts 0 or 1, or the other way around.
Make all non-experts predict 0 as a neutral value, and the expert predict 1 or -1 as it is certain to go in that direction and certain to not-go in the other directions.
Although I think this latter tweaking will not improve the results that much.

_primal_test_results_
One network trained with mse-loss, pushing all non-experts to zero and evaluating with max over experts could succeed in the corridor.
With the extension to evaluate over the mean there was not much improvement.

One model succeed in flying through corridor number 2 which is  already promissing. Validation accuracy remains too low in general (70percent). 


### Ensemble V1

branched from v0

Go from static expert selection to dynamic. 
This means that it depends on the input image by training a gating function.
The discriminator is a small meta network that takes as input the image/embedding and outputs for each expert a weight.
This is trained as a classifier.

1. add discriminator net (model.py)
2. add discriminator loss (model.py)
3. add discriminator targets in batch (model.py)
4. adjust forward pass with discriminator weights (model.py)
5. initialize model with experts trained first. Second the discriminator trained keeping the feature extraction part fixed.

_Primal Results_
The training of the discriminator is succesfull and reaches 100%. The overal accuracy remains around 40%.

_Adjustment_
The discriminator loss initially just urged to discriminator to predict the correct data factor (radiator -> weight 1 for radiator-expert and 0 for all other experts).
This was changed to taking the weighted sum over the experts and punish a different in target output. 
The benefit of doing this, is that the discriminator might learn that the poster expert has some valuable output besides the radiator output. 
This makes the discriminator learn to value different experts according to the feature/input and seen outputs of these experts rather than solely predicting something impossible.
Having a clear radiator while an unclear arc passway might mean that the expert of arc passway should have more decision power than the radiator expert.
As the current test results are better than the primal test results, it seems that this adjustment was a good idea.

_Extension_
Make an option to use all activations as input for discriminator.

### Ensemble V2

branched from v0

1. For each factor a different network is defined. (model.py)

Current status:   
In continuous case loss and mse goes down.
In discrete case loss loss goes down though accuracy and mse stagnates ==> something is wrong in how accuracy and mse is calculated.


### Ensemble V3

branched from v0 but added v2.
Steps are identical.

### Ensemble V4

A fusion of v0 and v1 in which the experts differ more than only the output layer.
A gating as in V2 and V3 can be added.