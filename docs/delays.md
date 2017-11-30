---
title: Delays
layout: default
---

# Evaluating the delays of tensorflow in different settings
Delay is measured in between tensorflow (rosinterface) receiving an image and publishing a control back to ROS. Dimension of all numbers is seconds and measured on an Alienware laptop with GeForce GTX 780M GPU.

**Evaluate**

This was run without gpu acceleration due to wrond cuda (8.0) and cudnn (5.0) version incompatibility with tensorflow (1.4).

| Device | min | avg | max |
|-----|-|-|---|
| Laptop without Depth | 0.13 | 0.16 | 0.35 | 
| Laptop with aux Depth | 0.14 | 0.17 | 0.33 |
| Laptop with aux Depth and plot depth | 0.14 | 0.18 | 0.4 |
| Docker with Graphics without Depth | 0.14 | 0.17 | 0.33 |
| Docker with Graphics with aux Depth | 0.14 | 0.17 | 0.33 |
| Docker with Graphics with aux Depth and plot depth | 0.16 | 0.18 | 0.37 |
| Docker with xpra without Depth | 0.155 | 0.25 | 0.59 |
| Docker with xpra without Depth (without displaying control) | 0.16 | 0.22 | 0.63 |
| Docker with xpra with aux Depth | 0.15 | 0.23 | 0.55 |
| Docker with xpra with aux Depth (without displaying control) | 0.16 | 0.21 | 0.56 |
| Docker with xpra with aux Depth and plot depth | 0.19 | 0.25 | 0.64 |
| Docker with xpra with aux Depth and plot depth (without displaying control) | 0.17 | 0.22 | 0.57 |
| Singularity with Graphics without Depth | 0.14 | 0.18 | 0.46 |
| Singularity with Graphics with aux Depth | 0.14 | 0.16 | 0.34 |
| Singularity with Graphics with aux Depth and plot depth | 0.15 | 0.17 | 0.39 |
| Singularity with xpra without Depth (without displaying control) | 0.13 | 0.19 | 0.50 |
| Singularity with xpra with aux Depth (without displaying control) | 0.13 | 0.19 | 0.51 |
| Singularity with xpra with aux Depth and plot depth (without displaying control) | 0.13 | 0.20 | 0.49 |


There are some quick wins by disabling the plotting of the depth prediction (0.01s on average) and avoiding the console display to be rendered in xpra (0.02s on average). Rendering with GPU acceleration (graphics) is much faster than rendering softwarewise with xpra.
Switching from Docker to Singularity introduces a small 0.01s delay on average when using the graphics though with xpra Singularity seems to be faster, surprisingly!

**Train**

Filling replay buffer on the fly and further experimenting with improving on the minimum speed. A minimum framerate of 10 frames per second should be possible. At this moment the kinect works at 20 fps.

| Device | min | avg | max | remark |
|---|
| Laptop naux | 0.02 | 0.11 | 1.0 | reference |
| Laptop naux | 0.02 | 0.11 | 0.68 | reference |
| Laptop naux | 0.02 | 0.11 | 0.63 | reference |
| Laptop naux | 0.02 | 0.11 | 0.62 | no gpu growth |
| Laptop naux | 0.02 | 0.11 | 0.66 | no gpu growth |
| Laptop naux | 0.02 | 0.11 | 0.61 | no gpu growth |

Using a GPU decreases the average delay from 0.16 to 0.11 on the laptop (without any container). The maximum delay is increased a lot which is due to the loading of the network on the gpu.
There seems to be some discrepantie between the parallel image-callbacks that can't follow to stream of images. It is also still surprising that the delay does not allow 10fps while before summer this used to allow even 30fps (if my measures were correct as well as my memory).

**Offline**

Changing the dataformat from NHWC with the image channels as 4th dimension to NCHW with the image channel as 2th dimension increases the offline training speed significantly. Working with 1 image at the time gives a small average improvement of 10% while on bigger batches (32) the improvement is up to 50% on average.

> In order to make NCHW work with mobilenet I had to change a line in the contrib library tensorflow (1.4): tensorflow/contrib/layers/python/layers/layer.py.
Change on line 2536:

`strides = [1, stride_h, stride_w, 1]`

in:

`strides = [1, 1, stride_h, stride_w] if data_format.startswith('NC') else [1, stride_h, stride_w, 1]`

| Offline batch size of 1 |
|---|
| Laptop scratch | 0.016 | 0.019 | 0.56 | dataformat NHWC |
| Laptop scratch | 0.014 | 0.017 | 0.551 | dataformat NCHW |

| Offline batch size of 32 |
|---|
| Laptop scratch | 10 | 10 | 11 | dataformat NHWC |
| Laptop scratch | 5 | 5 | 6 | dataformat NCHW |


**Online**

AHA!
The main misconceptation I had so far was that I was concatenating 3 frames. The frames are send at 20FPS so every 0.05s. Using 3 frames as inputs makes the delay between the first input image and the final control at least 2x this 0.05s delay resulting in 0.1s delay giving the impression that it can only work at 10FPS. But that is thus not at all the case. The max delay of around 0.5s is only for the first image when the network still needs to load on the GPU.

Working with only 1frame gives me the following 'true' results:
| Device | min | avg | max | remark |
|---|
| Laptop | 0.004 | 0.004 | 0.487 | NHWC 1f |
| Laptop | 0.004 | 0.005 | 0.459 | NCHW 1f |
| Laptop | 0.007 | 0.008 | 0.545 | NCHW 3fs |
| Laptop | 0.006 | 0.010 | 0.586 | NCHW 3fs auxd |
| Laptop | 0.007 | 0.011 | 0.555 |  | NCHW 3fs auxd show depth|
| Laptop | 0.010 | 0.014 | 0.603 | NCHW 3fs auxd mob-0.5 |
| Laptop | 0.018 | 0.021 | 0.969 | NCHW 3fs auxd mob-1.0 |

