---
title: Dockerfile
layout: default
---
### Intro

This is a guide to build docker images from a dockerfile. 

| Specifications | Version |
| -------------  | ------- |
| Ubuntu         |  16.04  |
| ROS            | Kinetic |
| Gazebo         |   7.07  |
| CUDA           |  9.1    |
| CudNN          |  7.0      |
| nvidia-docker  |  1      |
| tensorflow     |  1.5    |

### Preparation

Create a working dir.

```
$ mkdir -p ~/docker/ros_gz_tf
$ cd ~/docker/ros_gz_tf
```

Prepare the installation of cuda and cudnn by downloading the required files in you docker directory. This is not required for cuda version 9 and cudnn version 7 as they are inside the homes.esat.kuleuven.be/~kkelchte/lib folder.

For different versions it is recommended to perform the following steps inside the users/visics/kkelchte/public_home/lib folder so wget can pull the libraries inside your image.


```
$ wget https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux
$ chmod +x cuda_9.1.85_387.26_linux
$ ./cuda_9.1.85_387.26_linux --extract=$PWD
$ rm cuda-samples-linux-*
$ rm NVIDIA-Linux-*
$ rm cuda_*_linux
```

Download in your browser cudnn 7 from [here](https://developer.nvidia.com/compute/machine-learning/cudnn/secure/v7.0.5/prod/9.1_20171129/cudnn-9.1-linux-x64-v7).

```
$ mv ~/Downloads/cudnn-9.1-linux-x64-v7.0.tgz .
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
    ros-kinetic-turtlebot \
    ros-kinetic-turtlebot-gazebo \
    ros-kinetic-turtlebot3 \
    python-pip vim less wget

# install gazebo extra (to get 7.7 instead of 7.0)
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list 
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -
RUN	apt-get update && apt-get install -y gazebo7 libgazebo7-dev

#-- current size: 3.09G (old)

# install cuda 9.0 
WORKDIR /usr/local 
RUN apt-get update && \
	wget http://homes.esat.kuleuven.be/~kkelchte/lib/cuda-linux.9.1.85-23083092.run && \
	chmod 700 cuda-linux.9.1.85-23083092.run && \
	./cuda-linux.9.1.85-23083092.run -noprompt && rm -r cuda-linux*

#-- current size: 5.19G (old)

# install cudnn 7.0 by pulling it from esat homes.
WORKDIR /
RUN wget http://homes.esat.kuleuven.be/~kkelchte/lib/cudnn-9.1-linux-x64-v7.tgz && \
 	tar -xvzf cudnn-9.1-linux-x64-v7.tgz && \
	mv cuda /usr/local/cudnn && \
	rm cudnn-9.1-linux-x64-v7.tgz

#-- current size: 5.48GB (old)

# install pip packages including tensorflow (1.5) with compute capability 3.5
WORKDIR /
RUN pip install --upgrade http://homes.esat.kuleuven.be/~kkelchte/lib/tensorflow-1.4.0-cp27-cp27mu-linux_x86_64.whl

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

# Versions:
# scipy (1.0.0)
# scikit-image (0.13.1)
# pyinotify (0.9.6)
# lxml (4.1.1)
# sklearn (0.0)
# rospy (1.12.7)
# rospkg (1.1.4)
# rospkg-modules (1.1.4)
# matplotlib (1.5.1)

#-- current size: 6.97GB


# Stuff before xpra
RUN apt-get install -y openbox 

# TODO: apt-get install -y xorg xpra xserver-xorg-video-dummy 
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
$ sudo docker build -t kkelchte/ros_gazebo_tensorflow .
# install xorg manually and commit changes
$ sudo nvidia-docker run -it --rm --name rgt kkelchte/ros_gazebo_tensorflow bash
$$ apt-get install xorg xserver-xorg-video-dummy xpra
> 29
> 1
# from a different window while container is still running
$ sudo docker commit rgt kkelchte/ros_gazebo_tensorflow:latest
# --current size: 6.92GB
$ sudo docker login
$ sudo docker push kkelchte/ros_gazebo_tensorflow:latest
```


### Build a singularity image from the docker image


```bash
$ cd /esat/qayd/kkelchte/singularity_images
$ singularity build ros_gazebo_tensorflow.img docker://kkelchte/ros_gazebo_tensorflow:latest
```

### Test image in singularity and create new clean build of github packages


```bash
$ singularity shell --nv kkelchte/ros_gazebo_tensorflow:latest
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

### Put singularity image on gluster

Ask bert to place new image on gluster.
```bash
$ cp /esat/opal/kkelchte/singularity_images/new_image.img /gluster/visics/singularity/
```

### (OPTIONAL) Test the image in docker

Add you as a user and update the image.

```bash
$ id
uid=1000(klaas) gid=1000(klaas) groups=1000(klaas)
$ sudo nvidia-docker run -it --rm --name my_container -u root kkelchte/ros_gazebo_tensorflow bash
$$ adduser --uid 1000 --gid 1000 klaas
# from different terminal window
$ sudo docker commit my_container kkelchte/ros_gazebo_tensorflow
```

Stop the running container and start a container as normal user with your homedir mounted and graphic session in order to **test ros and gazebo**:

```
$ sudo nvidia-docker run -it --rm --name my_container -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/klaas:/home/klaas -u klaas kkelchte/ros_gazebo_tensorflow bash
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
$ sudo nvidia-docker run -it --rm --name my_container -v /home/klaas:/home/klaas -u klaas kkelchte/ros_gazebo_tensorflow bash
$$ export HOME=/home/klaas
$$ XAUTHORITY=$HOME/.Xauthority
$$ export DISPLAY=:$((1 + RANDOM % 254))
$$ export PATH...
```
