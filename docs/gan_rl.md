---
title: Using GANs with RL
layout: default
---

# Using GAN's with RL to learn good recording behaviors for the autonomous director

The goal is to train a policy that can guide a drone to make _nice_ recordings of a sportevents. In these events there is often 1 clear region of intrest for instance a rockclimber, a person skiing, mountainbiking, ... . 

The idea of the paper to train a policy with Reinforcement Learning to behave in such a manner that a discriminator can't tell the difference between recordings the policy made and recordings coming from popular youtube movies. This discriminator loss is used as a reward signal in the policy search.

In order to avoid the discriminator to learn from features from the background of the rgb image, we use a masked representation. In this mask a region of intrest, aka attention blob, is defined in a binary image. The size and position of this image in comparison to previous images is used by the discriminator. This ensures the discriminator is discriminating according to the relative position of the attention blob in the image and not the content of the image itself. 
This comes with the assumption that the proper filming behavior can be captured in an attention blob that is using. 
This might not be the case the moment the filming behavior is dependent on the content of its surrounding: zooming out in a valley to give an overview, while in a forest this leads to too much clutter.

Why is this interesting? DNN policies are hard to train. In many cases PID controllers or pathplanning algorithms serve a better solution to the task of autonomous navigation. Some behavior might actually be impossible to learn. One might have demonstrations of a good behavior but with labels missing or irrelevant for a drone with totally different actions. In that case it could be interesting to imitate a general navigation behavior from movies without the need of labels. Neural Networks are known to be capable of capturing complex behaviors which seem impossible with normal heuristics. 

This paper is more a conceptual idea with a proof of concept. We explore a new type of problem namely unlabeled imitation learning. In the setting of imitation learning a policy tries to mimic the demonstrated behavior. This behavior is often expressed in a dataset containing both inputs (state representations) as well as labels (action taken by the demonstrator). The discriminator in GANs has already shown to be very usefull in this settings.

### Assumptions to take under consideration

* We can extract attention blobs in a consistent way, robust against clutter and occlusions.
	* Todo: find a proper segmentation/attention network that robustly detects the attention blob in the image.
* Filming behavior is defined by moving attention blobs. A state representation as an attention blob is enough to learn this behavior.
	* Todo: extract attention blobs from some nice looking youtube movies and try to discriminate from bad looking movies
	* Todo: define good and bad filming behavior
* The loss of a discriminator is a valid reward signal in RL.
	* Todo: train a grid world policy (ex Zig Zag) to act like a heuristic by taking the discriminators prediction as a negative reward that needs to be minimized

### Open decisions to take

* Start and stop recording: It is still unsure whether the policy also inherently learns when to start and stop recording. Ideally it learns this as well. Many sports consists of short frames coming from different corners.
* The state input of the policy 
* One or several sports
* How to proof the concept as a success
* What type of RL algorithm is used for training: GCG? TRPO? PG?
* In what order are we learning?

