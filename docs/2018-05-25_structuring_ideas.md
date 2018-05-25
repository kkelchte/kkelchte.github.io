---
title: Structuring Ideas
layout: default
---

_At SIMPAR and ICRA I realized the complexity of the task of control prediction with DRL trained end-to-end namely the influence of the dynamics of the model. This is discussed in 1. 
Besides this main control concern, I was having some other new insides I would like to keep in mind and are listed in section 2 and 3._

### 1 don't just ignore the influence of a bad attitude controller
```Damn you, attitude control and system dynamics!```

One of the main aspects of the problem I was disregarding was the difficulty and influence of the attitude controller or the dynamics of the drone.
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


### 2 Drones Playing Hide-and-seek: a proof of concept for end-to-end DRL
```Time to get ambitious again to boost up the energy```
I have been focussing on this low level collision avoidance for quite some time with the idea that a simple reactive control is a proper place to start.
Now that I assume that the struggle of the progress so far is mainly due to bad attitude controllers (which I should check by performing Doshico on turtlebot), I do think it is time to go back again to a higher abstraction level and aim for more complex tasks.
Some more difficult tasks would for instance be a hide-and-seek implementation where a drone should learn to scan an area in search for something. This task includes remembering what areas are already screened, what parts of the scenery is occluded so should be discovered further, ... . Whether the AI learns to do a depth-first search or screens areas more thoroughly on the fly, is open for the AI to learn. 
From a game point of view, it would as well be cool if the previous AI can be learned, to get a second AI controller in there that learns to hide from the first as an adversarial. 

This hide-and-seek game can be implemented both with drones as well as turtlebot. It will be important to start off from a high abstraction level, very game-like, to shape the reward, to see the influence of imitation learning, ... .
Maybe a gridworld example with a full state-space can already be interesting to start from and apply TRPO-GAE to or another state-of-the-art RL algorithm. The fun comes in when the adversarial agent is learned simultaneously. 
The next step would be going from a small dimensional fully-observable state-space to a more partially observable state space by occluding parts of the gridworld.
Once this seems to work, it is time to go to a turtlebot in an empty room with one red object that is the target to get to as a goal state. 

In order to simplify the training procedure you could add the current goal location as input of which gradually noise is added so the networks learns to ignore it.

The task can be made more difficult by cluttering the environment and gradually taking the goal object more and more out of view. 
Currently probably learning becomes already surprisingly hard and techniques to find proper pretraining are required or other ways to put prior knowledge in the network. 
This is when prior knowledge will have to simplify the search to good model parameters, as is discussed in the next section.

The next step would than be to make the environment gradually more and more complex, hiding the goal object in different rooms. 
This is maybe also the point where training needs to be split up in different concepts:

* a subnetwork for recognizing the goal object and going towards it (which we should already have)
* a subnetwork for screening an indoor environment (which can be learned by making the drone free from collision)
* a subnetwork for obstacle avoidance (which can be learned seperately)
* a meta network should than combine the different outputs as well as feature representations to learn which part of the controller becomes most important

If I succeed at doing all this, which would be incredibly amazing, it is time to make the goal object a separate agent. 
It might be able to learn how to hide and in that sense that it learns to stand still or move quickly or maybe lurk behind the predator.
I am however very sceptible in how this all scales. 

In order to dive deeper into to benefits of having everything learned and approximated with deep neural networks, 
I could make the same thing with SLAM and tweaking and see which one can find the goal faster.

* obstacle avoidance < SLAM-based path-planning
* screening indoor scene < SLAM-based discovering
* go towards the goal < detect the goal and place it in the SLAM-build map
* have a heuristic or meta-controller that weights the different behaviors

Though on the other hand, it is discussible where the real benefits of end-to-end learning lies. 
Ideally you could gradually go from a hand-crafted algorithm to an end-to-end DNN, evaluating the pros and cons of each block in a DNN fashion.
The main benefit of having it all in a learning fashion seems to me the potential to generalize to a more wide set of environments while I would guess that the heuristic metacontroller will always be suboptimal unless it is tweaked for very specific environments.



### 3 'what prior knowledge is there to explore for autonomous navigation'
```Learn only what matters and not also everything that doesn't matter```

General research question could be: what are the strongest features to use for indoor collision avoidance with drones given both a perceptual domain and a control range shift. 


