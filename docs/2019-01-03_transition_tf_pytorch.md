---
title: Preparation for Policy Learning Experiments
layout: default
---


### Creation of circular ESAT

Created new Blender model with windows, lights and a circular parcours without dead ends.

<img src="/imgs/19-01/19-01-10_esatv3.jpg" alt="circular esat" style="width: 400px;"/>
<img src="/imgs/19-01/19-01-10_esatv3_1.jpg" alt="circular esat" style="width: 400px;"/>


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

## Add Pauzing and Reset of Gazebo Physics


`rosservice call /gazebo/pause_physics "{}"`


`rosservice call /gazebo/reset_simulation "{}"`

`rosservice call /gazebo/set_model_state '{model_state: { model_name: quadrotor, pose: { position: { x: 0.3, y: 0.2 ,z: 0 }, orientation: {x: 0, y: 0.491983115673, z: 0, w: 0.870604813099 } }, twist: { linear: {x: 0.0 , y: 0 ,z: 0 } , angular: { x: 0.0 , y: 0 , z: 0.0 } } , reference_frame: world } }'`

Use `--one_world` option if each run should be in the same world when the world has also a generator.

## Primal experiment

Settings

| Setting        | Value |
|----------------|-------|
| policy-mixing  |  0.5  |
| buffersize     |  500  |
| speed          |  1.3  |
| turn speed     |  0.5  |

By pauzing and unpauzing gazebo during the process and training step of torch, the real time factor of ROS is less than 50%. 
This means that 4minutes of training time takes more than 8minutes of real time.
It is questionable whether this is actually required.

Duration for 1 training step at each frame is 0.124s. This means that if pause simulator was not on, the duration is longer than the period rosinterface has between 2 frames (0.1s).
Tensorboard logging has almost no influence on this.
Taking two gradient steps for the same replay buffer increases the delay to 0.168s.

One way to fasten the experiment is by lowering the frame rate (6FPS ~ 0.16s) of the camera and not pausing the simulator.
Similarly you could work at 30FPS and repeating the previous action for 5 frames requiring a next training step and control decision every 6FP and not pausing the simulator.
The main speed up lies in training at the same rate as the frames come in so there is no waiting for a next frame.
Just increasing the framerate to 30FPS would already lower the 0.1s waiting for next frame to 0.033s however not that much will have changed in the simulated environment, making the two frames almost identical.
Conclusion: as DQN's have shown that working at 30FPS but repeating an action over several frames to adjust the training speed with the frame rate will probably give most gains.
In general I'm not very fond of this technique as the control will always be 0.125s later than the frame on which it is decided.
By pausing the simulator we ensure this delay does not effect the performance. So unpausing for speed up seems like a bad idea to startoff with.

