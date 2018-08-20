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
$ for d in ? ; do echo " | $d  | $(cat $d/condor/*.out | grep HOSTNAME | cut -d '=' -f 2 | cut -d '.' -f 1) | $(for f in $d/xterm_gazebo/* ; do cat $f | grep BadDrawable; done | wc -l) / $(ls -l $d/xterm_gazebo | wc -l) | "; done
```

