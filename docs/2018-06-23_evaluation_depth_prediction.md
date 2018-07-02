---
title: Evaluation Depth Prediction
layout: default
---

# Evaluation Depth Prediction

## Continue online training of pretrained depth_q_net on real_maze dataset:

Trained networks:

```
$ turtle
$ roscd simulation_supervised/python
$ python run_script_real_turtle.py -ds -p cont_slow.yaml -m depth_q_net_real/scratch_0_lr09_e2e -t depth_q_net_real/scratch_cont_train
# visualize depth prediction
```
