---
title: Doshico Revisited
layout: default
---

# Solving DoShiCo

Towards the ICRA2019 deadline I want to resubmit with DoShiCo but hopefully with better results.

The core concept of DoShiCo lies in the fact that you can train end-to-end task specific strong features by providing them to a network in a simple simulated environment.
By learning to focus on these specific features the policy has a high chance to learn something that will actually generalize to a very different environments.

Differences with DoShiCo from last year:

- start off with turtlebot and go later to drone: See influence of drift on variance of results.
- add visualizations to see what influence from different parts of the input image is actually used for the decision.
- play around with new architectures: densenet, train from scratch, pretrain with object detection, ...

## Create new data

Test interactively performance of behavior arbitration on drone and prepare condor online command:

```bash
$ roscd simulation_supervised/python
# incase of alienware add "-pe virtualenv" in the end
$ python run_script.py -w canyon -w forest -w sandbox --robot drone_sim --fsm oracle_drone_fsm -n 3 -g --paramfile params.yaml -ds -pe sing
# or on condor
python condor_online.py -t test_online --not_nice --wall_time $((60*60)) -w canyon -w forest -w sandbox --robot drone_sim --fsm oracle_drone_fsm -n 3 --paramfile params.yaml -ds 
```

## Discovered large variances on frame rates over different machines

Each image that is saved in create_dataset.py gets a timestamp from rospy. This timestamp is invariant of condor-suspensions though the delays between ROS and gazebo are still there.
If delays over ROS would mean that Gazebo is working at a lower rate although ROS is counting faster, there is not necessarily a problem as the environment goes as slow as the images arrived.
If on the other hand Gazebo runs faster when ROS goes slower due to more resources provided to Gazebo, then there is a bad influence as the network receiving images through ROS will have a much lower framerate than set by the camera.

The numbers extracted are delays between images written away by create_dataset.py and ROS. They give an indication of 'slower' machines but not necessarily on what impact we can expect on the final performance.

Recorded data at 20fps:

|   	  | yildun  	 | garnet  		 | matar  		| sadr  	   | oculus  	  | kunzite  	 | emerald  	| jade  	   | amethyst  	  | iolite   	 |
|---------|--------------|---------------|--------------|--------------|--------------|--------------|--------------|--------------|------------- |--------------|
| canyon  | 6.78 (1.96)  | 10.71 (6.14)  | 6.57 (2.12)  | 6.49 (1.99)  | 6.46 (1.92)  | 10.63 (5.47) | 10.73 (5.88) | 10.63 (5.38) | 10.77 (6.04) | 10.82 (6.41) | 
| forest  | 6.66 (2.22)  | 9.71 (5.47)   | 6.24 (1.91)  | 6.16 (1.65)  | 6.25 (1.77)  | 9.75 (5.65)  | 9.77 (5.52)  | 9.81 (5.59)  | 9.73 (5.50)  | 9.93 (6.12)  | 
| sandbox | 5.94 (1.64)  | 9.84 (5.50)   | 5.46 (1.25)  | 5.35 (1.19)  | 5.44 (1.89)  | 9.64 (5.52)  | 9.78 (5.49)  | 9.73 (5.08)  | 9.89 (5.32)  | 9.92 (6.23)  | 
| total   | 6.46 (1.94)  | 10.09 (5.71)  | 6.09 (1.76)  | 6.00 (1.61)  | 6.05 (1.86)  | 10.02 (5.55) | 10.11 (5.64) | 10.05 (5.35) | 10.14 (5.62) | 10.24 (6.26) | 

Recorded data at 10fps:

