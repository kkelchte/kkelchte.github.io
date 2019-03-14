---
title: Reproduce Results
layout: default
---

# Neural Architecture Experimental Notes:

_NA: Compare realistic architectures_

| network | alex                 | squeeze              | tiny                 |
|---------|----------------------|----------------------|----------------------|
| LR      | 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001|
| BS      | ??                   | ??                   | ??                   |
| init    | scratch              | scratch              | scratch              |
| optim   | winner               | winner               | winner               |
| seed    | 123,456,789          | 123,456,789          | 123,456,789          |
| dataset | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  |

Justify step to scratch as hand crafted models do not have a imagenet pretrained checkpoint available.
The three models above are competing in performance on gradual smaller datasets.
Ideally a smaller model is less prune to overfitting and allows faster learning.
Handcraft different versions of tiny net according to pruning with importance weights.

_NA: Compare deep architectures_

| network | vgg16                | alex                 | incpetion            | res18                | dense                |
|---------|----------------------|----------------------|----------------------|----------------------|----------------------|
| LR      | 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001|
| BS      | 64                   | 64                   | 64                   | 64                   | 64                   |
| init    | imagenet             | imagenet             | imagenet             | imagenet             | imagenet             |
| optim   | winner               | winner               | winner               | winner               | winner               |
| seed    | 123                  | 123                  | 123                  | 123                  | 123                  |

Models are compared in the same setting. 
If a model fails to learn due to severe overfitting, overfitting is handled by regularization techniques (DO, WD, BN).
Regularized model is add to the validation learning graph.

_NA: VGG preparation_

| network | vgg16                |
|---------|----------------------|
| LR      | 0.1,0.01,0.001,0.0001|
| BS      | 32                   |
| init    | scratch, imagenet    |
| optim   | SGD, adam, adadelta  |
| seed    | 123                  |

_imagenet pretrained speeds up learning and decreases overfitting_
For VGG16 SGD from scratch / imagenetpretrained is compared over different learning rates.

_optimizers can increase learning rate without overfitting_
For VGG16 with SGD, ADAM and ADADELTA are compared for 'best' learning rate in pretrained setting.

Plot curves of validation accuracy and table final test accuracies with std over different seeds.

TODO:
- test proper batch size so model fits on 4G gpu
- estimate condor training time

```bash
for LR in 1 001 00001 ; do
  for OP in SGD Adadelta Adam ; do 
    name="vgg16_net/esatv3_expert_200K/$OP/$LR"
    pytorch_args="--network vgg16_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
     --continue_training --checkpoint_path vgg16_net_scratch --tensorboard --max_episodes 100 --batch_size 32\
     --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer $OP"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_rec $((100*2*60+3600)) --rammem 6 --gpumem 7000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
```




_NA: Influence of data normalization on Alexnet_

| network | alex                 |
|---------|----------------------|
| LR      | 0.1,0.01,0.001,0.0001|
| BS      | 100                  |
| init    | scratch              |
| optim   | SGD                  |
| seed    | 123,456,789          |

Baseline is no normalization with images [0,1].
Models: Shifted input [-0.5,0.5] `--shifted_input`; Normalized input N(0,1) `--scaled_input`; Normalized output `--normalized_output`.
Esatv3 has following normalization parameters: `--scale_means` [0.42, 0.46, 0.5] and `--scale_stds` [0.218, 0.239, 0.2575].

If improvement on models with normalized input is not large enough, stick to shifted or normal input.
Estimating the mean, variance and covariance matrix of a dataset is not feasible in an online setting, unless with some running average.

|         | 0.1  |  0.01  | 0.001 | 0.0001 | 
|---------|------|--------|-------|--------|
|reference| check|11392 11393| check | running|
|shifted  | check| check  | check | check|        
|scaled i | check| check  | run   | running|
|scaled o |11386 |11389 11390| check | run|

Plot curves of validation accuracy and table final test accuracies with std over different seeds.


