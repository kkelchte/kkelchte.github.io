---
title: Increase Action Influence on Output
layout: default
---
# Increase Action Influence on Output

## Intro

While doing real-world experiments on the turtlebot for the depth-q-net workshop paper, I realized that the action input that is feeded to the network is lacking influence on the different depth predictions at the output.
This has a bad influence as the preferred next action is picked according to the best looking future depth map.
If all maps are very similar this leads to a very lucrative policy which is not what we want.

It seems that the prediction layer mainly focusses on getting the depth scan prediction as good as possible without caring too much about what action is actually applied.
It might also be that at training the depth is hard to link with the actual action.

Here is a series of hacks I tried and some intuitive qualitive results. Because everything is implemented, trained and evaluated within a day this report is not really valable more a reminder for the future.

## Predict further in the future

The training data is recorded at around 3fps. Predicting further in the future would mean that you quickly reach a time span of 1s which is pretty far away.

It is implemented by skipping 1frame with the `--subsample 2` option in offline training.

The validation and training loss were very noisy and the real-world behavior was not significantly different.

## Invert the action

The action ranges from [-1;1]. If input weigths with relu activations saturates the negative side this might give a bias towards the positive action (turning right).

It is implemented within depth-q-net and coll-q-net. It is activated with the `--add_inverted_action` option.

Training looked very similar as well as evaluation. Influence seemed zero probably due to batch normalization that occurs between the layers.

## Upscale the action

By adding a fully-connected layer at the action input before concatenation to the first prediction layer, we can add the physical influence of the action relative to the imagenet pretrained feature.

It is implemented within depth-q-net and coll-q-net. It is activated with the `--upscale_action` option.

Training looked very similar though evaluation appeared to give the best results.

## Predict the action

By predicting the action at the output the intermediate feature has to discriminate more strongly over different actions.

It is implemented within depth-q-net and coll-q-net. It is activated with the `--predict_action` option.

The action prediction is nicely learned although the network is probably making a shortcut directly between the output and the input without strongly changing the intermediate representation.

Tinne remarked that the latter problem can be overcome by creating an extra layer that tries to predict the action given the imagenet-feature and the predicted depth-map. The representation is then still adjusted but there is no potential to shortcut the connection between the action prediction and the action input due to the intermediate future-depth estimation.

Training looked very similar as well as the evaluation was unsatisfactory.

## Adjust the loss

You could add predictions for -1 and 1 at training time for a sample with for instance an action of 0.5. 

As a side loss you could force the intermediate representation of the image with -1 action to lie further away from 0.5 than the input combined with +1.

The forcing can be done with a triplet loss or just a combined:

`(sign(a)+1)/2*d(x_a,x_+1)/d(x_a,x_-1)+(sign(a)-1)/-2*d(x_a,x_-1)/d(x_a,x_+1)`
