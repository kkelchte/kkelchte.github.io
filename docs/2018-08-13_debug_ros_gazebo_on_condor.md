---
title: Debug Gazebo Simulations on Condor
layout: default
---


### Controller spawner of Hector Quadrotor error

```
$ cdlog
$ cd test_drone
$ for d in ? ; do echo "Job: $d"; echo "Host: $(cat $d/condor/*.out | grep HOSTNAME | cut -d '=' -f 2 | cut -d '.' -f 1)"; echo "success out of total sims: $(for f in $d/xterm_gazebo/* ; do cat $f | grep success; done | wc -l) / $(ls $d/xterm_gazebo | wc -l)"; controller_error=$(for f in $d/xterm_gazebo/* ; do if [ -z "$(cat $f | grep success)" ] ; then cat $f | grep 'Controller Spawner'; fi; done | wc -l); controller_error=$((controller_error/2)); echo "$controller_error controller spawner errors."; echo; echo; done
# get it in table form
$ echo ' | job | host | success | control spawn error | '
$ echo ' |-----|------|---------|---------------------|'
$ for d in ? ; do controller_error=$(for f in $d/xterm_gazebo/* ; do if [ -z "$(cat $f | grep success)" ] ; then cat $f | grep 'Controller Spawner'; fi; done | wc -l); controller_error=$((controller_error/2)); echo "| $d | $(cat $d/condor/*.out | grep HOSTNAME | cut -d '=' -f 2 | cut -d '.' -f 1) | $(for f in $d/xterm_gazebo/* ; do cat $f | grep success; done | wc -l) / $(ls $d/xterm_gazebo | wc -l) | $controller_error |"; done

```

___sandbox_drone___

| job | host | success | control spawn error | 
|-----|------|---------|---------------------|
| 0 | quartz | 50 / 66 | 16 |
| 1 | pyrite | 50 / 68 | 18 |
| 2 | spinel | 50 / 51 |  1 |
| 3 | topaz | 50 / 52  |  2 |
| 4 | realgar | 50 / 53 | 4 |
| 5 | ulexite | 50 / 54 | 5 |
| 6 | asahi | 50 / 64   | 14 |
| 7 | vauxite | 50 / 64 | 14 |
| 8 | ena | 50 / 62     | 12 |
| 9 | spinel | 50 / 53  | 3 |

Error occured 20 out of 20 simulations so keep Libra in Black list.

### Tensorflow out of memory

This is probably due to gpu-usage by daemon process which is not be visible for condor. 
Exit code from run_script should be sent through by run.sh within singularity to sing.sh within condor.

### BadDrawable Gazebo error

This occured on Andromeda 8/19 times. Is probably unrelated with the type of robot.

```
$ for d in ? ; do echo "| $d  | $(cat $d/condor/*.out | grep HOSTNAME | cut -d '=' -f 2 | cut -d '.' -f 1) | $(for f in $d/xterm_gazebo/* ; do cat $f | grep BadDrawable; done | wc -l) / $(ls -l $d/xterm_gazebo | wc -l) | "; done
```

### Continue on 5/09/2018

**Canyon drone conclusions:** 

