---
title: Reproduce Results
layout: default
---

# Neural Architecture Experimental Notes:

_NA: LSTM training methods_

We distinguish three types of feeding sequential batches of data throught the network.
The sequences can be fed to the network in its full length leading to fully unrolled backpropagation through time (FBPTT).
Or the sequences can be truncated at a fixed length, for instance 20, leading to truncated backpropagation through time (TBPTT).
The order the sequences are provided to the network, can be as a sliding window providing for each step a new shifted data sequence, sliding TBPTT (S-TBPTT).
Or the order can be shuffled leading to better stabilization wich is called windowwise-truncated backpropagation through time (WW-TBPTT).

| network | tiny_LSTM F-BPTT     | tiny_LSTM WW-BPTT    | tiny_LSTM S-BPTT     | alex_LSTM F-BPTT     | alex_LSTM WW-BPTT    | alex_LSTM S-BPTT     |
|---------|----------------------|----------------------|----------------------|----------------------|----------------------|----------------------|
| LR      | 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001|
| BS      | 1                    | 32                   | 32                   | 1                    | 32                   | 32                   |
| TL      | -1                   | 20                   | 20                   | -1                   | 20                   | 20                   |
| init    | scratch              | scratch              | scratch              | scratch              | scratch              | scratch              |
| optim   | SGD                  | SGD                  | SGD                  | SGD                  | SGD                  | SGD                  |
| seed    | 123                  | 123                  | 123                  | 123                  | 123                  | 123                  |
| dataset | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  |
| gpu     | 3800                 | 3800                 | 3800                 | 3800                 | 3800                 | 3800                 |

```bash
# wwbptt
for LR in 1 01 ; do
  name="tiny_LSTM_1ss/wwbptt/$LR"
  pytorch_args="--weight_decay 0 --network tiny_LSTM_net --checkpoint_path tiny_LSTM_net_scratch --dataset esatv3_expert_10K --discrete --turn_speed 0.8 --speed 0.8\
 --tensorboard --max_episodes 30000 --batch_size 4 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --time_length 20 --subsample 1 --load_data_in_ram"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((300*5*60+2*3600)) --rammem 7 --gpumem 900"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

# sbptt
for LR in 1 01 ; do
  name="tiny_LSTM_1ss/sbptt/$LR"
  pytorch_args="--weight_decay 0 --network tiny_LSTM_net --checkpoint_path tiny_LSTM_net_scratch --dataset esatv3_expert_10K --discrete --turn_speed 0.8 --speed 0.8\
 --tensorboard --max_episodes 30000 --batch_size 4 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --time_length 20 --sliding_tbptt --subsample 1 --sliding_step_size 5 --load_data_in_ram"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((300*1*60+2*3600)) --rammem 7 --gpumem 900"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

# fbptt
for LR in 1 01 ; do
  name="tiny_LSTM_1ss/fbptt/$LR"
  pytorch_args="--weight_decay 0 --network tiny_LSTM_net --checkpoint_path tiny_LSTM_net_scratch --dataset esatv3_expert_10K --discrete --turn_speed 0.8 --speed 0.8\
 --tensorboard --max_episodes 3000 --batch_size 4 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --time_length -1 --subsample 1 --load_data_in_ram"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((3000*10+3600)) --rammem 11 --gpumem 6000"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_LSTM/wwbptt --legend_names 0.01 0.1
python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_LSTM/sbptt --legend_names 0.01 0.1
python combine_results.py --tags validation_accuracy --subsample 50 --mother_dir tiny_LSTM_net/fbptt --legend_names 0.01 0.1

# python main.py --network tiny_LSTM_net --discrete --dataset esatv3_expert_200K --turn_speed 0.8 --speed 0.8 --tensorboard --max_episodes 100 --batch_size 32 --learning_rate 0.01 --loss CrossEntropy --shifted_input --optimizer SGD --continue_training --checkpoint_path tiny_LSTM_net_scratch

# combine winners
# python combine_results.py --tags train_accuracy validation_accuracy --subsample 5 --log_folders tiny_LSTM_net/wwbptt2/1/seed_0 tiny_LSTM_net/sbptt/1/seed_0 tiny_LSTM_net/fbptt/1/seed_0 --legend_names WW-BPTT S-BPTT F-BPTT
# pars fbptt at a much lower resolution 
jupyter notebook pars_clean_results_interactively.ipynb

```

