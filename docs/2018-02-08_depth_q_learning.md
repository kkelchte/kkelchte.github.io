---
title: Depth Q Learning
layout: default
---

In the experimental section we first derive the feasibility of the use of a continuous depth signal in comparison with a sparse collision signal.

Ensure there is a fair difference in delay between evaluating the depth maps (max(min(depth))) and taking the minimum collision.
Therefore it seems best to evaluate the different delays. 

|-|-|-|
| Average delay with coll_q_net  | qayd: 0.013s | nereid: 0.025s |
| Average delay with depth_q_net | qayd: 0.014s |  |

For both settings we make a small gridsearch over hyperparameters and use all computers online except the ones on the black list.
For the final experiments it is best to use solely the computers on the greenlist as they come with small delays.

Both methods can be learned offline from a big dataset. This would significantly speed up the training procedure especially for a good parameter search.
Although the hyperparameters might differ a lot from the offline to the online setting? This is arguable. 
It would be interesting to create a dataset taken from a mixed random policy and expert with maybe the use of gt_depth_pilot?
Created dataset with random (epsilon 1) flying behavior from which both depth_q_net and coll_q_net can be trained. 
Note that the labels for the coll_q_net (1 incase of collision within 10 frames) are not provided yet.


TODO:
Find hyperparameters: learning rate, weight decay, dropout, batchsize, batchnormalization, ... on offline dataset 'canyon_explored'

Quickly view of gridsearch 
on **coll_q_net**: very different training duration. Probably will have to put some wall time to maximum.
Bad ones: 23, 4, 19, 13, 2
Better ones: 26, 8, 5
Very noisy ones: 3, 6

The training loss decreases (0.3 --> 0.06) for 3, 5, 6, 19 but for most of the other models it increased (0.3 --> 0.5).

on **depth_q_net**:
Promissing ones: 10, 1 --> sharp increase in average distance
Stagnating ones: 2,5,8
Bad ones: 2 --> decaying average distance

Keeping epsilon to zero makes the model train up until a certain distance after which it stays but never improves. This is therefor not an interesting path to go. It seems to be a good idea to work with a decaying epsilon.

Learning 0.5 seems too high. Will work with 0.05 or 0.005. Epsilon is best 0.01 during the first 10 epochs and 0 afterwards.

REDO with decaying epsilon and different buffersizes and 2 learning rates: 0.5 and 0.05.

TODO:
check influence of buffersize.

TODO:
Give performance measures of gridsearch online with variance over 3 models.

| i | LR | EPSILON | NUM |
|-|-|-|-| 
| 0 | 0.5 | 0.1 | 0 |
| 1 | 0.5 | 0.01 | 0 |
| 2 | 0.5 | 0 | 0 |
| 3 | 0.05 | 0.1 | 0 |
| 4 | 0.05 | 0.01 | 0 |
| 5 | 0.05 | 0 | 0 |
| 6 | 0.005 | 0.1 | 0 |
| 7 | 0.005 | 0.01 | 0 |
| 8 | 0.005 | 0 | 0 |
| 9 | 0.5 | 0.1 | 1 |
| 10 | 0.5 | 0.01 | 1 |
| 11 | 0.5 | 0 | 1 |
| 12 | 0.05 | 0.1 | 1 |
| 13 | 0.05 | 0.01 | 1 |
| 14 | 0.05 | 0 | 1 |
| 15 | 0.005 | 0.1 | 1 |
| 16 | 0.005 | 0.01 | 1 |
| 17 | 0.005 | 0 | 1 |
| 18 | 0.5 | 0.1 | 2 |
| 19 | 0.5 | 0.01 | 2 |
| 20 | 0.5 | 0 | 2 |
| 21 | 0.05 | 0.1 | 2 |
| 22 | 0.05 | 0.01 | 2 |
| 23 | 0.05 | 0 | 2 |
| 24 | 0.005 | 0.1 | 2 |
| 25 | 0.005 | 0.01 | 2 |
| 26 | 0.005 | 0 | 2 |

