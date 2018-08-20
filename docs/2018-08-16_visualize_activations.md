---
title: Visualize Activations
layout: default
---


### Test different trained models interactively in jupyter

```
$ cdpilot
$ cd ../scripts
$ jupyter notebook visualize_nn.ipynb
```

The final code is integrated in tools.py and can be tested with:

```
$ python main.py --continue_training --load_config --max_episodes 0 --checkpoint_path canyon_drone/0 --device /cpu:0 --visualize_saliency_of_output
$ python main.py --continue_training --load_config --max_episodes 0 --checkpoint_path canyon_drone_discrete/0 --device /cpu:0 --visualize_saliency_of_output
$ python main.py --continue_training --load_config --max_episodes 0 --checkpoint_path canyon_drone/0 --device /cpu:0 --visualize_deep_dream_of_output
```

##### Canyon

<img src="/imgs/18-08-16_canyon.png" alt="Canyon Model" style="width: 200px;"/>



