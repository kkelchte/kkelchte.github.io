---
title: Extracting Taxonomy
layout: default
---

# Calculating feature distances for taskonomy network

 <a href="http://taskonomy.stanford.edu/taskonomy_CVPR2018.pdf">Paper</a>
 <a href="https://github.com/StanfordVL/taskonomy/tree/master/taskbank">Github</a>

Install anaconda with shell script from conda website.
Retrieve correct conda environment with instructions on github.
Test on one image.
Adjust code to take as input many images and store representations.



 
```bash
bash
start_conda
conda activate testenv
cd /esat/opal/kkelchte/docker_home/tensorflow/taskonomy/taskbank
# extract 1 image input tasks
for TASK in rgb2depth autoencoder curvature colorization denoise edge2d edge3d rgb2mist inpainting_whole jigsaw keypoint2d keypoint3d class_1000 reshade room_layout class_places segment2d segment25d segmentsemantic rgb2sfnorm vanishing_point ; do
  echo
  echo "--------------------------------$(DATE +%H:%M) $TASK"
  for DATASET in /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/2500/00000_esatv3 /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_1_subsampled /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_2_subsampled; do
    #for DATASET in /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_1_subsampled ; do
    echo "----------$(DATE +%H:%M) $DATASET"
    IMAGES="$(for f in $DATASET/RGB/* ; do printf " $f"; done)"
    LOGFOLDER=/esat/opal/kkelchte/docker_home/tensorflow/log/feature_extraction/$TASK/$(basename $DATASET)/
    mkdir -p $LOGFOLDER
    python tools/get_representations.py --task $TASK --imgs $IMAGES --store-rep --store $LOGFOLDER
  done
done

for TASK in point_match ego_motion non_fixated_pose fix_pose ; do
  echo
  echo "--------------------------------$(DATE +%H:%M) $TASK"
  for DATASET in /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/2500/00000_esatv3 /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_1_subsampled /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_2_subsampled; do
    #for DATASET in /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_1_subsampled ; do
    echo "----------$(DATE +%H:%M) $DATASET"
    IMAGES="$(for f in $DATASET/RGB/* ; do printf " $f"; done)"
    LOGFOLDER=/esat/opal/kkelchte/docker_home/tensorflow/log/feature_extraction/$TASK/$(basename $DATASET)/
    mkdir -p $LOGFOLDER
    python tools/get_representations_multiimage.py --task $TASK --imgs $IMAGES --store-rep --store $LOGFOLDER 
  done
done

```

For each task, evaluate the extracted features from the real world how the control differs from features in the simulated corridor and whether the controls are the same.


## Train decision layers

```bash
for TASK in rgb2depth autoencoder curvature colorization denoise edge2d edge3d rgb2mist inpainting_whole jigsaw keypoint2d keypoint3d class_1000 reshade room_layout class_places segment2d segment25d segmentsemantic rgb2sfnorm vanishing_point point_match ego_motion non_fixated_pose fix_pose ; do
  python dag_train.py --load_data_in_ram --rammem 5 --wall_time "$((24*3600))" -pp taskonomy/taskbank/tools -ps train_decision_layers.py --learning_rates 0.0001 0.00001 0.000001 --max_episodes 1000000 --task $TASK --log_tag chapter_domain_shift/feature_extraction/$TASK/decision_net2 --n_frames 1 
done
for TASK in point_match non_fixated_pose fix_pose ; do
  python dag_train.py --load_data_in_ram --rammem 5 --wall_time "$((24*3600))" -pp taskonomy/taskbank/tools -ps train_decision_layers.py --learning_rates 0.0001 0.00001 0.000001 --max_episodes 1000000 --task $TASK --log_tag chapter_domain_shift/feature_extraction/$TASK/decision_net2 --n_frames 2 
done
for TASK in ego_motion ; do
  python dag_train.py --load_data_in_ram --rammem 5 --wall_time "$((24*3600))" -pp taskonomy/taskbank/tools -ps train_decision_layers.py --learning_rates 0.0001 0.00001 0.000001 --max_episodes 1000000 --task $TASK --log_tag chapter_domain_shift/feature_extraction/$TASK/decision_net2 --n_frames 3 
done
```

Drop out and action normalization failed to have a positive impact.
Next: train much longer but with smaller learning rates.

Parse results:
```bash
LR=lr_001; for d in * ; do echo " $d & $(cat $d/decision_net/$LR/tf_log | grep validation_loss | tail -n 1 | cut -d , -f 7 | cut -d : -f 2) & $(cat $d/decision_net/$LR/tf_log | grep test_loss | tail -n 1 | cut -d , -f 7 | cut -d : -f 2)\\\\"; done
```

In general all decision layers become degenerate, predicting one output and reaching the best overall performance which is not nice...
Therefore, extract depth maps from taskonomy network and train tiny net on depth inputs.

```bash
for TASK in rgb2depth ; do
  for DATASET in /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/original/00000_esatv3 \
    /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/original/00001_esatv3 \
    /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/original/00002_esatv3 \
    /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/original/00003_esatv3 \
    /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_1_subsampled \
    /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_2_subsampled; do
    echo "----------$(date +%H:%M) $DATASET"
    echo
    IMAGES="$(for f in $DATASET/RGB/* ; do printf " $f"; done)"
    LOGFOLDER=/esat/opal/kkelchte/docker_home/tensorflow/log/chapter_domain_shift/feature_extraction/$TASK/predictions/$(basename $DATASET)/
    mkdir -p $LOGFOLDER
    python tools/get_representations.py --task $TASK --imgs $IMAGES --store-pred --store $LOGFOLDER
  done
done
```

# Calculating feature distances for network with varying corridors

Source dataset is specified with `--dataset` tag, target dataset is hard coded as real_drone.
Image is extracted and places in log_tag folder as nearest_feature_image.png.
Checkpoint should be in log_tag folder as well.
If batch_size is not defined (default -1), it will not work.

```bash
env3
python main.py --dataset esatv3_expert/2500 --extract_nearest_features --log_tag chapter_domain_shift/variation/res18_reference/final/1 --batch_size 100
python main.py --dataset esatv3_expert/2500 --extract_nearest_features --log_tag chapter_domain_shift/variation/res18_augmented/final/1 --batch_size 100

```


With gaussian data --> improvement

Reference (res18 pretrained esat2500)
accuracy : 0.6788935658448587
SE : 0.2303788334335538
CTR: 0.33895906805992126

Randomized corridor (res18 pretrained varyingcorridor)
accuracy : 0.3048707155742634
SE : 0.6060733613950694
CTR: 0.12983009219169617

==> conclusion: use control prediction rather than distance.


# extract neural style transferred images

One job copies run_dir to destination, moves RGB to original and starts transferring from original to RGB.
Other jobs can be added on condor (after this initial step is performed).

```bash
python neural_style_tutorial.py --content_run_dir /esat/opal/kkelchte/docker_home/pilot_data/esatv3_expert/original/00003_esatv3 --style_run_dir /esat/opal/kkelchte/docker_home/pilot_data/real_drone/flying_2_subsampled --destination_dir /esat/opal/kkelchte/docker_home/pilot_data/esat_transferred
condor_submit condor_job_0
```


