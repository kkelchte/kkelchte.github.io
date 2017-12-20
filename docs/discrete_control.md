---
title: Discrete control
layout: default
---

# Implementation notes

## step 1: redefine network for outputs

In mobilenet a parameter num_classes defines number of outputs

## step 2: discretize labels

Add a `discrete` and `num_outputs` flag to model to indicate the number of outputs if model is discrete.
Add some initialization code in model.py to calculate discrete boundaries:
Define a list form [-bound, +bound] with num_outputs steps and keep the boundaries in a field.

```
    if FLAGS.discrete:
      bin_width=2*self.bound/(self.num_outputs+0.)
      b=round(-self.bound+bin_width,4)
      self.boundaries=[]
      while b < self.bound:
        self.boundaries.append(b)
        b=round(b+bin_width,4)
```

Add a discretize function to model that takes as input a placeholder for the targets and returns a tensor with onehot labels:

```
def discretized(self, targets):
		dis_targets=[]
    for t in targets:
      res_bin=0
      for b in self.boundaries:
          if b<t:
              res_bin+=1
          else:
              break
      res = np.zeros(self.num_outputs)
      res[res_bin] = 1
      dis_targets.append(res_bin)
    return tf.one_hot(tf.convert_to_tensor(dis_targets, dtype=tf.float32), depth=FLAGS.num_outputs)

```


