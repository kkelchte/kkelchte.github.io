---
title: Transition from Tensorflow to Pytorch
layout: default
---

<!-- <img src="/imgs/18-10-29_doshico.png" alt="doshico environments" style="width: 800px;"/> -->

Due to the lack of reproducable computations with tensorflow, I decided to transfer my code to pytorch.
In this post I'll keep track of the major changes in structure and overall required translations.
During the transition I'll use both platforms within a virtual environment.
This allows me to keep Tensorboard for instance for plotting results of a pytorch model.

Files that will have to change are:

- model.py: almost all functions [must]
- tiny_v2_r.py & all other architectures: architecture / use of alexnet from pytorch [must] 
- offline.py: loop over trainable_variables for logging [must]
- tools.py: visualizations with tf.cnn_vis [must]
- main.py: initialize session, model, tensorboards filewriter [combination possible]
- data.py: multithreaded coordinator for stopping threads during data loading [combination possible]

Remarkable differences:

'operation' --> 'function'
Shape of tensor: nsample x height x width x nchannels --> nsample x nchannels x height x width

| toch command | meaning          | example                   |
|--------------|------------------|---------------------------|
| .view()      | resize/reshape   | x.view(-1,8)              |
| .numpy()     | change tensor>np | b=a.numpy()               |
| .to(device)  | move to gpu      | x.to(toch.device('cuda')) |
| (requires_grad=True) | track gradients | |
| .grad_fn     | backward gradient function | b=(a*a).sum(); b.grad_fn() |
| .backward(v) | calculates jacobian product with v | y.backward(v) |
| net.parameters()| returns trainable parameters | list(net.paramet) |
| print(net) | prints an overview of fields in network | |
| .unsqueeze(0) | add fake batch dimension | |
| .zero_grad() | zeroes the gradient buffers of all parameters | |
| state_dict() | print values of parameters of network as dictionary used for saving and loading model | self.net.state_dict().keys() |

## Step 1: pytorch load in model, no logging, no visualizations, tf data loading, continuous

First step is to have an alex model trained on the canyon dataset and evaluated online in gazebo with tensorflow everywhere pruned out except for the data loading.

Todo-list:

- load pretrained model if continue_training and model-file exists
- train with global step variable to continue from checkpoint

## Next:

Continuous to discrete:

- add classification layers
