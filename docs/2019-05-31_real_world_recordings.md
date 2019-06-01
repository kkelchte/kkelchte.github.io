---
title: Notes on real world recordings
layout: default
---

## Test flight in simulation

keyboard controls

|command|key|
|-------|---|
|takeoff| t |
|land   | l |
|go     | g |
|stop   | o |
|emergency|e|
|flattrim|f |
|right  | v |
|straight|x |
|left   | c |

Speed is 0.8

```
start_sing
source .entrypoint_graph
roslaunch simulation_supervised_demo drone_sim.launch full:=true fsm_config:=key_fsm log_folder:=real_drone/$(date +%d%m%y_%H%M%S) graphics:=true save_images:=true data_location:=real_drone/$(date +%d%m%y_%H%M%S) world:=esatv3
```

## Test flight real world

```
start_sing
source .entrypoint_graph
roslaunch simulation_supervised_demo drone_real.launch full:=true fsm_config:=key_fsm log_folder:=real_drone/$(date +%d%m%y_%H%M%S) graphics:=true save_images:=true data_location:=real_drone/$(date +%d%m%y_%H%M%S)
```