- Bad Drawable pix map error occurs mainly on Andromeda and sparsely on bandai, ulexite, asahi, ena and wulfenite.
- Controller Spawner error occurs mainly on Andromeda and sparsely on bandai, ulexite, asahi, ena and wulfenite.
 
 | BadDrawable Pixmap | machine | |
 |--------|-------|-------|
 | 0_eva  | asahi | 1 / 4 | 
 | 1_eva  | spinel | 0 / 3 | 
 | 2_eva  | andromeda | 4 / 10 | 
 | 2_eva  | andromeda | 1 / 7 | 
 | 0_eva  | bandai | 0 / 11 | 
 | 1_eva  | ena | 0 / 11 | 
 | 2_eva  | ulexite | 0 / 11 | 
 | 3_eva  | bandai | 3 / 14 | 
 | 4_eva  | bandai | 5 / 16 | 
 | 0_eva  | andromeda | 7 / 18 | 
 | 1_eva  | ena | 0 / 11 | 
 | 2_eva  | ena | 2 / 13 | 
 | 3_eva  | ena | 0 / 11 | 
 | 4_eva  | ena | 2 / 13 | 
 | 0_eva  | andromeda ulexite | 7 / 28 | 
 | 1_eva  | bandai | 3 / 14 | 
 | 2_eva  | ulexite ulexite | 0 / 21 | 
 | 3_eva  | wulfenite | 1 / 12 | 
 | 4_eva  | opal andromeda | 6 / 27 | 
 | 0_eva  | andromeda | 0 / 3 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | andromeda | 0 / 3 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | leo | 0 / 3 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | andromeda | 1 / 4 | 
 | 1_eva  | asahi | 0 / 3 | 
 | 0_eva  | ulexite | 0 / 3 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | asahi | 0 / 3 | 
 | 1_eva  | quartz | 1 / 4 | 
 | 0_eva  | ulexite | 0 / 3 | 
 | 1_eva  | wulfenite | 0 / 3 | 
 | 0_eva  | bandai | 0 / 3 | 
 | 1_eva  | ena | 0 / 3 | 
 | 0_eva  | leo | 0 / 3 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | andromeda | 1 / 4 | 
 | 1_eva  | andromeda | 0 / 3 | 
 | 0_eva  | leo | 0 / 3 | 
 | 1_eva  | ulexite | 0 / 3 | 
 | 0_eva  | bandai | 0 / 3 | 
 | 0_eva  | andromeda | 1 / 4 | 
 | 1_eva  | wulfenite | 1 / 4 | 
 | 0_eva  | topaz | 0 / 3 | 
 | 1_eva  | asahi | 0 / 3 | 
 | 0_eva  | andromeda | 0 / 3 | 
 | 1_eva  | andromeda | 1 / 4 | 
 | 0_eva  | asahi | 1 / 4 | 
 | 1_eva  | spinel | 0 / 3 | 
 | 0_eva  | asahi | 0 / 3 | 
 | 1_eva  | asahi | 0 / 3 | 
 | 0_eva  | bandai | 1 / 4 | 
 | 0_eva  | andromeda | 0 / 3 | 
 | 1_eva  | andromeda | 1 / 4 | 
 | 0_eva  | ulexite | 0 / 3 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | ulexite | 1 / 4 | 
 | 1_eva  | ulexite | 0 / 3 | 
 | 0_eva  | andromeda | 1 / 4 | 
 | 1_eva  | leo | 0 / 3 | 
 | 0_eva  | spinel | 0 / 3 | 
 | 1_eva  | ena | 0 / 3 | 
 | 0_eva  | andromeda | 0 / 3 | 
 | 0_eva  | andromeda | 1 / 4 | 
 | 1_eva  | andromeda | 1 / 4 | 
 | 0_eva  | leo | 0 / 3 | 
 | 0_eva  | andromeda | 2 / 5 |