Conclusion:
At the input side is not much difference. Shifting the data, as well as scaling has a slight improvement over the reference.
The difference is not large and mainly visible at the beginning of training.
Because scaling the data requires estimation of mean and standard deviations for each new dataset, we continue working with shifted input.
<img src="/imgs/19-03-10_data_normalization.jpg" alt="data normalization" style="width: 400px;"/>


The difference on the different learning rates was negligible:
<img src="/imgs/19-03-10_data_normalization_learningrate.jpg" alt="data normalization learning rates" style="width: 400px;"/>

Normalizing the different discrete actions within a batch at the output has a slight negative impact in this setting.
The data imbalance and force normalization makes some samples much less represented in the training data, leading to a poorer validation accuracy.

The variance over different seeds is also negligible:
<img src="/imgs/19-03-10_data_normalization_seeds.jpg" alt="data normalization seeds" style="width: 400px;"/>


```bash
python combine_results.py --subsample 10 --tags Loss_val_accuracy\
  --log_folders alex_net/esatv3_expert_200K/shifted_input/1/2\
                alex_net/esatv3_expert_200K/ref/1/2\
                alex_net/esatv3_expert_200K/scaled_input/1/2\
                alex_net/esatv3_expert_200K/normalized_output/1/2\
  --legend_names shifted_input reference scaled_input normalized_output

python combine_results.py --subsample 10 --tags Loss_val_accuracy\
                alex_net/esatv3_expert_200K/ref/1/2\
                alex_net/esatv3_expert_200K/ref/01/2\
                alex_net/esatv3_expert_200K/ref/001/2\
                alex_net/esatv3_expert_200K/ref/0001/2\
  --legend_names 0.1 0.01 0.001 0.0001

python combine_results.py --subsample 10 --tags Loss_val_accuracy\
                alex_net/esatv3_expert_200K/ref/1/0\
                alex_net/esatv3_expert_200K/ref/1/1\
                alex_net/esatv3_expert_200K/ref/1/2\
  --legend_names 0 1 2
```


```bash
for LR in 1 01 001 0001 ; do
  name="alex_net/esatv3_expert_200K/ref/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --loss CrossEntropy"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 6 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/shifted_input/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --shifted_input --loss CrossEntropy"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 6 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/scaled_input/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --scaled_input --loss CrossEntropy"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 6 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/normalized_output/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --normalized_output --loss CrossEntropy"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 6 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
```



_NA: Load Imagenet Pretrained Alexnet_

```bash
python main.py --dataset esatv3_expert_500  --tensorboard --max_episodes 10 --learning_rate 0.01 --owr --network res18_net --checkpoint_path '' --discrete --loss CrossEntropy --pretrained
```

_NA: Train Tinyv2_

Trained with same seeds to inspect variance for different sizes of the dataset.
Changed data multithreaded read in so no variance is introduced over different timings of different threads.
It is however crucial to load a scratch saved pytorch model to be able to have the exact same training behavior.

```bash
for d in 'esatv3_expert' 'esatv3_expert_10K' 'esatv3_expert_5K' 'esatv3_expert_1K' 'esatv3_expert_500' ; do
  name="tinyv2/$d"
  pytorch_args="--dataset $d --turn_speed 0.8 --speed 0.8 --discrete --load_data_in_ram --owr --loss CrossEntropy \
   --continue_training --checkpoint_path tiny_net_scratch --tensorboard --max_episodes 100 --batch_size 64\
   --learning_rate 0.01"
  dag_args="--number_of_models 2"
  condor_args="--wall_time_rec $((200*60)) --rammem 15"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
```

_NA: Collect data with expert_

```bash
# Collect data:
name="collect_esatv3"
script_args="--z_pos 1 -w esatv3 --random_seed 512  --owr -ds --number_of_runs 10 --no_training --evaluate_every -1 --final_evaluation_runs 0"
pytorch_args="--pause_simulator --online --alpha 1 --tensorboard --discrete --turn_speed 0.8 --speed 0.8"
dag_args="--number_of_recorders 1 --destination esatv3_expert --val_len 1 --test_len 1"
condor_args="--wall_time_rec $((10*60*60)) --rammem 7"
python dag_create_data.py -t $name $script_args $pytorch_args $dag_args $condor_args
```
