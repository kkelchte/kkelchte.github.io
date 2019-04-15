---
title: Reproduce Results of Training Deep Policies
layout: default
---

# Training Deep Policy Experiments

## Off- & On-policy Training

### 3DCNN-Tiny Online Evaluation Measures: The need of on-policy evaluation

Train 3D-CNN-Tiny models on a small dataset, such as Esatv3_expert_10K, offline with different learning rates and different seeds.

Evaluate all nine (3x3) models online for 10x on Opal: mean=..., std=... .
Evaluate all nine (3x3) model online for 10x on Condor: mean= ..., std=... .

Demonstrate how validation accuracy does not necessarily correlate with online performance.

For each learning rate:

| model | validation accuracy | online performance |
|       |      mean (std)     |     mean (std)     |
|-------|---------------------|--------------------|
| 3DCNN |                     |                    |
| 3DCNN |                     |                    |
| 3DCNN |                     |                    |


Result:

Scatter plot with offline validation accuracy vs online collision free distance.