<img src="/imgs/19-4-2_LSTM_train_accuracy.jpg" alt="LSTM_train_accuracy" style="width: 400px;"/>
<img src="/imgs/19-4-2_LSTM_validation_accuracy.jpg" alt="LSTM_validation_accuracy" style="width: 400px;"/>

Training LSTM's can be tedious as the time unrolment quickly takes over the GPU memory space. 
In order to deal with this, we subsampled the data by a factor of 10.

Alternatively, models were trained on the smaller 10K dataset but due to less data the validation accuracy became too noisy, making it harder to interpret the results.



EXTENSION:
The sliding-window is very unstable due to multiple gradient steps are based on consecutive frames that are highly correlated.
Rather than taking a gradient step at each time window, it would be better to accumulate the gradients first over the full sequence before changing the parameters.
The latter would create gradient steps based on the full sequence just like in FBPTT which are more stable.






_NA: Increase input space_


2 Options: with or without shared feature extraction network. 

- nfc: Concatenate the features extracted from a siamese network over multiple frames.
- 3d: Place multiple consecutive frames at the input and allow different feature extracting networks in a 3D CNN.

```bash
for LR in 1 01 001 ; do
  name="tiny_nfc_net_1/$LR"
  pytorch_args="--weight_decay 0 --network tiny_nfc_net --n_frames 1 --continue_training --checkpoint_path tiny_nfc_net_1_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --loss CrossEntropy\
 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --shifted_input --optimizer SGD"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
for LR in 1 01 001 ; do
  name="tiny_nfc_net_3/$LR"
  pytorch_args="--weight_decay 0 --network tiny_nfc_net --n_frames 3 --continue_training --checkpoint_path tiny_nfc_net_3_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --loss CrossEntropy\
 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --shifted_input --optimizer SGD"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
# for LR in 1 01 001 ; do
#   name="tiny_nfc_net_5/$LR"
#   pytorch_args="--weight_decay 0 --network tiny_nfc_net --n_frames 5 --continue_training --checkpoint_path tiny_nfc_net_5_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --loss CrossEntropy\
#  --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --shifted_input --optimizer SGD"
#   dag_args="--number_of_models 1"
#   condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
#   python dag_train.py -t $name $pytorch_args $dag_args $condor_args
# done

python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_nfc_net_1 --legend_names 0.001 0.01 0.1
python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_nfc_net_3 --legend_names 0.001 0.01 0.1
# python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_nfc_net --legend_names 0.001 0.01 0.1

for LR in 1 01 001 ; do
  name="tiny_3d_net_1/$LR"
  pytorch_args="--weight_decay 0 --network tiny_3d_net --n_frames 1 --continue_training --checkpoint_path tiny_3d_net_1_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --loss CrossEntropy\
 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --shifted_input --optimizer SGD"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
for LR in 1 01 001 ; do
  name="tiny_3d_net_3/$LR"
  pytorch_args="--weight_decay 0 --network tiny_3d_net --n_frames 3 --continue_training --checkpoint_path tiny_3d_net_3_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --loss CrossEntropy\
 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_3d_net_1 --legend_names 0.001 0.01 0.1
python combine_results.py --tags validation_accuracy --subsample 5 --mother_dir tiny_3d_net_3 --legend_names 0.001 0.01 0.1

# combine winners: 0.01
python combine_results.py --tags validation_accuracy train_accuracy --subsample 5 --log_folders tiny_nfc_net_1/1 tiny_nfc_net_3/1 tiny_3d_net_3/1 --legend_names reference 3_frames_siamese 3_frames_3D-CNN --blog_destination 19-04-02_inputspace 

```

