---
title: Delays with ROS - tensorflow - docker - singularity
layout: default
---

# Evaluating the delays of tensorflow in different settings
Delay is measured in between tensorflow (rosinterface) receiving an image and publishing a control back to ROS.

| Device | min | avg | max |
| Laptop without Depth | 0.13 | 0.16 | 0.35 | 
| Laptop with aux Depth | 0.14 | 0.17 | 0.33 |
| Laptop with aux Depth and plot depth | 0.14 | 0.18 | 0.4 |
|----------|
| Docker with Graphics without Depth | 0.14 | 0.17 | 0.33 |
| Docker with Graphics with aux Depth | 0.14 | 0.17 | 0.33 |
| Docker with Graphics with aux Depth and plot depth | 0.16 | 0.18 | 0.37 |
| Docker with xpra without Depth | 0.155 | 0.25 | 0.59 |
| Docker with xpra without Depth (without displaying control) | 0.16 | 0.22 | 0.63 |
| Docker with xpra with aux Depth | 0.15 | 0.23 | 0.55 |
| Docker with xpra with aux Depth (without displaying control) | 0.16 | 0.21 | 0.56 |
| Docker with xpra with aux Depth and plot depth | 0.19 | 0.25 | 0.64 |
| Docker with xpra with aux Depth and plot depth (without displaying control) | 0.17 | 0.22 | 0.57 |
|---------|
| Singularity with Graphics without Depth | 0.14 | 0.18 | 0.46 |
| Singularity with Graphics with aux Depth | 0.14 | 0.16 | 0.34 |
| Singularity with Graphics with aux Depth and plot depth | 0.15 | 0.17 | 0.39 |
| Singularity with xpra without Depth (without displaying control) | 0.13 | 0.19 | 0.50 |
| Singularity with xpra with aux Depth (without displaying control) | 0.13 | 0.19 | 0.51 |
| Singularity with xpra with aux Depth and plot depth (without displaying control) | 0.13 | 0.20 | 0.49 |

There are some quick wins by disabling the plotting of the depth prediction (0.01s on average) and avoiding the console display to be rendered in xpra (0.02s on average). Rendering with GPU acceleration (graphics) is much faster than rendering softwarewise with xpra.
Switching from Docker to Singularity introduces a small 0.01s delay on average when using the graphics though with xpra Singularity seems to be faster, surprisingly!





## Code for redoing these experiments:
#### Code for laptop
```
$ roscd simulation_supervised
$ ./scripts/evaluate_model.sh -s start_python.sh -m naux -t testing_on_laptop_naux -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_laptop_naux
$ ./scripts/evaluate_model.sh -s start_python.sh -m auxd -t testing_on_laptop_auxd -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_laptop_auxd
$ ./scripts/evaluate_model.sh -s start_python.sh -m auxd -t testing_on_laptop_auxd_show_depth -p "--show_depth True"
$ less /home/klaas/tensorflow/log/testing_on_laptop_auxd_show_depth
```

#### Code for docker with graphics
```
$ sudo nvidia-docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/klaas:/home/klaas -u klaas kkelchte/ros_gazebo_tensorflow
$ export DISPLAY=:0
$ export LD_LIBRARY_PATH=/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
$ roscd simulation_supervised
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m naux -t testing_on_docker_graph_naux -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_docker_graph_naux
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_docker_graph_auxd -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_docker_graph_auxd
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_docker_graph_auxd_show_depth -p "--show_depth True"
$ less /home/klaas/tensorflow/log/testing_on_docker_graph_auxd_show_depth
```

#### Code for docker with xpra
```
$ sudo nvidia-docker run -it --rm -v /home/klaas:/home/klaas -u klaas kkelchte/ros_gazebo_tensorflow
$ source /home/klaas/docker_home/.entrypoint
$ roscd simulation_supervised
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m naux -t testing_on_docker_xpra_naux -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_docker_xpra_naux
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_docker_xpra_auxd -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_docker_xpra_auxd
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_docker_xpra_auxd_show_depth -p "--show_depth True"
$ less /home/klaas/tensorflow/log/testing_on_docker_xpra_auxd_show_depth
```

#### Code for singularity with graphics
```
$ singularity shell --nv ~/ros_gazebo_tensorflow.img
$ source /opt/ros/$ROS_DISTRO/setup.bash
$ source $HOME/simsup_ws/devel/setup.bash --extend
$ source $HOME/drone_ws/devel/setup.bash --extend
$ roscd simulation_supervised
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m naux -t testing_on_sing_graph_naux -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_sing_graph_naux
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_sing_graph_auxd -p "--show_depth False"
$ less /home/klaas/tensorflow/log/testing_on_sing_graph_auxd
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_sing_graph_auxd_show_depth -p "--show_depth True"
$ less /home/klaas/tensorflow/log/testing_on_sing_graph_auxd_show_depth
```

#### Code for singularity with xpra
```
$ singularity shell --nv ~/ros_gazebo_tensorflow.img
$ source /home/klaas/docker_home/.entrypoint_sing
$ roscd simulation_supervised
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m naux -t testing_on_sing_xpra_naux -p "--show_depth False" -g false
$ less /home/klaas/tensorflow/log/testing_on_sing_xpra_naux
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_sing_xpra_auxd -p "--show_depth False" -g false
$ less /home/klaas/tensorflow/log/testing_on_sing_xpra_auxd
$ ./scripts/evaluate_model.sh -s start_python_docker.sh -m auxd -t testing_on_sing_xpra_auxd_show_depth -p "--show_depth True" -g false
$ less /home/klaas/tensorflow/log/testing_on_sing_xpra_auxd_show_depth
```
