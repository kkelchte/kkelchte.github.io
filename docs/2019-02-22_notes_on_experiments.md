---
title: Reproduce Results
layout: default
---



# Neural Architecture Experimental Notes:

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
  pytorch_args="--dataset $d --turn_speed 0.8 --speed 0.8 --discrete --load_in_ram --owr --loss CrossEntropy \
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
