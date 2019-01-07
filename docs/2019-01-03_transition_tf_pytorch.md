---
title: Preparation for Policy Learning Batch
layout: default
---


### Creation of circular ESAT

Created new Blender model with windows, lights and a circular parcours without dead ends.

<img src="/imgs/19-01-10_esatv3.jpg" alt="circular esat" style="width: 500px;"/>
<img src="/imgs/19-01-10_esatv3_1.jpg" alt="circular esat" style="width: 300px;"/>


Todo:
- Add starting positions
- Add yaml file with configuration of success/failure

### Transition from Tensorflow to Pytorch

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


Different steps and notes during implementation:

_reproducability_
Cudnn, torch, random, numpy are all seeded. If only one thread `--num_threads 1` is used, the model can be trained in a fully reproducable way.

_saving and loading model_

For each network the layers of the network that are modular should have the same name so they are easily transferrable.
The optimizer is saved in the model by name and hyperparameters are only loaded when the current optimizer is the same.

In case a pretrained model from torch.vision is required, it is best to make a new Net class for this model that loads the architecture and concatenate the output layers.

_continuous to discrete actions_

The CrossEntropy Loss takes as prediction input the raw values before soft max and as targets the indices of the correct label but not in a one-hot fashion.
In the `discretize` function, the target values are translated to the correct form depending on the loss function.

_test online_

check!

_Extensions_

- Add tensorboard logging
- Add visualizations in tools: https://github.com/choosehappy/PytorchDigitalPathology/tree/master/visualization_densenet/pytorch-cnn-visualizations

## 