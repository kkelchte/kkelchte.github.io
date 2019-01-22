---
title: Policy Learning: The core ideas
layout: default
---

In this chapter we explore some of the difficulties as well as opportunities you can expect when training neural policies.
In order to do so, we will work with an example for which we gradually want to improve the performance.

Neural networks have proven to be most useful first in a the computer vision field where they are trained in a supervised fashion from a static dataset.
It seems most logic therefor to take a similar approach at least as first.

## Experiment 1: Naive imitation learning

In the first experiment we evaluate the same tiny network trained on different datasets:

_human_demo_one_: contains one demonstration flight through the corridor.
_human_demo_recovery_: is the same flight as human_demo_one but with recovery cameras.

TODO:
- create dataset _human_demo_one_
- create dataset _human_demo_recovery_
- hyperparameter search tiny pomerleau on _human_demo_one_
- hyperparameter search tiny pomerleau on _human_demo_recovery_
- train tiny pomerleau model on _human_demo_one_ and evaluate (5x)
- train tiny pomerleau model on _human_demo_recovery_ and evaluate (5x)
- hyperparameter search resnet on _human_demo_one_
- hyperparameter search resnet on _human_demo_recovery_
- train resnet model on _human_demo_one_ and evaluate (5x)
- train resnet model on _human_demo_recovery_ and evaluate (5x)


Adding recovery cameras:
This second appoach is very similar to one of the first successful demonstration of behavioral cloning in the DARPA challenge by Pomerleau.
As to validate, we take a similar sized network predicting one out of three steering angle given a 32x32 input image.
We expect this to work well for super small networks, however one we take the step to a classic res-net 50 network, we clearly fail due to overfitting.

## Experiment 2: More data

As a general rule of thumb in deep learning, more data is better.

Therefore we autmate the expert with the use of extra sensors only required at training time. 
This, I will further refer to simulation-supervised as the simulated environment provides a supervision signal based on extra sensors.
In our primal experiment, a simple heuristic based on a lidar range finder suffices to navigate the drone around in the corridor.

_expert_demo_hundred_: 100 flights through corridor
_expert_demo_thousand_: is the same flight as human_demo_one but with recovery cameras.

