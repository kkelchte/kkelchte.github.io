---
title: Structuring Ideas
layout: default
---

At SIMPAR and ICRA I realized the complexity of the task of control prediction with DRL trained end-to-end. 

```Damn you, attitude control and system dynamics!```

One of the main aspects of the problem I was disregarding was the difficulty and influence of the attitude controller.
It is not specifically hard to fly a drone in simulation or the real world if it has a stable attitude controller and you're speed stays reasonably low.
The tricky parts pops in when you train a neural network. 
You'll see that if the network has some temporal aspect for instance with an LSTM or 3D-CNN, the neural network will overfit towards this specific controller. 
In an online setting this shouldn't be a problem, though you can't expect your drone to be able to adapt its predicted control output towards a new controller.
In other words, you'll need to make sure that all rarities caused by the controller are filtered out both in simulation as in the real-world by for instance flying very slowly or using a turtlebot.
This means closing the control or range shift.
An alternative approach could be the use of randomization or generalization over the aspects in simulation of which you are uncertain. 
I partially played around with this by adding translational and orientational noise to the drone so it would act weird. 
The DNN needed to learn to find the safest control while these strange turbulence would apply.
Adding random noise to a control is a rather drastic and naive approach to mimic attitude inaccuracies. Better would be to use a set of different settings of drones that all very slightly on mass/inertia/friction/responsiveness/... . In this case the possible set of turbulences is much smaller and more relevant. 
I see this short coming of understanding as one of the major flaws of my current setup.

<img src="/imgs/18-05-25_noisy_control.png" alt="Naive incremental noise adding" style="width: 200px;"/>

It makes sense to abstract from this part and assume that if the agent gives understandable steering commands, the controller should take care of the attitude and navigation.
This is however not the case due to a too realistic drone model in simulation that drifts and react with delays as well as a rather sloppy bebop drone that fails to fly stable indoors.
At least this unfair assumption resulted in poorer simulated performances especially when trained from a tuned expert like behavior arbitration.

Having this tricky controller behavior that acts slightly different every simulation could also explain the high dependency on small latencies due to different physical machines resulting in a large variation.

It is however unclear how we best deal with this problem and whether it is our problem. 

If we want to **ignore the problem** or at least identify the problem we should at least run the doshico experiment with a floating camera object that acts perfectly stable. Or we can test it with the turtlebot. 
Alternatively we could try to **generalize** over the different control parameters as defined above.
A final and most attractive strategy might be to **learn to adapt** to the dynamics of the control in an unsupervised fashion. For this last strategy there are number of interesting tools to use:

* A **dynamics model** of the drone could be learned to predict a future frame or smaller state representation in feature space given current frame or feature and applied control. This can be trained from the demonstration data in order to finetune the dynamics model. The dynamics model can then be trained iteratively with the policy in a modelbased reinforcement learning fashion. In robotics, I guess they refer to this as system identification where you want to see how close you can model the real system from real data.
* If the only issue is drift, I could augment the controller with a control mapping that compensates in roll for current turn. This however requires a proper velocity estimation that needs to be learned. I'm referring here to Bart Theys's Phd.

Though both methods seem valid, they both are not specially exciting research directions for my phd. So if it really comes to this I might try one of the two out, assuming I already have a nice working DNN ready to perform a task in the real world. So in that sense I would prefer to choose to ignore the problem for now and work with the turtlebot or a drone with very zero inertia.

As a side note I want to refer to Mario Henrique Cruz Torrez that recommended me to work with the angular velocity as control rather than linear velocity. This is something I always ignored because I was only steering in yaw but I guess I could start worrying on that part to see if I can improve the predictiveness and stability of applied control.












General research question could be: what are the strongest features to use for indoor collision avoidance with drones given both a perceptual domain and a control range shift. 


