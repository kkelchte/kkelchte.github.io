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
- play around with new architectures: densenet, train from scratch, pretrain with object detection, 