|         | quartz       | pyrite       | topaz        | realgar      | wulfenite    | asahi        | 
|---------|--------------|--------------|--------------|--------------|--------------|--------------|
| canyon  | 9.20 (1.13)  | 9.18 (0.84)  | 9.21 (1.51)  | 9.20 (1.27)  | 9.17 (0.81)  | 9.16 (0.68)  | 
| forest  | 9.23 (1.47)  | 9.21 (1.25)  | 9.24 (1.67)  | 9.25 (2.24)  | 9.19 (1.11)  | 9.19 (1.17)  | 
| sandbox | 9.47 (5.00)  | 9.44 (4.58)  | 9.48 (5.15)  | 9.46 (4.65)  | 9.50 (5.46)  | 9.54 (5.99)  | 
| total   | 9.30 (2.53)  | 9.28 (2.22)  | 9.31 (2.77)  | 9.30 (2.72)  | 9.29 (2.45)  | 9.30 (2.61)  | 


\![Plot]({{ "/imgs/18-07-12-fps_create_data.png" | absolute_url }})

Conclusion:
Yildun, Matar, Sadr and Oculus has consistently lower framerates than Garnet, Kunzite, Emerald, Jade, Amethyst and Iolite (6 instead of 10).  
On the other hand is the variance on the slower machines much lower (2 vs 5.5).
Collecting data at a lower framerate introduces more frames saved per second (25 to 30) mainly depending on which environment (sandbox tends to be slower) but with very large variances(300 to 500).
The extra frames saved might be more related to the extra CPU (8 cores instead of 4) and therefore less suspensions than to the FPS of the camera.
The variance for the sandbox is significantly higher than the variance for the canyon/forest (5 vs 2). This is as expected as the sandbox is much more difficult to render.
This trend is not visible when recording at 20fps and not enough cpu cores so probably this is more related to the latter.

It seems that setting the camera at 20fps does not result in higher frame rates than 10fps when there is only limited cpu capacity.


Extracted frame rates from number of images divided by the time between the first and the last image of the run.

|         | yildun       | garnet       | matar        | sadr         | oculus       | kunzite      | emerald      | jade         | amethyst     | iolite       | 
|---------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|
| canyon  | 6.04 (3.18)  | 10.11 (6.07) | 5.56 (2.96)  | 5.82 (1.90)  | 5.39 (3.65)  | 9.58 (9.35)  | 9.91 (7.53)  | 9.53 (9.62)  | 10.36 (4.55) | 10.18 (5.20) | 
| forest  | 6.12 (1.15)  | 8.82 (5.51)  | 5.59 (1.34)  | 5.32 (2.12)  | 5.59 (1.40)  | 8.98 (4.67)  | 8.96 (5.17)  | 9.11 (4.47)  | 9.31 (2.49)  | 8.72 (7.95)  | 
| sandbox | 5.85 (0.58)  | 9.80 (0.82)  | 5.41 (0.53)  | 5.25 (0.56)  | 5.31 (0.46)  | 9.56 (0.83)  | 9.77 (1.05)  | 9.57 (2.74)  | 9.90 (0.87)  | 9.90 (1.18)  | 

|         | quartz       | pyrite       | topaz        | realgar      | wulfenite    | asahi        |
|---------|--------------|--------------|--------------|--------------|--------------|--------------|
| canyon  | 9.92 (0.00)  | 9.93 (0.00)  | 9.94 (0.00)  | 9.94 (0.00)  | 9.97 (0.00)  | 9.97 (0.00)  | 
| forest  | 9.87 (0.00)  | 9.88 (0.00)  | 9.89 (0.00)  | 9.90 (0.00)  | 9.95 (0.00)  | 9.94 (0.00)  | 
| sandbox | 10.02 (0.02) | 10.03 (0.03) | 10.01 (0.03) | 10.01 (0.03) | 10.13 (0.01) | 10.14 (0.02) | 

The framerate at the real-world is surprisingly correct with the ROS-rate. Of course it is uncertain how well this matches with the Gazebo frame rate.

It is still uncertain whether the high variance over frame rates at 20fps is due to the 20fps or the lack of cpu cores at hand... And of course also why it only reaches 5 to 10fps instead of 20....
