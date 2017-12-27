---
title: Discrete control
layout: default
---

# Implementation notes

## step 1: redefine network for outputs

In mobilenet a parameter num_classes defines number of outputs.

## step 2: discretize labels

Add a `discrete` and `num_outputs` flag to model to indicate the number of outputs if model is discrete.
Add some initialization code in model.py to calculate discrete boundaries:
Define a list form [-bound, +bound] with num_outputs steps and keep the boundaries in a field.

```
if FLAGS.discrete:
  bin_width=2*self.bound/(FLAGS.num_outputs-1.)
  # Define the corresponding float values for each index [0:num_outputs]
  self.bin_vals=[-self.bound+n*bin_width for n in range(FLAGS.num_outputs)]
  b=round(-self.bound+bin_width/2,4)
  self.boundaries=[]
  while b < self.bound:
    # print b
    self.boundaries.append(b)
    b=round(b+bin_width,4)
  assert len(self.boundaries) == FLAGS.num_outputs-1
```

Add a discretize function to model that takes as input the targets as floats and returns indexes for one_hot labeling done at the loss side:

```
  def discretized(self, targets):
    '''discretize targets from a float value like 0.3 to an integer index
    according to the calculated bins between [-bound:bound] indicated in self.boundaries
    returns: discretized labels.
    '''
    dis_targets=[]
    for t in targets:
      res_bin=0
      for b in self.boundaries:
          if b<t:
              res_bin+=1
          else:
              break
      dis_targets.append(res_bin)
    return dis_targets

```


Current issue occurs when using data_format NCHW which is probably due to a library version difference in the contrib library between
singularity and my virtualenvironment. For now Ill use NHWC.
```
ValueError: Can not squeeze dim[3] expected a dimension of 1, got 29 for MobileV1/control/SpationSqueeze with input [?,9,1,29]
```



