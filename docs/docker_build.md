---
title: Delays
layout: default
---
### Intro

This is a guide to build docker images from a dockerfile. 

| Specifications | Version |
| -------------  | ------- |
| Ubuntu         |  16.04  |
| ROS            | Kinetic |
| Gazebo         |   7.07  |
| CUDA           |  8      |
| CudNN          |  6      |
| nvidia-docker  |  1      |
| tensorflow     |  1.4    |

### Preparation

Create a working dir.

```
$ mkdir -p ~/docker/ros_gz_tf
$ cd ~/docker/ros_gz_tf
```

Prepare the installation of cuda and cudnn by downloading the required files in you docker directory. This is not required for cuda version 8 and cudnn version 6 as they are inside the homes.esat.kuleuven.be/~kkelchte/lib folder.

For different versions it is recommended to perform the following steps inside the users/visics/kkelchte/public_home/lib folder so wget can pull the libraries inside your image.


```
$ wget https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run
$ chmod +x cuda_8.0.61_375.26_linux-run
$ ./cuda_8.0.61_375.26_linux-run --extract=$PWD
$ rm cuda-samples-linux-8.0.61-21551265.run
$ rm NVIDIA-Linux-x86_64-375.26.run
$ rm cuda_8.0.61_375.26_linux-run
```

Download in your browser cudnn 6 from [here](https://developer.nvidia.com/compute/machine-learning/cudnn/secure/v6/prod/8.0_20170307/cudnn-8.0-linux-x64-v6.0-tgz).

```
$ mv ~/Downloads/cudnn-8.0-linux-x64-v6.0.tgz .
```

Add pip requirements list from tensorflow:

```
$ cp ~/tensorflow/requirements.txt .
# OR
$ cat > requirements.txt
pyyaml
rospy
rospkg
scipy
pillow
scikit-image
matplotlib
pyinotify
lxml
sklearn
CTR+D
```

### Defining a Docker File

Paste the following in a Dockerfile.

```bash
# Image to build ros+gazebo+tensorflow ready for condor
FROM ros:kinetic-ros-base

LABEL "com.nvidia.volumes.needed"="nvidia_driver"

ENV TERM dumb

# install ros packages
RUN apt-get update && apt-get install -y \
    ros-kinetic-desktop \
    ros-kinetic-gazebo-ros-pkgs ros-kinetic-gazebo-ros-control \
    ros-kinetic-tf2-geometry-msgs \
    ros-kinetic-hector-pose-estimation \
    libignition-math2-dev \
    ros-kinetic-parrot-arsdk \
    ros-kinetic-hector-sensors-description \
    ros-kinetic-hector-localization \
    ros-kinetic-hector-models \
    ros-kinetic-teleop-twist-keyboard \
    ros-kinetic-hector-mapping \
    ros-kinetic-hector-gazebo \
    ros-kinetic-hector-gazebo-plugins \
    ros-kinetic-hector-sensors-description \
    ros-kinetic-hector-sensors-gazebo \
    python-pip vim less openbox

#-- current size: 3.09G (old)

# install cuda 8 
WORKDIR /usr/local
RUN apt-get update && apt-get install -y wget
RUN wget http://homes.esat.kuleuven.be/~kkelchte/lib/cuda-linux64-rel-8.0.61-21551265.run && \
	chmod 700 cuda-linux64-rel-8.0.61-21551265.run && \
	./cuda-linux64-rel-8.0.61-21551265.run -noprompt && rm -r cuda-linux64-*

#-- current size: 5.19G (old)

# install cudnn 6 by pulling it from esat homes.
WORKDIR /
RUN wget http://homes.esat.kuleuven.be/~kkelchte/lib/cudnn-8.0-linux-x64-v6.0.tgz && \
 	tar -xvzf cudnn-8.0-linux-x64-v6.0.tgz && \
	mv cuda /usr/local/cudnn && \
	rm cudnn-8.0-linux-x64-v6.0.tgz

#-- current size: 5.48GB (old)

# install pip packages including tensorflow (1.4)
WORKDIR /
RUN pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.4.0-cp27-none-linux_x86_64.whl

#-- current size: 6.42GB (old)

# rospy rospkg matplotlib are already pulled with tensorflow or ros
#COPY requirements.txt /tmp
#RUN pip install -r /tmp/requirements.txt

# alternative on requirements file:
RUN pip install --upgrade pip
RUN pip install pyyaml \
	scipy pillow \
	scikit-image pyinotify \
    lxml sklearn

#-- current size: 6.97GB
```

Pip versions:
* Versions:
* scipy (1.0.0)
* scikit-image (0.13.1)
* pyinotify (0.9.6)
* lxml (4.1.1)
* sklearn (0.0)
* rospy (1.12.7)
* rospkg (1.1.4)
* rospkg-modules (1.1.4)
* matplotlib (1.5.1)

### Build and push the image

Put the Dockerfile in an empty folder and go to this folder from the command line and put online.

```bash
$ sudo docker build -t kkelchte/test_image .
# install xorg manually and commit changes
$ sudo nvidia-docker run -it --rm --name rgt kkelchte/test_image bash
../# apt-get install xorg
> 29
> 1
# from a different window while container is still running
$ sudo docker commit rgt kkelchte/test_image:latest
# --current size: 6.92GB
$ sudo docker login
$ sudo docker push kkelchte/test_image:latest
```


### Build a singularity image from the docker image


```bash
$ cd /esat/qayd/kkelchte/singularity_images
$ singularity build ros_gazebo_tensorflow.img docker://kkelchte/test_image:latest
```

### Test image in singularity and create new clean build of github packages


```bash
$ singularity shell --nv kkelchte/test_image:latest
$$ source /opt/ros/$ROS_DISTRO/setup.bash
$$ source $HOME/simsup_ws/devel/setup.bash --extend
$$ source $HOME/drone_ws/devel/setup.bash --extend
$$ export export ROS_PACKAGE_PATH=$HOME/drone_ws/src:$HOME/simsup_ws/src:/opt/ros/kinetic/share
$$ export PYTHONPATH=$PYTHONPATH:$HOME/tensorflow/pilot
$$ export GAZEBO_MODEL_PATH=$HOME/simsup_ws/src/simulation_supervised/simulation_supervised_demo/models
$$ cd drone_ws
$$ catkin_make
$$ cd simsup_ws
$$ catkin_make
```


### (OPTIONAL) Test the image in docker

Add you as a user and update the image.

```bash
$ id
uid=1000(klaas) gid=1000(klaas) groups=1000(klaas)
$ sudo nvidia-docker run -it --rm --name my_container -u root kkelchte/test_image bash
$$ adduser --uid 1000 --gid 1000 klaas
# from different terminal window
$ sudo docker commit my_container kkelchte/test_image
```

Stop the running container and start a container as normal user with your homedir mounted and graphic session in order to **test ros and gazebo**:

```
$ sudo nvidia-docker run -it --rm --name my_container -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/klaas:/home/klaas -u klaas kkelchte/test_image bash
$$ export DISPLAY=:0
$$ export LD_LIBRARY_PATH=''
# test ros & gazebo
$$ source /opt/ros/kinetic/setup.bash
$$ roscore &
$$ gzserver --verbose &
$$ gzclient
```

Stop the running container and start a container as normal user with your homedir mounted to in order **test xpra**:

```
$ sudo nvidia-docker run -it --rm --name my_container -v /home/klaas:/home/klaas -u klaas kkelchte/test_image bash
$$ export HOME=/home/klaas
$$ XAUTHORITY=$HOME/.Xauthority
$$ export DISPLAY=:$((1 + RANDOM % 254))
$$ export PATH...
```
