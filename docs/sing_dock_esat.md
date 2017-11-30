---
title: Using ROS-gazebo-tensorflow interactively on ESAT machines with Singularity
layout: default
---

# Using ROS-gazebo-tensorflow interactively on ESAT machines with Singularity

* step 1: see if the image is not already on Gluster / qayd
```
$ ls /gluster/visics/singularity
$ ls /esat/qayd/kkelchte/singularity_images
```

* step 2: if not, then pull the image. This might take a while...
	
	* from [docker](https://hub.docker.com/r/kkelchte/ros_gazebo_tensorflow/):
	
	```
	$ singularity build ros_gazebo_tensorflow.img docker://kkelchte/ros_gazebo_tensorflow:latest
	```

	* from [singularity hub](https://www.singularity-hub.org/collections/315):
	
	```
	$ singularity build ros_gazebo_tensorflow.img shub://kkelchte/simulation_supervised
	```

# Installing a package in singularity

Singularity wont let you write something in the image. Therefore you first need to adjust the docker image from which the singularity image was build:

### Start docker on your laptop

```bash
$ sudo docker run -it --rm -v /home/klaas:/home/klaas --name updated_container -u root kkelchte/ros_gazebo_tensorflow bash
$ apt-get install ...
$ pip install ...
```

### Commit your docker container to a new image

```bash
$ sudo docker commit updated_container kkelchte/ros_gazebo_tensorflow:proper_tag_name
sha256:a6f72b468de24daac7cd9379431f38235806d79dfe8418dc9904168ebb74093f
$ sudo docker images
```

### Upload the image to the docker hub

You might have to login in order to do this.

```bash
$ sudo docker push kkelchte/ros_gazebo_tensorflow:proper_tag_name
```

### Build a new singularity image

```bash
$ singularity build ros_gazebo_tensorflow.img docker://kkelchte/ros_gazebo_tensorflow:proper_tag_name
```	

# Troubleshoot

Pip uninstall and reinstall in docker might not be recognized by Singularity as an updated layer. Singularity probably keeps some cached docker layers from which singularity build pulls which seems to boycot a proper update of the singularity image. To overcome this issue I build the singularity image as a sandbox and run it in --writable mode after which I rebuild as a normal singularity read-only image file.

Note that even though this troubleshoot has only 3 steps, it actually take much longer. Building a writable sandbox takes up to more than 30min with an image of this size.

* Step 1: create a sandbox image as root

```
$ sudo singularity build --sandbox ros_gazebo_tensorflow docker://kkelchte/ros_gazebo_tensorflow:latest
```

* Step 2: adjust the singularity image in writable mode

```
$ sudo singularity shell --writable --nv ros_gazebo_tensorflow
> pip uninstall
> pip install --upgrade ...
> test..
```

* Step 3: build the singularity image again in read-only mode

```
$ sudo singularity build ros_gazebo_tensorflow.img ros_gazebo_tensorflow
```