<img src="/imgs/19-04-02_inputspace_train_acurracy.jpg" alt="inputspace_train_acurracy" style="width: 400px;"/>
<img src="/imgs/19-04-02_inputspace_validation_acurracy.jpg" alt="inputspace_validation_acurracy" style="width: 400px;"/>

Conclusion:
A clear win for the usage of multiple input samples between one and 3 frames in shared feature extraction part.
The improvement from three to five is not so clear. 



_NA: Continuous action space_


```bash
for LR in 1 01 001 0001 00001; do
  name="continous_discrete_stochastic/tiny_net/continuous/$LR"
  pytorch_args="--weight_decay 0 --network tiny_net --checkpoint_path tiny_net_cont_scratch --continue_training --dataset esatv3_expert_stochastic_200K --turn_speed 0.8 --speed 0.8\
 --tensorboard --max_episodes 20000 --batch_size 32 --learning_rate 0.$LR --loss MSE --shifted_input --optimizer SGD --clip 1.0"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*1*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="continous_discrete_stochastic/tiny_net/discrete/$LR"
  pytorch_args="--weight_decay 0 --network tiny_net --checkpoint_path tiny_net_scratch --continue_training --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
 --tensorboard --max_episodes 20000 --batch_size 32 --learning_rate 0.$LR --loss MSE --shifted_input --optimizer SGD --clip 1.0"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*1*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

python combine_results.py --subsample 5 --tags validation_imitation_learning train_imitation_learning --mother_dir continous_discrete_stochastic/tiny_net/continuous --legend_names 0.00001 0.0001 0.001 0.01 0.1
python combine_results.py --subsample 5 --tags validation_imitation_learning train_imitation_learning --mother_dir continous_discrete_stochastic/tiny_net/discrete --legend_names 0.00001 0.0001 0.001 0.01 0.1

```
Results MSE on validation set for continuous action space over different learning rates:

<img src="/imgs/19-04-02_continuous_learningrate_validation_imitation_learning.jpg" alt="continuous_learningrate_validation_imitation_learning" style="width: 400px;"/>

Results MSE on validation set for discrete action space over different learning rates:

<img src="/imgs/19-04-02_datadependency_tiny.jpg" alt="train and validation accuracy over different dataset sizes." style="width: 400px;"/>

Results MSE on validation set for discrete and continuous action space:

<img src="/imgs/19-04-02_continuous_discrete_validation_imitation_learning.jpg" alt="19-04-02_continuous_discrete_validation_imitation_learning" style="width: 400px;"/>


Conclusion:
The dataset is discrete with controls varying only over 3 options. 
This prior knowledge of the task can be exploited in the network by using a classifier network instead of a regressor.
This leads to faster training and better end performance.
In some cases the control needs to be continuous for which different quantizations can be used according to the required control resolution.
However, in cases where the control is very continuous, the quantization of the control leads to a minimum quantization error which might not be tolerable in cases of delicate control.

EXTENSION:
Create a dataset with the continuous expert and see how a big dataset and a regressor might lead to a lower training (and validation?) loss due to no lower bound quantization error.


_NA: Gather specifications_

| network      | feature layers | decision layers | parameters | GPU size[MB] |   FPS (cpu) |
|--------------|----------------|-----------------|------------|--------------|-------------|
| alex         |        5       |        3        |   57*10^6  |       1013   |  1188 (38)  | 
| vgg16        |       13       |        3        |  134*10^6  |       1091   |   603 (8)   |
| inception    |        7       |        1        |   24*10^6  |       1341   |    35 (3)   |
| res18        |        4       |        1        |   11*10^6  |       1277   |   297 (21)  |
| dense        |       24       |        1        |    6*10^6  |        913   |    52 (5)   |
| squeeze      |        9       |        1        |    736963  |       1303   |   293 (22)  |
| tiny         |        2       |        2        |    8*10^6  |       1335   |  2369 (59)  |

