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


## Test trained network interactively on real turtlebot

```
$ sshfsopal
$ cp opal/docker_home/tensorflow/log/.. tensorflow/log/..
$ adapt tensorflow/log/../checkpoint
$ turtle
$ roscd simulation_supervised/python
$ python run_script_real_turtle.py -p cont_slow.yaml -m ... -e --fsm console_nn_db_interactive_turtle_fsm -g
$ rosrun image_view image_view image:=/raspicam_node/image/ _image_transport:=compressed
```

