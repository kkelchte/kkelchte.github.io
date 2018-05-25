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


### 2 Drones Playing Hide-and-seek: a proof of concept for end-to-end DRL in robotics applications

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
Ideally you could gradually go from a hand-crafted algorithm to an end-to-end DNN, evaluating the pros and cons of each block in a DNN fashion. But that seems to make the integration kind of hard.
The main benefit of having it all in a learning fashion seems to me the potential to generalize to a more wide set of environments while I would guess that the heuristic metacontroller will always be suboptimal unless it is tweaked for very specific environments.

So to conclude, I think this is a crazy ambitious thread that has its weight mainly in RL as you are training agents for a complex task rather than in computer vision. 
Having as a side project a SLAM-based obstacle avoidance combined with discovery and goal detection does not make thinks much easier as it will demand some fancy integration between control+SLAM+octomaps.
Though having a master thesis student to implement this could be comfortable. On the other, it would be a good integration challenge and will give quite some insight in the problem of autonomous navigation. 

Estimated time for having the setup with SLAM (including second turtlebot): 

2w(LSD-slam)
+ 1w (octomap)
+ 1w (3d-obstacle-avoidance)
+ 1w (adding discovery heuristic)
+ 1w (adding goal detector)
+ 2w (tweaking it all with a meta heuristic)
= 8 weeks ~ 2 months

Estimated time for training the DRL agents (assuming I understand the use of structural priors for autonomous navigation):

1w (creation of gridworld)
+ 1w (solving openAI gym MPC with TRPO) 
+ 1w (solving MPC with TRPO for fixed goal)
+ 1w (solving MPC exploring reward-shaping to get the incentives right) 
+ 1w (solving MPC with TRPO for adversary goal exploring reward-shaping to get the incentives right) 
+ 1w (solving MPC with cluttered environments as obstacle avoidance exploring reward-shaping to get the incentives right)
+ 2w (solving POMPC get-to-goal in FPV in empty room)
+ 2w (solving POMPC obstacle avoidance in FPV in cluttered room)
+ 2w (solving POMPC screening a larger region of cluttered rooms without collision)
+ 3w (combining it all with a meta network training end-to-end)
= 15 weeks ~ 4 months
+ 3w (switching from simulation to the real-world: finetune different subtask)
+ 3w (add an adversary goal learning algorithm)

What would be my contribution to the research society?

* competing obstacle avoidance (driving at fixed speed) with SLAM + octomap + path-planning versus training it end-to-end with a DNN: pros and cons on both robustness, tweaking, hardware constraints.
* visualize learned features for OA, discovering as well as target capturing might enlighten robotics community in the relevance of these features in contrast with having a labelled octomap.
* potential of encapsulating behaviors in a learning fashion which is very hard to define from an optimalization strategy: a proof of concept

The main critic in my point of view is that everything separately has already been shown to work so there is not much novelty. 
It's gonna be a hell of a work to implement though it will result in a nice journal paper or thesis encapsulating good practices while benchmarking to non-learning strategies.

HOWEVER, I should find a better focus on the reason to do all this work. 
If you focus on the application, you should probably take a higher abstraction level.

This is kind of as good as state-of-the-art learning has shown to perform in the real world. 
It is however unfortunate if we can't finish this or if it does not seem to work.

The main contribution I see is the search for structural priors (architecture, unsupervised pretraining, auxiliary tasks, ? use of basis filters ?) to simplify the learning on a set of different tasks.

I assume that this also means that I should not care about publications in that sense that I'm just aiming for one big journal paper at IJRR. 
Each task (OA, screening, target) with priors could be a different paper though.

Another big downside is the lack of real-world experiments or demonstrations.

```Vision: having the turtlebot being chased by the drone in a largely cluttered sportshall.```

In order to be able to demonstrate this in a real setting would mean the use of intermediate domain-invariant representations,
or a look-a-like sportshall in simulation or the necessary structural priors that could be applied according to the task or proper ways of finetuning to different sensor models, attitude control and environment.
I guess for the sensor model and perceived environment you could finetune to some recorded data from in the sportshall. 
For the attitude control however I think it is best to use an intermediate representation like a control raster, so the attitude control can be tweaked to fit its behavior of the raster to what happens in simulation.
Or we buy a better drone that is capable of flying according to this raster control.


### 3 The research question behind it: 'what prior knowledge is there to explore for autonomous navigation?'

