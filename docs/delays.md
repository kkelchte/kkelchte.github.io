# Evaluating the delays of tensorflow in different settings
Delay is measured in between tensorflow (rosinterface) receiving an image and publishing a control back to ROS.

| Device | min | avg | max | max fps |
| Laptop without Depth | 0.13 | 0.16 | 0.35 | 2.86 |
| Laptop with aux Depth | 0.14 | 0.17 | 0.33 | 3 |
| Laptop with aux Depth and plot depth | 0.14 | 0.18 | 0.4 | 2.5 |
| Docker with Graphics without Depth | 0.14 | 0.17 | 0.33 | 3 |
| Docker with Graphics with aux Depth | 0.14 | 0.17 | 0.33 | 3 |
| Docker with Graphics with aux Depth and plot depth | 0.16 | 0.18 | 0.37 | 2.5 |
| Docker with xpra without Depth | 0.14 | 0.17 | 0.33 | 3 |
| Docker with xpra with aux Depth | 0.14 | 0.17 | 0.33 | 3 |
| Docker with xpra with aux Depth and plot depth | 0.16 | 0.18 | 0.37 | 2.5 |




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

