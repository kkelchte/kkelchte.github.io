---
title: Domain Free Autonomous Navigation
layout: default
---

## The Context of the Problem

Autonomous navigation for drones (land and aerial) is still an open and quick evolving field. 
Drones are often equipped with camera's as they are lightweight, cheap and have no limited range.
Using the high dimensional camera input in a collision-free path planning algorithm requires a map building often based on SfM. 
These techniques however require easy feature to track and no occludence of the camera.
Another approach is to estimate the desired control directly on the camera input.
In this setting reinforcement learning (RL) techniques can be applied in which the camera frame represents the current state.
A policy maps this state to a desired action in our case an steering signal that avoids collision.
RL provides algorithms that train this policy to be optimal in that sense that it maximizes the cumulative future reward.
The policy however needs to be able to extract the state-space information from current and/or previous frames.
Because this input is high dimensional NxHxWxC (3x200x200x3=360000D), deep neural networks with convolutional layers are required to get a smaller (30D) representation.
With the use of back propagation this smaller dimensional feature representation can be trained end-to-end. 
This means that the gradients that adjusts the policy or control prediction layers will flow back through the network all the way to the input.
The benefit of this end-to-end training is that the features will be most discriminative for having a good policy on the data the policy is trained.
The big drawback is that training both a good state-space representation as control prediction layers, makes training slow and data-hungry.
A second pitfall of the end-to-end training is the high chance to end up with features that are informative only on the data the policy is trained while incapable to be still discriminative in newer environments.


## Related Work

## Research Question

## Method

## Experiments

## Conclusion

