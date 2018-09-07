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


### Ensemble V1

branched from v0

1. For each factor a different network is defined. (model.py)
2. A batch is dedicated to a certain network. (data.py)
3. In the backward pass only the loss of that factor is invokes. (model.py)
4. at test time see v0

### Ensemble V2

branched from v1

Go from static expert selection to dynamic. 
This means that it depends on the input image by training a gating function.
The discriminator is a small meta network that takes as input the image/embedding at outputs for each expert a weight.
This is trained as a classifier.

1. add discriminator net (model.py)
2. add discriminator loss (model.py)
3. add discriminator targets in batch (data.py)
4. adjust forward pass with discriminator weights (model.py)

### Ensemble V3

branched from v0 but added v2.
Steps are identical.

### Ensemble V4

A fusion of v0 and v1 in which the experts differ more than only the output layer.
A gating as in V2 and V3 can be added.