| job | host | success | control spawn error | 
|-----|------|---------|---------------------|
| 2_eva | andromeda | 0 / 9 | 4 |
| 2_eva | andromeda | 0 / 6 | 1 |
| 0_eva | bandai | 0 / 10 | 0 |
| 1_eva | ena | 0 / 10 | 0 |
| 2_eva | ulexite | 0 / 10 | 0 |
| 3_eva | bandai | 0 / 13 | 3 |
| 4_eva | bandai | 0 / 15 | 5 |
| 0_eva | andromeda | 0 / 17 | 7 |
| 1_eva | ena | 0 / 10 | 0 |
| 2_eva | ena | 0 / 12 | 2 |
| 3_eva | ena | 0 / 10 | 0 |
| 4_eva | ena | 0 / 12 | 2 |
| 0_eva | andromeda ulexite | 10 / 27 | 7 |
| 1_eva | bandai | 5 / 13 | 3 |
| 2_eva | ulexite ulexite | 11 / 20 | 0 |
| 3_eva | wulfenite | 4 / 11 | 1 |
| 4_eva | opal andromeda | 8 / 26 | 6 |
| 0_eva | andromeda | 0 / 2 | 0 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | andromeda | 0 / 2 | 0 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | leo | 0 / 2 | 0 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | andromeda | 0 / 3 | 1 |
| 1_eva | asahi | 0 / 2 | 0 |
| 0_eva | ulexite | 0 / 2 | 0 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | asahi | 0 / 2 | 0 |
| 1_eva | quartz | 0 / 3 | 1 |
| 0_eva | ulexite | 2 / 2 | 0 |
| 1_eva | wulfenite | 2 / 2 | 0 |
| 0_eva | bandai | 2 / 2 | 0 |
| 1_eva | ena | 1 / 2 | 0 |
| 0_eva | leo | 0 / 2 | 0 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | andromeda | 0 / 3 | 1 |
| 1_eva | andromeda | 0 / 2 | 0 |
| 0_eva | leo | 1 / 2 | 0 |
| 1_eva | ulexite | 2 / 2 | 0 |
| 0_eva | bandai | 2 / 2 | 0 |
| 0_eva | andromeda | 0 / 3 | 1 |
| 1_eva | wulfenite | 0 / 3 | 1 |
| 0_eva | topaz | 1 / 2 | 0 |
| 1_eva | asahi | 2 / 2 | 0 |
| 0_eva | andromeda | 2 / 2 | 0 |
| 1_eva | andromeda | 2 / 3 | 1 |
| 0_eva | asahi | 2 / 3 | 1 |
| 1_eva | spinel | 2 / 2 | 0 |
| 0_eva | asahi | 2 / 2 | 0 |
| 1_eva | asahi | 2 / 2 | 0 |
| 0_eva | bandai | 0 / 3 | 1 |
| 0_eva | andromeda | 0 / 2 | 0 |
| 1_eva | andromeda | 0 / 3 | 1 |
| 0_eva | ulexite | 0 / 2 | 0 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | ulexite | 0 / 3 | 1 |
| 1_eva | ulexite | 2 / 2 | 0 |
| 0_eva | andromeda | 0 / 3 | 1 |
| 1_eva | leo | 0 / 2 | 0 |
| 0_eva | spinel | 1 / 2 | 0 |
| 1_eva | ena | 1 / 2 | 0 |
| 0_eva | andromeda | 0 / 2 | 0 |
| 0_eva | andromeda | 0 / 3 | 1 |
| 1_eva | andromeda | 0 / 3 | 1 |
| 0_eva | leo | 0 / 2 | 0 |
| 0_eva | andromeda | 0 / 4 | 2 |



| machine | total |
|---------|-------|
| andromeda| 35 |
| bandai  | 12 |
| ena     | 2 |
| wulfenite | 6 |
| asahi   | 8 |
| topas   | 2 |

Currently errors occur always together, both the controller spawner as the baddrawable, but around the same time (11/40).

### Debugging Network Issues and Speeding up Offline training

If data fits in RAM it is definetely worth it to try ! `--load_data_in_ram` and monitor with `dstat --mem-adv`.
In case the dataset is too big, there are two options:

1. Get data while training one image at a time from opal [default]. This is good if dataset is very big and network is not too slow.
2. Copy data at the start over the network and save it in /tmp with the `--copy_dataset` option. This introduces a large overhead at the start of the job, which will slowdown also the beginning of training but if the dataset is not too big and the training is long (>100 epochs) and the network is saturated, it is probably worth it.

Option 2 is not faster than option 1 in the case the network is not saturated because reading data from the hard drive is almost as fast as asgart.

As a side note, you can compress (loseless) your dataset with `jpegoptim` with a relative improvement of around 8%:

```bash
$ jpegoptim -s your_data_set
```

In case the network is really saturated, the main winner is probably to save your dataset in hdf5, copy it to the /tmp. This copy will take less than a minute as most of the time of copying a large dataset goes to checking if adres is free, claiming address,... 
And reading your data from the shuffled hdf5 file. This might be something for in the future if large (>10G) datasets are required.
 