TODO:
- create dataset _expert_demo_hundred_ (with recovery camera's for later)
- add data specifications: flying time, number of images, distribution over outputs
- hyperparameter search resnet on _expert_demo_hundred_
- train resnet model on _expert_demo_hundred_ and evaluate (5x)

Conclusion: more iterations is not necessarily more information.

Explanation of state space shift between expert and student and long term unreliability.

## Experiment 3: Learning how to recover

In order to have the student recover from its own mistakes at test time, a significant amount of data should cover this aspect.
Therefor we add a random behavior with the expert, namely an OUNoise as exploration noise borrowed from RL.

As second step we also use recovery camera's with the expert.
A small note on recovery camera's, is that it introduces a wrong bias in temporal networks as the next frame does not correspond to the action taken.

Adding recovery camera's and noise

TODO:
- hyperparameter search resnet on _expert_demo_hundred_recovery_
- train resnet model on _expert_demo_hundred_recovery_ and evaluate (5x)
- create dataset _expert_demo_thousand_noisy_
- hyperparameter search resnet on _expert_demo_thousand_noisy_
- train resnet model on _expert_demo_thousand_ and evaluate (5x)

Adding noise to the data, increases the variance on the data and decreases the bias from the expert being different from the student.
The bias reduction leads to better performance but the variance in the data results in more training time, so a lower sample efficiency.



Rather than covering any stupid move the student can take at test time, it might make more sense to use the students' flying behavior when collecting a dataset and sampling form this dataset. 


## Experiment 4: On-Policy learning

This train of thought was taken by Ross etal when they came up with Dagger, where a student network pretrained on expert data flies through the environment with an expert anotating the data. In the next training iteration the student is trained on both the expert and the students data.

We could drive this idea even furhter and let the student fly from the start. Obviously you don't want this in the real-world, only in simulation.
The core idea behind this, is negative-mining: making the most likeli mistakes appear most often in the training data.
As the data seen during training is than the most relevant data to improve the policy, the policy might require less data samples and gain in data efficiency while overcoming also the bias introduced by the expert.

For this experiment we iterate between data collection and training.
In order to have the data still i.i.d. sampled, we have to collect large enough datasets (> 10.000 samples) from which K gradient steps are taken based on multiple randomly selected batches. 

_sidenote_ rather than sampling minibatches, it might make more sense to calculate the gradient on all current data in the replay buffer.

Because we can't reuse the data, as the policy changes each time, we gain very few information from one experience relating to lower sample efficiency. Though, we will leave this type of sample efficiency (information obtained per experience) aside for the next experiment. Here we only care about the amount of gradient steps or amount of input samples required before training has converged.

Note that one batch of data might result in a gradient in the right direction that with a correct learning rate will result in only one gradient step required.

However, training in an on-policy fashion, eventhough it is trained with sufficient amount of intermediate replay buffers, appears to be unstable.
We can demonstrate this with the evolving state space distribution of intermediate trained models trained on-policy and off-policy. 

The insight behind this, is the following. 
The model is trained towards a certain objective, namely minimizing the cross-entropy or MSE between the predicted action and the expert's action over different state spaces.
As mentioned above, is sampling from the total state space unfeasinably large, resulting in many uninformative samples such as looking close to a wall.
However, only using the expert's data is too biased, making a small divergence from this behavior resulting in a further divergence leading to instability.
A batch of data upon which a gradient step is taken, should represent the test distribution.
If this batch is sampled solely from the experts data, it will not properly represent the students' state-space.
However if this batch is sampled over the total (uniform, random) state space, a reliable gradient requires a super large batch to avoid extreme variance between consecutive batches.

A Dagger combination of the two seems a too naive approach as well as it appears hard for the network to leave current local minima for a better one in practice.

An alternative approach seen in literature is the concept of policy mixing.
This means that at each step a coin is flipped (binomial distribution) for picking the experts or the students action. 
This allows to demonstrate recovery from students' mistakes by the expert covering the students test state space still for a significant level.

The policy mixing and advantage should be demonstratable in the top-down view.
(EXTENSION) It would be nice if the CE between the expert and the student is visible in the color of the arrow.

One way to improve this behavior towards a safer learning, is to allow small mistakes of the student, but let the expert take over each time the loss is too high.
Having such an adaptive online policy mixing behavior might result in a higher sample efficiency due a decreased variance as well as bias.

TODO
- specify set of experiments


## More and more online

So far the gradient for the next step is calculated on the full data distribution/ or sampled from a large enough dataset so it is i.i.d..
This, however, demands slow iterations between collecting large datasets before a gradient step can be taken.
If we don't do this, and for instance use a smaller sample, the batch and so the gradient will be stronger biased.
Having a smaller buffer size and data batch to represent the current state-space, result in biased gradient steps.
These biased gradient steps obviously impedes the search for a optimum in the globabl or test state space.

There are however smarter ways to sample from smaller buffer sizes that can overcome this bias.

TODO 
- implement, test and visualize: repulsive point sampling technique
- implement, test and visualize: prioritized sweeping / keeping
- implement, test and visualize: hard replay buffer
- implement MAS regularization and visualize influence of (total) state space distribution over on-policy learning

## Time to outperform the expert, time to reinforce!

The expert is clearly still suboptimal as it takes turns larger than necessary and sometimes it even get stuck in a corridor resulting in a collision.
In the real-world this might be the case as well. 
Sometimes the final objective is not so easily demonstrated eventhough different expert heuristic based on extra sensory information are combined.
In some cases, the goal is better explainable with a reward than with a demonstration.

However, I know that previous statement might provoke some contraversial: learning from demonstration and imitation learning are rooted in behaviors that were not easily defined in a reward. Therefore a reward could be extracted from a demonstration with the use of inverse reinforcement learning.

In this case, however, we want to see if we could outperform the expert on the part of flying as fast as possible mutliple rounds through the corridor without any collision.
This can be translated in a negative reward on collision (-10/collision), a large positive reward per successfull round (+100/round) and a negative reward for living (-1/step).

To improve the previous trained policy P(a|s) with the reward, we can apply a simple bayesian rule: P(reward | s) = sum_a P(reward|a,s) P(a|s).

Or we could apply a well-established RL algo such as PPO in combination with the pretrained policy network: generalized advantage estimation in an actor-critic fashion.

As a baseline a RL model from scratch should indicate the advantage of IL pretraining.