The GPU speed depends mainly on how well the torch implementation utilizes the cuda and cudnn accelerations.
All speed measurements were taken on a Titan X which is also not necessarily representative for an energy efficient onboard GPU. Therefore these results should only be used as an indicator for relative comparison.

To reproduce these results please use the `parse_network_details.ipynb` script.

_NA: Compare realistic architectures_

| network | alex                 | tiny                 |
|---------|----------------------|----------------------|
| LR      | 0.1,0.01,0.001,0.0001| 0.1,0.01,0.001,0.0001|
| BS      | 32                   | 32                   |
| init    | scratch              | scratch              |
| optim   | SGD                  | SGD                  |
| seed    | 123                  | 123                  |
| dataset | 100K, 50K, 20K, 10K  | 100K, 50K, 20K, 10K  |

Justify step to scratch as hand crafted models do not have a imagenet pretrained checkpoint available.
The three models above are competing in performance on gradual smaller datasets.
Ideally a smaller model is less prune to overfitting and allows faster learning.
Handcraft different versions of tiny net according to pruning with importance weights.

```bash
for DS in 100K 50K 20K 10K 5K 1K ; do 
  for LR in 1 01 001 ; do
    name="tiny_net/esatv3_expert_$DS/$LR"
    pytorch_args="--weight_decay 0 --network tiny_net --checkpoint_path tiny_net_scratch --dataset esatv3_expert_$DS --discrete --turn_speed 0.8 --speed 0.8\
  --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*1*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
for DS in 100K 50K 20K 10K 5K 1K; do 
  for LR in 1 01 001 ; do
    name="alex_net/esatv3_expert_$DS/$LR"
    pytorch_args="--weight_decay 0 --network alex_net --checkpoint_path alex_net_scratch --dataset esatv3_expert_$DS --discrete --turn_speed 0.8 --speed 0.8\
  --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*1*60+2*3600)) --rammem 6 --gpumem 1900 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done

for DS in 100K 50K 20K 10K 5K 1K ; do combine_results.py --tags validation_accuracy train_accuracy --mother_dir tiny_net/esatv3_expert_$DS --legend_names 0.001 0.01 0.1 ; done
for DS in 100K 50K 20K 10K 5K 1K ; do combine_results.py --tags validation_accuracy train_accuracy --mother_dir alex_net/esatv3_expert_$DS --legend_names 0.001 0.01 0.1 ; done

# specific image:
jupyter notebook pars_clean_results_interactively.ipynb
```
Tiny Net:

<img src="/imgs/19-04-02_datadependency_tiny.jpg" alt="train and validation accuracy over different dataset sizes." style="width: 400px;"/>

Alex Net:

<img src="/imgs/19-04-02_datadependency_alex.jpg" alt="train and validation accuracy over different dataset sizes." style="width: 400px;"/>


Note: it would be nice to add an overregularization example with weight decay. However, 10K failed as there was no clear overfitting. Moreover


_NA: Compare deep architectures_
               
| network | vgg16                | alex                 | inception            | res18                | dense                | squeeze               |
|---------|----------------------|----------------------|----------------------|----------------------|----------------------|-----------------------|
| LR      | 0.1,0.001,0.00001    | 0.1,0.001,0.00001    | 0.1,0.001,0.00001    | 0.1,0.001,0.00001    | 0.1,0.001,0.00001    | 0.1,0.01,0.001,0.00001|
| BS      | 32                   | 32                   | 32                   | 32                   | 32                   | 32                    |
| init    | imagenet             | imagenet             | imagenet             | imagenet             | imagenet             | imagenet              |
| optim   | SGD                  | SGD                  | SGD                  | SGD                  | SGD                  | SGD                   |
| seed    | 123                  | 123                  | 123                  | 123                  | 123                  | 123                   |
| acc(fine)|87.5 (78.6)          | 85.9 (77.0)          | 88.4 (77.5)          | 88.3 (77.7)          | 86.3 (73.4)          | 84.9 (77.2)           |


Models are compared in the same setting. 
If a model fails to learn due to severe overfitting, overfitting is handled by regularization techniques (DO, WD, BN).
Regularized model is add to the validation learning graph.

