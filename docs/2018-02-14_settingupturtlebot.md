---
title: Turtlebot
layout: default
---


# Setting up the turtlebot on alienware

## 1. Creating the internet connection

Initially I tried to get the hotspot working on alienware though without success. The current driver (wl) with the network card (broadcom BCM4352) is not capable of creating a hotspot. `$ iw list`
Start a hotspot on the Turtlebot:

```bash
nmcli con add type wifi ifname wlan0 con-name Hotspot autoconnect yes ssid Hotspot
nmcli con modify Hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify Hotspot wifi-sec.key-mgmt wpa-psk wifi-sec.psk "turtlebot"
nmcli con up Hotspot
ip addr
```

Connect from alienware to this hotspot and login with ssh

```bash
nmcli dev wifi rescan
nmcli def wifi list
nmcli dev wifi connect Hotspot password turtlebot
ssh turtlebot@10.42.0.1
****
```

## 2. Install software on laptop

```bash
# install realsensecamera manually
sudo sh -c 'echo "deb-src http://us.archive.ubuntu.com/ubuntu/ xenial main restricted
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-updates main restricted
deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://security.ubuntu.com/ubuntu xenial-security main restricted" > \
  /etc/apt/sources.list.d/official-source-repositories.list'
sudo apt-get update
sudo apt-get install ros-kinetic-turtlebot ros-kinetic-turtlebot-apps ros-kinetic-turtlebot-interactions ros-kinetic-turtlebot-simulator ros-kinetic-kobuki-ftdi ros-kinetic-ar-track-alvar-msgs
```

Create alias for sourcing environment:

`alias turtle='export ROS_MASTER_URI=http://10.42.0.1:11311 && export ROS_HOSTNAME=10.42.0.203'`

Test by running roscore at turtlebot and checking on alienware: `$ turtle && rostopic list`

Install chrony, `sudo apt-get install chrony`, for synchronisation.

There are two ways of setting up the environment depending on where roscore is running.
In case of **ROSMASTER on alienware** the following settings apply:

|machine|environment variable|value|
|-|-|-|
|alienware|ROS_MASTER_URI|http://10.42.0.203:11311|
|alienware|ROS_HOSTNAME|10.42.0.203|
|turtlebot|ROS_MASTER_URI|http://10.42.0.203:11311|
|turtlebot|ROS_HOSTNAME|10.42.0.1|

In case of **ROSMASTER on alienware** the following settings apply:

|machine|environment variable|value|
|-|-|-|
|alienware|ROS_MASTER_URI|http://10.42.0.1:11311|
|alienware|ROS_HOSTNAME|10.42.0.203|
|turtlebot|ROS_MASTER_URI|http://10.42.0.203:11311|
|turtlebot|ROS_HOSTNAME|10.42.0.1|



## 3. Start robot

pw: esat

```
(alienware)$ ssh turtlebot@10.42.0.1
(turtlebot)$ roslaunch turtlebot3_bringup turtlebot3_robot.launch
(turtlebot)$ roslaunch turtlebot3_bringup turtlebot3_remote.launch
(turtlebot)$ roslaunch raspicam_node camerav2_410x308_10fps.launch

(alienware)$ turtle
(alienware)$ roslaunch turtlebot_rviz_launchers view_robot.launch --screen
(alienware)$ roslaunch simulation_supervised_demo turtleot.launch
```

## 4. Create scan based oracle

File depth_heuristic.py in simulation_supervised_control.

## 5. Visualize topi

```
$ rosrun image_view image_view image:=/raspicam_node/image/ _image_transport:=compressed
```

## 6. Scan range

I measured at 10cm and 1m a camera field of view from -52degrees to 52 degrees.
The field of view slightly increased at 1m (54degrees). 
This means that camera ahead of the lazer but as the difference is so small and the hardware is at its limit I decide to continue with this setting.

The field of view is taken as 104 degrees.

The wide-angle camera is adapted in the turtlebot model in simulation.

```
(alienware)$ export ROS_MASTER_URI=http://10.42.0.203:11311 && export ROS_HOSTNAME=10.42.203
(alienware)$ roscore&
(alienware)$ ssh turtlebot@10.42.0.1
(turtlebot)$ roslaunch turtlebot3_bringup turtlebot3_robot.launch
(turtlebot)$ roslaunch turtlebot3_bringup turtlebot3_remote.launch
(turtlebot)$ roslaunch raspicam_node camerav2_410x308_10fps.launch
# new screen
(alienware)$ export ROS_MASTER_URI=http://10.42.0.203:11311 && export ROS_HOSTNAME=10.42.203
(alienware)$ roslaunch simulation_supervised_demo turtle_real.launch full:=true graphics:=true
# new screen
(alienware)$ export ROS_MASTER_URI=http://10.42.0.203:11311 && export ROS_HOSTNAME=10.42.203
(alienware)$ rosrun image_view image_view image:=/raspicam_node/image/ _image_transport:=compressed
```