```Learn only what matters and not everything that doesn't matter```

General research question could be: what are the strongest features to use for indoor collision avoidance with drones given both a perceptual domain and a control range shift. 

As the main contribution of my thesis (Towards robust semi- and fully autonomous monocular flight control for UAVs based on Deep Reinforcement Learning), I now think that the actual research question should be:
'what task-specific structural priors can I exploit for the case of fully autonomous monocular control predictoin based on DRL'.
I would leave the drone out due to the high dependency of the attitude controller which is only mediocre quality in the bebop drone. 
With this kind of controller we need extra space to have more freedom to kind of recover from strange behaviors which is not the case for our ESAT corridors.

RGB input is high dimensional. We don't want all the information that is there as our task only requires some specific information. 
The information it actually requires however is very different for each task. For example: 
(1) if we want to find a target object that is small in a cluttered environment we will have to be able to focus on small patches of the input.
(2) if we want to know what area we have already looked for we should be concious of our own movement which is most easy when looking at the global optical flow in your image. Note that this also requires the memory of what we have seen before so there should be recurrency in the network.
(3) if we want to avoid bumping into things, it is best to get a clue of where we are towards close objects which requires depth estimation and tracking of fast moving parts in the image. Whether a close object is on the left or on the right side from is has a huge impact on what desired control we want to apply. Therefor we don't want this feature to be for instance position or orientation invariant. Maybe we are more concerned about the depth of the next frame, or what we might expect when applying this control rather than that instead of only looking at current depth prediction.

In other words, this would mean that we will have to go into more details on deep learning and see what priors we can exploit. 
With priors I actually mean nothing more than:

* architecture of the network
* definition of the loss function for instance with the aid of unsupervised or self-supervised auxiliary tasks
* exploiting unsupervised pretraining like time contrastive networks, depth or optic-flow pretrained, third-person-estimator

I will focus less on the RL part that would define reward-shaping or data-sampling. These two concepts are more related to the RL part than to the D part from DRL. 

For data-sampling I also refer to the type of learning. In general I see RL as the most generic way of learning which allows for a more convenient task definition than imitation learning. 

However I do see the value of having an example flight for instance from which features could be finetuned as well as control(?).

Sample efficiency should be improved by using the structural priors. But wether the agent should learn with an A3C or TRPO or model based is not a main concern of this thesis.

Although I can expect problems on the part of exploration-exploitation depending on my reward. 
Other problems I can expect is the lack of convergence when training in an online fashion. 
I do think that this instable learning is also related with the lack of different policies that gather experience at the same time.
This might actually be the solution of my best-minibatch-sample-practice. This is, I think, having multiple agents all collecting experience in turn but training on minibatches of experiences from everybody.



### To conclude

So having this all written down, I would like to reschedule and reprioritize this all with proper in between milestones. 
I have the feeling that I'm reusing a lot from my past research but I'm also creating at least 2 to 3 times more work than what I've already done.
But at least it will fit nicely in a step-by-step project with clear intermediate hopefully success stories. 

In general I see the SLAM-octomap-path-planning-heuristic as a seperate though nice starting place to get a better understanding of the problem. 
Probably I can try to implement the heuristic that combines the OA and searching and targetting behavior as a learned agent that takes the 2d octomap as input.
This would allow to already try to get a hide-and-seek behavior on 2d partially observable octomaps which would be a great application contribution to ICRA 2018 although it assumes I have RL algorithm working on a octomap-like gridworld.
If I follow my planning estimation this would mean a large 3 months which is just enough to get before the deadline. 
Because it is SLAM based this should be able to work directly in the real-world if I have a good enough laptop (with dongle), stable enough drone and clear flying area.

I see the previous paragraph and this first contribution as an introduction to the problem and having my baseline model with all starting assumptions working:
- an RL algorithm that can learn a good behavior from a partially observable state space (though still having a lower dimensional octomap as input)
- an adversarial agent that makes it harder for the seeking agent 
- a raster-based control 

To continue from there, I gradually learn DNN's with DRL on the FPV instead of the gridworld for each concept task exploring naive and smarter approaches exploiting the structural priors related to the task.

The core of my thesis would than be this step-by-step training of an DNN agent for different control prediction tasks and seeing whether the structural priors help in convergence speed as well as generalization over domain shifts. (solely on the visual parts)
How I explore the task-dependent prior knowledge I will have to figure out along the way.