As end-to-end training leads to a better accuracy than only retraining the last decision layers, it is clear that the imagenet features are still suboptimal.


```bash
for net in inception_net vgg16_net dense_net ; do
  for LR in 1 01 001 0001 00001 ; do
    name="${net}_pretrained/esatv3_expert_200K/$LR"
    pytorch_args="--weight_decay 0 --network ${net} --pretrained --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --clip 1.0\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done

for net in res18_net alex_net squeeze_net; do
  for LR in 1 01 001 0001 00001 ; do
    name="${net}_pretrained/esatv3_expert_200K/$LR"
    pytorch_args="--weight_decay 0 --network ${net} --pretrained --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --clip 1.0\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 1900 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done

# After training
for net in alex vgg16 inception res18 dense squeeze ; do python combine_results.py --subsample 5 --tags validation_accuracy --log_folders ${net}_net_pretrained/esatv3_expert_200K --legend_names 0.00001 0.0001 0.001 0.01 0.1; done

# select the winners and combine:
python combine_results.py --subsample 5 --tags train_accuracy validation_accuracy --log_folders alex_net_pretrained/esatv3_expert_200K/01 dense_net_pretrained/esatv3_expert_200K/001 inception_net_pretrained/esatv3_expert_200K/1 res18_net_pretrained/esatv3_expert_200K/01 squeeze_net_pretrained/esatv3_expert_200K/1 vgg16_net_pretrained/esatv3_expert_200K/1 --legend_names Alexnet Densenet Inception Resnet Squeezenet Vgg --blog_destination 19-04-02_deeparchitectures_pretrained
```
<img src="/imgs/19-04-02_deeparchitectures_pretrained_train_accuracy.jpg" alt="training accuracy of pretrained archtictures." style="width: 400px;"/>
<img src="/imgs/19-04-02_deeparchitectures_pretrained_validation_accuracy.jpg" alt="validation accuracy of pretrained archtictures." style="width: 400px;"/>



Finetune models by freezing feature extraction part:
```bash
for net in inception_net vgg16_net dense_net ; do
  for LR in 1 01 001 0001 00001 ; do
    name="${net}_finetune/$LR"
    pytorch_args="--weight_decay 0 --network ${net} --feature_extract --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --clip 1.0\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done

for net in res18_net alex_net squeeze_net; do
  for LR in 1 01 001 0001 00001 ; do
    name="${net}_finetune/$LR"
    pytorch_args="--weight_decay 0 --network ${net} --feature_extract --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --clip 1.0\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 1900 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done

# After training
for net in alex vgg16 inception res18 dense squeeze; do python combine_results.py --subsample 5 --tags validation_accuracy --log_folders ${net}_net_finetune --legend_names 0.001 0.01 0.1; done

# select the winners and combine:
python combine_results.py --subsample 5 --tags train_accuracy validation_accuracy --log_folders alex_net_finetune/01 dense_net_finetune/001 inception_net_finetune/1 res18_net_finetune/1 squeeze_net_finetune/1 vgg16_net_finetune/1 --legend_names Alexnet Densenet Inception Resnet Squeezenet Vgg --blog_destination 19-04-02_deeparchitectures_finetune
```

<img src="/imgs/19-04-02_deeparchitectures_finetune_train_accuracy.jpg" alt="training accuracy of finetune archtictures." style="width: 400px;"/>
<img src="/imgs/19-04-02_deeparchitectures_finetune_validation_accuracy.jpg" alt="validation accuracy of finetune archtictures." style="width: 400px;"/>


_NA: VGG preparation_

| network | vgg16                |
|---------|----------------------|
| LR      | 0.1,0.001,0.00001    |
| BS      | 32                   |
| init    | scratch, imagenet    |
| optim   | SGD, Adam, Adadelta  |
| seed    | 123                  |

_imagenet pretrained speeds up learning and decreases overfitting_
For VGG16 SGD from scratch / imagenetpretrained is compared over different learning rates.

