---
title: Reproduce Results
layout: default
---

The plan is to have each result in this thesis made reproducable with minimal effort.
This blog summarizes all final experiments mentioned in the thesis.

### Neural Architectures

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
