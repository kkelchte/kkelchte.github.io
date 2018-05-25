---
title: Structuring Ideas
layout: default
---

At SIMPAR and ICRA I realized the complexity of the task of control prediction with DRL trained end-to-end. 
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

![Naive incremental noise adding]({{ "/imgs/18-05-25_noisy_control.png"|absolute_url}} =250x)

It makes sense to abstract from this part and assume that if the agent gives understandable steering commands, the controller should take care of the attitude and navigation.
This is however not the case due to a too realistic drone model in simulation that drifts and react with delays as well as a rather sloppy bebop drone that fails to fly stable indoors.
At least this unfair assumption resulted in poorer simulated performances especially when trained from a tuned expert like behavior arbitration.

Having this tricky controller behavior that acts slightly different every simulation could also explain the high dependency on small latencies due to different physical machines resulting in a large variation.

It is however unclear how we best deal with this problem and whether it is our problem. If we want to ignore the problem or at least identify the problem we should at least run the doshico experiment with a floating camera object that acts perfectly stable. Or we can test it with the turtlebot. 









General research question could be: what are the strongest features to use for indoor collision avoidance with drones given both a perceptual domain and a control range shift. 