SGD:
<img src="/imgs/19-04-02_vgg_optimizers_pretrained_SGD_validation_accuracy.jpg" alt="SGD pretrained" style="width: 400px;"/>
ADAM:
<img src="/imgs/19-04-02_vgg_optimizers_pretrained_Adam_validation_accuracy.jpg" alt="Adam pretrained" style="width: 400px;"/>
ADADELTA:
<img src="/imgs/19-04-02_vgg_optimizers_pretrained_Adadelta_validation_accuracy.jpg" alt="Adadelta pretrained" style="width: 400px;"/>

_optimizers can increase learning rate without overfitting_
For VGG16 with SGD, ADAM and ADADELTA are compared for 'best' learning rate in scratch setting.
SGD scratch:
<img src="/imgs/19-04-02_vgg_optimizers_scratch_SGD_validation_accuracy.jpg" alt="SGD scratch" style="width: 400px;"/>
ADAM scratch:
<img src="/imgs/19-04-02_vgg_optimizers_scratch_Adam_validation_accuracy.jpg" alt="Adam scratch" style="width: 400px;"/>
ADADELTA scratch:
<img src="/imgs/19-04-02_vgg_optimizers_scratch_Adadelta_validation_accuracy.jpg" alt="Adadelta scratch" style="width: 400px;"/>

<img src="/imgs/19-04-02_vgg_optimizers_scratch_combined_train_accuracy.jpg" alt="Adadelta scratch" style="width: 400px;"/>

<img src="/imgs/19-04-02_vgg_optimizers_scratch_combined_validation_accuracy.jpg" alt="Adadelta scratch" style="width: 400px;"/>


Plot curves of validation accuracy and table final test accuracies with std over different seeds.


```bash
# pretrained
for LR in 1 001 00001 ; do
 for OP in SGD Adam Adadelta ; do 
  name="vgg16_net_pretrained/esatv3_expert_200K/$OP/$LR"
  pytorch_args="--weight_decay 0 --network vgg16_net --pretrained --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --clip 1.\
  --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer $OP"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 7 --gpumem 6000 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
 done
done
# scratch
for LR in 1 001 00001 ; do
  for OP in SGD Adadelta Adam ; do 
    name="vgg16_net/esatv3_expert_200K/$OP/$LR"
    pytorch_args="--weight_decay 0 --network vgg16_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --clip 1.\
     --continue_training --checkpoint_path vgg16_net_scratch --tensorboard --max_episodes 100 --batch_size 32\
     --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer $OP"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
# parse results
for OP in SGD Adadelta Adam ; do \
  python combine_results.py --subsample 5 --tags validation_accuracy --mother_dir vgg16_net_pretrained/esatv3_expert_200K/$OP --legend_names 0.00001 0.001 0.1 --blog_destination 19-04-02_vgg_optimizers_pretrained_${OP};\
  python combine_results.py --subsample 5 --tags validation_accuracy --mother_dir vgg16_net/esatv3_expert_200K/$OP --legend_names 0.00001 0.001 0.1 --blog_destination 19-04-02_vgg_optimizers_scratch_${OP};\
done
# combine best results
python combine_results.py --subsample 5 --tags train_accuracy validation_accuracy --log_folders vgg16_net_pretrained/esatv3_expert_200K/SGD/1 vgg16_net_pretrained/esatv3_expert_200K/Adam/00001 vgg16_net_pretrained/esatv3_expert_200K/Adadelta/1 --legend_names SGD Adam Adadelta --blog_destination 19-04-02_vgg_optimizers_pretrained_combined
python combine_results.py --subsample 5 --tags train_accuracy validation_accuracy --log_folders vgg16_net/esatv3_expert_200K/SGD/1 vgg16_net/esatv3_expert_200K/Adam/00001 vgg16_net/esatv3_expert_200K/Adadelta/1 --legend_names SGD Adam Adadelta --blog_destination 19-04-02_vgg_optimizers_scratch_combined

```


_NA: Influence of data normalization on Alexnet:_

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


Plot curves of validation accuracy and table final test accuracies with std over different seeds.


