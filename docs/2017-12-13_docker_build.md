
### 3 Defining a Docker File

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


# install cuda 9.1 
WORKDIR /usr/local 
RUN apt-get update && \
	wget http://homes.esat.kuleuven.be/~kkelchte/lib/cuda-linux.9.1.85-23083092.run && \
	chmod 700 cuda-linux.9.1.85-23083092.run && \
	./cuda-linux.9.1.85-23083092.run -noprompt && rm -r cuda-linux*

#-- current size: 5.19G (old)

# install cudnn 7.1 by pulling it from esat homes.
WORKDIR /
RUN wget http://homes.esat.kuleuven.be/~kkelchte/lib/cudnn-9.1-linux-x64-v7.1.tgz && \
 	tar -xvzf cudnn-9.1-linux-x64-v7.1.tgz && \
	mv cuda /usr/local/cudnn && \
	rm cudnn-9.1-linux-x64-v7.1.tgz

#-- current size: 5.48GB (old)

# install pip packages including tensorflow (1.8) with compute capability >3.5
WORKDIR /
RUN pip install --upgrade http://homes.esat.kuleuven.be/~kkelchte/lib/tensorflow-1.8.0-cp27-cp27mu-linux_x86_64.whl

# rospy rospkg matplotlib are already pulled with tensorflow or ros
#COPY requirements.txt /tmp
#RUN pip install -r /tmp/requirements.txt

# alternative on requirements file:
RUN pip install --upgrade pip
RUN pip install pyyaml \
	scipy pillow \
	scikit-image pyinotify \
    lxml sklearn h5py

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

### 4 Build and push the image

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


### 5 Build a singularity image from the docker image


```bash
$ cd /esat/qayd/kkelchte/singularity_images
$ singularity build ros_gazebo_tensorflow.img docker://kkelchte/ros_gazebo_tensorflow:latest
# You could try to build it writable (but requires sudo)
$ sudo singularity build --writable ros_gazebo_tensorflow_writable.img docker://kkelchte/ros_gazebo_tensorflow
$ scp ros_gazebo_tensorflow_writable.img kkelchte@ssh.esat.kuleuven.be:/esat/opal/kkelchte/singularity_images
```

### 6 (Alternative to clean build) Add package to singularity image if it is build writable

Note that this requires sudo permission. 
```bash
$ cd singularity_images
$ scp kkelchte@ssh.esat.kuleuven.be:/esat/opal/kkelchte/singularity_images/ros_gazebo_tensorflow_writable.img .
$ sudo singularity shell --nv --writable ros_gazebo_tensorflow_writable.img
$# apt-get update
$# apt-get install ...
CTR+D
$ scp ros_gazebo_tensorflow_writable.img kkelchte@ssh.esat.kuleuven.be:/esat/opal/kkelchte/singularity_images
# In case you want to update the drone_ws in /code, you first copy the drone_ws to /root with sudo as only /root is loaded in the image shell for sudo user.
$ rm -r /root/drone_ws
$ cp -r ~/drone_ws /root/
$ sudo singularity shell --nv --writable ~/singularity_images/ros_gazebo_tensorflow_writable.img
$# rm -r /code/drone_ws
$# mv /root/drone_ws /code
CTR+D
```

### 7 (Alternative to clean build) Add package to docker container and rebuild singularity

In this example we add the turtlbot3 package to the ros_gazebo_tensorflow docker image.
```bash
$ sudo nvidia-docker run -it --rm --name rgt kkelchte/ros_gazebo_tensorflow:latest bash
$# source /opt/ros/$ROS_DISTRO/setup.bash
# load in list
$# apt-get update 
# find your package with apt list (!apt-get list dont work!)
$# apt list | grep ros-kinetic | grep turtlebot3
# install packages you need
$# apt install ros-kinetic-turtlebot3
# --> In other window, without closing previous one: commit changes <--
$ sudo docker commit rgt kkelchte/ros_gazebo_tensorflow:latest
# --current size: 6.92GB
$ sudo docker login
$ sudo docker push kkelchte/ros_gazebo_tensorflow:latest
# repeat step 5
======
### Put singularity image on gluster

Ask bert to place new image on gluster.
```bash
$ cp /esat/opal/kkelchte/singularity_images/new_image.img /gluster/visics/singularity/
```

### 6 Test image in singularity and create new clean build of github packages


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
### 8 (OPTIONAL) Test the image in docker

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