The first frame introduces a big delay: 0.5s up to 1.0s. This makes the average delay depend more on the duration of the flight. Therefore the average is taken from all frames but the first.
Note:

- In the online setting, NCHW increases the average time slightly due to an extra preprocessing step of swapping dimensions in an numpy array.
- Increasing to 3 frames increases the average delay with 3ms.
- Auxiliary depth prediction increases the average delay with 2ms. 
- Displaying depth prediction only increases the average delay with 1ms.
- Increasing the depth of the network from 0.25 to 0.5 increases the average delay with 3ms (14ms)
- Increasing the depth of the network from 0.5 to 1.0 increases the average delay with 7ms (21ms)

| Device | min | avg | max | remark |
|---|
| Laptop | 0.007 | 0.011 | 0.555 |  | NCHW 3fs auxd show depth|
| Docker Graphics |  0.008 | 0.012 | 0.592 | NCHW 3fs auxd plot depth |
| Docker Xpra | 0.008 | 0.011 | 0.746 | NCHW 3fs auxd plot depth |
| Docker (condor) Graphics | NCHW 3fs auxd plot depth |
| Docker (condor) Xpra | NCHW 3fs auxd plot depth |
| Singularity Graphics | NCHW 3fs auxd plot depth |
| Singularity Xpra | NCHW 3fs auxd plot depth |
| Singularity (condor) Graphics | NCHW 3fs auxd plot depth |
| Singularity (condor) Xpra | NCHW 3fs auxd plot depth |

The experiments in docker and singularity are repeated 3 times from which the last time is used. This avoids some start up delays.

- Docker with graphics increases the average delay with only 1ms
- Docker with xpra decrease the average delay with a 1ms bringing it close to the standard delay except for the first frame.


## Code for redoing the last experiments:
#### Code for laptop
```bash
roscd simulation_supervised
./scripts/train_model.sh -s start_python.sh -n 1 -p "--show_depth False --scratch True --auxiliary_depth False --n_fc False --n_frames 1 --data_format NHWC" -t online_naux_1f_NHWC
./scripts/train_model.sh -s start_python.sh -n 1 -p "--show_depth False --scratch True --auxiliary_depth False --n_fc False --n_frames 1" -t online_naux_1f_NCHW
./scripts/train_model.sh -s start_python.sh -n 1 -p "--show_depth False --scratch True --auxiliary_depth False" -t online_naux_3f_NCHW
./scripts/train_model.sh -s start_python.sh -n 1 -p "--show_depth False --scratch True" -t online_auxd_3f_NCHW
./scripts/train_model.sh -s start_python.sh -n 1 -p "--scratch True" -t online_auxd_3f_NCHW_showd
./scripts/train_model.sh -s start_python.sh -n 1 -p "--scratch True --depth_multiplier 0.5" -t online_auxd_3f_NCHW_showd_05dm
./scripts/train_model.sh -s start_python.sh -n 1 -p "--scratch True --depth_multiplier 1.0" -t online_auxd_3f_NCHW_showd_1dm
```

#### Code for docker with graphics
```bash
$ sudo nvidia-docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/klaas:/home/klaas -u klaas kkelchte/ros_gazebo_tensorflow
$ export DISPLAY=:0
$ export LD_LIBRARY_PATH=/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
$ roscd simulation_supervised
$ for i in 0 1 2 ; do ./scripts/train_model.sh -s start_python_docker.sh -n 1 -p "--scratch True" -t online_auxd_3f_NCHW_showd_dockgraph ; done
```

#### Code for docker with xpra
```bash
$ sudo nvidia-docker run -it --rm -v /home/klaas:/home/klaas -u klaas kkelchte/ros_gazebo_tensorflow
$ source /home/klaas/docker_home/.entrypoint
$ roscd simulation_supervised
$ for i in 0 1 2 ; do ./scripts/train_model.sh -s start_python_docker.sh -n 1 -p "--scratch True" -t online_auxd_3f_NCHW_showd_dockxpra ; done
```

#### Code for singularity with graphics
```bash
$ singularity shell --nv ~/ros_gazebo_tensorflow.img
$ source /opt/ros/$ROS_DISTRO/setup.bash
$ source $HOME/simsup_ws/devel/setup.bash --extend
$ source $HOME/drone_ws/devel/setup.bash --extend
$ roscd simulation_supervised
$ for i in 0 1 2 ; do ./scripts/train_model.sh -s start_python_docker.sh -n 1 -p "--scratch True" -t online_auxd_3f_NCHW_showd_singgraph; done
```

#### Code for singularity with xpra
```
$ singularity shell --nv ~/ros_gazebo_tensorflow.img
$ source /home/klaas/docker_home/.entrypoint_sing
$ roscd simulation_supervised
$ ./scripts/train_model.sh -s start_python_docker.sh -m naux -t training_on_sing_xpra_naux -p "--show_depth False" -g false
$ less /home/klaas/tensorflow/log/training_on_sing_xpra_naux
$ ./scripts/train_model.sh -s start_python_docker.sh -m auxd -t training_on_sing_xpra_auxd -p "--show_depth False" -g false
$ less /home/klaas/tensorflow/log/training_on_sing_xpra_auxd
$ ./scripts/train_model.sh -s start_python_docker.sh -m auxd -t training_on_sing_xpra_auxd_show_depth -p "--show_depth True" -g false
$ less /home/klaas/tensorflow/log/training_on_sing_xpra_auxd_show_depth
```