Conclusion:
At the input side is not much difference. Shifting the data, as well as scaling has a slight improvement over the reference.
The difference is not large and mainly visible at the beginning of training.
Because scaling the data requires estimation of mean and standard deviations for each new dataset, we continue working with shifted input.
<img src="/imgs/19-04-02_data_normalization_methods_validation_accuracy.jpg" alt="data normalization" style="width: 400px;"/>


The difference on the different learning rates is very clear:
<img src="/imgs/19-04-02_data_normalization_learningrate_validation_accuracy.jpg" alt="data normalization learning rates" style="width: 400px;"/>

Normalizing the different discrete actions within a batch at the output has a slight negative impact in this setting.
The data imbalance and force normalization makes some samples much less represented in the training data, leading to a poorer validation accuracy.

The variance over different seeds is also negligible:
<img src="/imgs/19-04-02_data_normalization_seed_validation_accuracy.jpg" alt="data normalization seeds" style="width: 400px;"/>


```bash
python combine_results.py --subsample 5 --tags validation_accuracy\
  --log_folders alex_net/esatv3_expert_200K/ref/1/seed_0\
                alex_net/esatv3_expert_200K/shifted_input/1/seed_0\
                alex_net/esatv3_expert_200K/scaled_input/1/seed_0\
                alex_net/esatv3_expert_200K/normalized_output/1/seed_0\
  --legend_names reference shifted_input scaled_input normalized_output\
  --blog_destination 19-04-02_data_normalization_methods

python combine_results.py --subsample 5 --tags validation_accuracy\
    --log_folders alex_net/esatv3_expert_200K/ref/1/seed_2\
                alex_net/esatv3_expert_200K/ref/01/seed_2\
                alex_net/esatv3_expert_200K/ref/001/seed_2\
                alex_net/esatv3_expert_200K/ref/0001/seed_2\
  --legend_names 0.1 0.01 0.001 0.0001\
  --blog_destination 19-04-02_data_normalization_learningrate

python combine_results.py --subsample 5 --tags validation_accuracy\
  --mother_dir alex_net/esatv3_expert_200K/ref/1\
  --blog_destination 19-04-02_data_normalization_seed
```


```bash
for LR in 1 01 001 0001 ; do
   name="alex_net/esatv3_expert_200K/ref/$LR"
   pytorch_args="--weight_decay 0 --network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8\
    --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 20000 --batch_size 100\
    --loss CrossEntropy --learning_rate 0.$LR"
   dag_args="--number_of_models 3"
   condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
   python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/shifted_input/$LR"
  pytorch_args="--weight_decay 0 --network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 20000 --batch_size 100 --loss CrossEntropy\
   --learning_rate 0.$LR --shifted_input"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/scaled_input/$LR"
  pytorch_args="--weight_decay 0 --network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 20000 --batch_size 100 --loss CrossEntropy\
   --learning_rate 0.$LR --scaled_input"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/normalized_output/$LR"
  pytorch_args="--weight_decay 0 --network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 20000 --batch_size 100 --loss CrossEntropy\
   --learning_rate 0.$LR --normalized_output"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
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
  pytorch_args="--weight_decay 0 --dataset $d --turn_speed 0.8 --speed 0.8 --discrete --load_data_in_ram --owr --loss CrossEntropy \
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
# for discrete dataset
pytorch_args="--weight_decay 0 --pause_simulator --online --alpha 1 --tensorboard --discrete --turn_speed 0.8 --speed 0.8"
# for continuous dataset
pytorch_args="--weight_decay 0 --pause_simulator --online --alpha 1 --tensorboard --stochastic --turn_speed 0.8 --speed 0.8"
dag_args="--number_of_recorders 12 --destination esatv3_expert --val_len 1 --test_len 1 --min_rgb 2000 --max_rgb 3000"
condor_args="--wall_time_rec $((10*10*60+3600)) --rammem 6"
python dag_create_data.py -t $name $script_args $pytorch_args $dag_args $condor_args
```
