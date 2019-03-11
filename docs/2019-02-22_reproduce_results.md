---
title: Reproduce Results
layout: default
---

The plan is to have each result in this thesis made reproducable with minimal effort.
This blog summarizes all final experiments mentioned in the thesis.

### Neural Architectures

__Train Alexnet__: Compare performance over different seeds, learning rates and data normalization techniques:
```bash
for LR in 1 01 001 0001 ; do
  name="alex_net/esatv3_expert_200K/ref/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete --owr\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 15"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/shifted_input/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete --owr\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --shifted_input"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 15"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/scaled_input/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete --owr\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --scaled_input"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 15"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args

  name="alex_net/esatv3_expert_200K/normalized_output/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --discrete --owr\
   --continue_training --checkpoint_path alex_net_scratch --tensorboard --max_episodes 500 --batch_size 100\
   --learning_rate 0.$LR --normalized_output"
  dag_args="--number_of_models 3"
  condor_args="--wall_time_rec $((5*500*60)) --rammem 15"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
```

__Create esatv3 dataset__: Launch condor job from pytorch_pilot/scripts/launch.sh within tensorflow-1.8 environment.
```bash
# Collect data:
name="collect_esatv3"
script_args="--z_pos 1 -w esatv3 --random_seed 512  --owr -ds --number_of_runs 10 --no_training --evaluate_every -1 --final_evaluation_runs 0"
pytorch_args="--pause_simulator --online --alpha 1 --tensorboard --discrete --turn_speed 0.8 --speed 0.8"
dag_args="--number_of_recorders 1 --destination esatv3_expert --val_len 1 --test_len 1"
condor_args="--wall_time_rec $((10*60*60)) --rammem 7"
python dag_create_data.py -t $name $script_args $pytorch_args $dag_args $condor_args
```
