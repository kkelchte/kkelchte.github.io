---
title: Extracting Taxonomy
layout: default
---

 <a href="http://taskonomy.stanford.edu/taskonomy_CVPR2018.pdf">Paper</a>
 <a href="https://github.com/StanfordVL/taskonomy/tree/master/taskbank">Github</a>

Install anaconda with shell script from conda website.
Retrieve correct conda environment with instructions on github.
Test on one image.
Adjust code to take as input many images and store representations.



 
```bash
bash
start_conda
testenv
cd /esat/opal/kkelchte/docker_home/tensorflow/taskonomy/taskbank
# for TASK in autoencoder curvature colorization denoise rgb2depth edge2d edge3d rgb2mist inpainting_whole jigsaw keypoint2d keypoint3d class_1000 reshade room_layout class_places segment2d segment25d segmentsemantic rgb2sfnorm vanishing_point non_fixated_pose fix_pose ego_motion point_match ; do
for TASK in autoencoder ; do
  echo $TASK
  for DATASET in /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/2500/00000_esatv3 /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_1_subsampled /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_2_subsampled; do
    IMAGES="$(for f in $DATASET/RGB/* ; do printf " $f"; done)"
    LOGFOLDER=/esat/opal/kkelchte/docker_home/tensorflow/log/feature_extraction/$TASK/$(basename $DATASET)
    mkdir -p $LOGFOLDER
    echo "python tools/get_representations.py --task rgb2depth --imgs $IMAGES --store-rep --store $LOGFOLDER"
  done
done

```


