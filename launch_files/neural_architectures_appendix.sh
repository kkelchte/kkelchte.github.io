#!/bin/bash
# Script for launching condor jobs invoking both condor_offline.py and condor_online.py scripts.
# Dependencies: condor_offline.py condor_online.py

# OVERVIEW OF PARAMETERS

# 0. dag_create_data / dag_train_and_evaluate
# --number_of_recorders
# --number_of_models
# --destination
# --dont_retry
# --copy_dataset

# 1. directory and logging
# --summary_dir
# --data_root
# --code_root
# --home
# --log_tag

# 2. tensorflow code
# --python_project q-learning/pilot
# --python_script main.py
# --python_environment sing

# 3. condor machine specifications
# --gpumem
# --rammem
# --diskmem
# --evaluate_after
# --wall_time
# --not_nice

# 4. others for offline training (see main.py) for online (see run_script.py)

#--------------------------- COLLECT DATASET

# Collect data:
name="collect_esatv3"
script_args="--z_pos 1 -w esatv3 --random_seed 512  --owr -ds --number_of_runs 10 --no_training --evaluate_every -1 --final_evaluation_runs 0"
pytorch_args="--pause_simulator --online --alpha 1 --tensorboard --turn_speed 0.8 --speed 0.8"
dag_args="--number_of_recorders 12 --destination esatv3_expert --val_len 1 --test_len 1 --min_rgb 2400 --max_rgb 2600"
condor_args="--wall_time_rec $((10*10*60+3600)) --rammem 6"
python dag_create_data.py -t $name $script_args $pytorch_args $dag_args $condor_args


#---------------------------------------------- DATA NORMALIZATION
#####################
# seeds
name="alex_net_seeds"
pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss CrossEntropy --optimizer SGD --clip 1 --weight_decay 0"
dag_args="--number_of_models 3"
condor_args="--wall_time_train $((67200)) --rammem 7 --gpumem 1800 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

# compare results
python combine_results.py --tags train_accuracy validation_accuracy --mother_dir alex_net_seeds --subsample 5 --blog_destination 19-04/19-04-06_seeds
# create fixed scratch checkpoint
python ../pilot/main.py --network alex_net --log_tag alex_net_scratch --create_scratch_checkpoint --discrete 

#####################
# learning rates
for LR in 1 01 001 0001 ; do
  name="alex_net_learningrates/$LR"
  pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path alex_net_scratch \
   --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.$LR --loss CrossEntropy --optimizer SGD --clip 1 --weight_decay 0"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((67200)) --rammem 7 --gpumem 1800 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
# compare results
python combine_results.py --tags train_accuracy validation_accuracy --mother_dir alex_net_learningrates --legend_names 0.0001 0.001 0.01 0.1 --subsample 5 --blog_destination 19-04/19-04-06_learningrates

#####################
# data normalization 
name="data_normalization/reference"
pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path alex_net_scratch \
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss CrossEntropy --optimizer SGD --clip 1 --weight_decay 0 --skew_input" 
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

name="data_normalization/shifted_input"
pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path alex_net_scratch \
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss CrossEntropy --optimizer SGD --clip 1 --weight_decay 0 --shifted_input"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  
name="data_normalization/scaled_input"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

name="data_normalization/normalized_output"
pytorch_args="--network alex_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path alex_net_scratch \
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss CrossEntropy --optimizer SGD --clip 1 --weight_decay 0 --normalized_output"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((5*200*60+3600*2)) -gpumem 1900 --rammem 7 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

python combine_results.py --tags train_accuracy validation_accuracy --subsample 5 --blog_destination 19-04/19-04-06_datanormalization --mother_dir data_normalization --legend_names normalized_output reference shifted_input scaled_input

#---------------------------------------------- VGG16 OPTIMIZERS PRETRAINED
# create fixed scratch checkpoint
python ../pilot/main.py --network vgg16_net --log_tag vgg16_net_scratch --create_scratch_checkpoint --discrete 
for LR in 1 001 00001 ; do
  for OP in SGD Adadelta Adam ; do 
    name="vgg16_net/$OP/$LR"
    pytorch_args="--network vgg16_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1 --checkpoint_path vgg16_net_scratch\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer $OP --weight_decay 0"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 7 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
for OP in SGD Adadelta Adam ; do 
  python combine_results.py --tags train_accuracy validation_accuracy --mother_dir vgg16_net/$OP --subsample 5 --blog_destination 19-04/19-04-06_vgg16_net_$OP
done
for LR in 1 001 00001 ; do
  for OP in SGD Adadelta Adam ; do 
    name="vgg16_net_pretrained/$OP/$LR"
    pytorch_args="--network vgg16_net --pretrained --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1 --checkpoint_path vgg16_net_scratch\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer $OP --weight_decay 0"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 7 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
for OP in SGD Adadelta Adam ; do 
  python combine_results.py --tags train_accuracy validation_accuracy --mother_dir vgg16_net_pretrained/$OP --subsample 5 --blog_destination 19-04/19-04-06_vgg16_net_$OP
done


#---------------------------------------------- POPULAR ARCHITECTURES
###### Finetune
# models with 6G GPU RAM
for AR in inception_net dense_net vgg16_net squeeze_net ; do
  for LR in 1 01 001; do
    name="${AR}_finetune/$LR"
    pytorch_args="--network ${AR} --pretrained --feature_extract --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1.\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --weight_decay 0"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
# models requiring 2G GPU RAM
for AR in res18_net alex_net ; do
  for LR in 1 01 001; do
    name="${AR}_finetune/$LR"
    pytorch_args="--network ${AR} --pretrained --feature_extract --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1.\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --weight_decay 0"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*4*60+2*3600)) --rammem 6 --gpumem 1900 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
for AR in inception_net dense_net squeeze_net res18_net alex_net vgg16_net; do 
  python combine_results.py --tags train_accuracy validation_accuracy --mother_dir ${AR}_finetune --subsample 5 --legend_names 0.001 0.01 0.1 --blog_destination 19-04/19-04-06_${AR}_finetune
done

###### End-to-end
# models with 6G GPU RAM
for AR in inception_net dense_net vgg16_net squeeze_net ; do
  for LR in 1 01 001; do
    name="${AR}_end-to-end/$LR"
    pytorch_args="--network ${AR} --pretrained --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1.\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --weight_decay 0"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*5*60+2*3600)) --rammem 6 --gpumem 6000 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
# models requiring 2G GPU RAM
for AR in res18_net alex_net ; do
  for LR in 1 01 001; do
    name="${AR}_end-to-end/$LR"
    pytorch_args="--network ${AR} --pretrained --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1.\
    --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.$LR --loss CrossEntropy --shifted_input --optimizer SGD --weight_decay 0"
    dag_args="--number_of_models 1"
    condor_args="--wall_time_train $((100*4*60+2*3600)) --rammem 6 --gpumem 1900 --copy_dataset"
    python dag_train.py -t $name $pytorch_args $dag_args $condor_args
  done
done
# Tinyv3 Discrete CE
python ../pilot/main.py --network tinyv3_net --log_tag tinyv3_net_scratch --create_scratch_checkpoint --discrete 
for LR in 1 01 001; do
  name="tinyv3_end-to-end/$LR"
  pytorch_args=" --network tinyv3_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --clip 1 --checkpoint_path tinyv3_net_scratch --continue_training\
   --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.$LR --loss CrossEntropy --shifted_input  --optimizer SGD --weight_decay 0"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((67200)) --rammem 7 --gpumem 800 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

for AR in inception_net dense_net squeeze_net res18_net alex_net vgg16_net tinyv3_net ; do 
  python combine_results.py --tags train_accuracy validation_accuracy --mother_dir ${AR}_end-to-end --subsample 5 --legend_names 0.001 0.01 0.1 --blog_destination 19-04/19-04-06_${AR}_end-to-end
done


#---------------------------------------------- CONTINUOUS ACTION SPACE
# Tinyv3 Discrete CE
name="discrete_continuous/tinyv3_CE"
pytorch_args="--network tinyv3_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path tinyv3_net_scratch --continue_training\
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss CrossEntropy --optimizer SGD --shifted_input --weight_decay 0"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((67200)) --rammem 7 --gpumem 800 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

# Tinyv3 Discrete MSE
name="discrete_continuous/tinyv3_MSE"
pytorch_args="--network tinyv3_net --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path tinyv3_net_scratch --continue_training\
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss MSE --optimizer SGD --shifted_input --weight_decay 0"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((67200)) --rammem 7 --gpumem 800 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

# Tinyv3 Continuous MSE
name="discrete_continuous/tinyv3_continuous"
pytorch_args="--network tinyv3_net --dataset esatv3_expert_200K --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --checkpoint_path tinyv3_net_continuous_scratch --continue_training\
 --tensorboard --max_episodes 10000 --batch_size 100 --learning_rate 0.1 --loss MSE --optimizer SGD --shifted_input --weight_decay 0"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((67200)) --rammem 7 --gpumem 800 --copy_dataset"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

python combine_results.py --tags validation_accuracy --log_folders discrete_continuous/tinyv3_CE discrete_continuous/tinyv3_MSE --subsample 5 --legend_names tinyv3_CE tinyv3_MSE --blog_destination 19-04/19-04-06_CE_MSE
python combine_results.py --tags validation_imitation_learning --mother_dir discrete_continuous/tinyv3_MSE discrete_continuous/tinyv3_continuous --subsample 5 --legend_names  discrete continuous --blog_destination 19-04/19-04-06_discrete_continuous


#---------------------------------------------- INCREASE INPUT SPACE

for AR in tinyv3_net tinyv3_3d_net tinyv3_nfc_net ; do
  name="input_space/${AR}"
  pytorch_args="--network $AR --n_frames 3 --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
   --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --shifted_input --optimizer SGD --loss MSE --weight_decay 0 --clip 1"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
python combine_results.py --tags validation_accuracy --mother_dir input_space --subsample 5 --legend_names tiny tiny_concat tiny_siamese --blog_destination 19-04/19-04-06_input


for NF in 1 2 3 5 8 16 ; do
  name="number_of_frames/$NF"
  pytorch_args="--network tinyv3_3d_net --n_frames $NF --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
   --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --shifted_input --optimizer SGD --loss MSE --weight_decay 0 --clip 1"
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done
python combine_results.py --tags validation_accuracy --mother_dir number_of_frames --subsample 5 --blog_destination 19-04/19-04-06_input_nframes

#---------------------------------------------- LSTM's
python ../pilot/main.py --network tinyv3_3d_net --log_tag tinyv3_3d_net_2_scratch --create_scratch_checkpoint --discrete --n_frames 2

name="LSTM/ref_3D"
pytorch_args="--network tinyv3_3d_net --n_frames 2 --checkpoint_path tinyv3_3d_net_2_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
 --tensorboard --max_episodes 30000 --batch_size 5 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --clip 1"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((30*3600)) --rammem 7 --gpumem 1900"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

python ../pilot/main.py --network tiny_3d_LSTM_net --log_tag tiny_3d_LSTM_net_scratch --create_scratch_checkpoint --discrete --n_frames 2

name="LSTM/FBPTT"
pytorch_args="--network tiny_3d_LSTM_net --n_frames 2 --checkpoint_path tiny_3d_LSTM_net_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
--tensorboard --max_episodes 30000 --batch_size 5 --learning_rate 0.$LR --loss MSE --shifted_input --optimizer SGD --clip 1 --time_length -1 --subsample 10 --load_data_in_ram"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((30*3600)) --rammem 7 --gpumem 1900"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

name="LSTM/SBPTT"
pytorch_args="--network tiny_3d_LSTM_net --n_frames 2 --checkpoint_path tiny_3d_LSTM_net_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
--tensorboard --max_episodes 30000 --batch_size 5 --learning_rate 0.$LR --loss MSE --shifted_input --optimizer SGD --clip 1 --time_length 20 --subsample 10 --load_data_in_ram --sliding_tbptt"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((30*3600)) --rammem 7 --gpumem 1900"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

name="LSTM/WBPTT"
pytorch_args="--network tiny_3d_LSTM_net --n_frames 2 --checkpoint_path tiny_3d_LSTM_net_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
--tensorboard --max_episodes 30000 --batch_size 5 --learning_rate 0.$LR --loss MSE --shifted_input --optimizer SGD --clip 1 --time_length 20 --subsample 10 --load_data_in_ram"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((30*3600)) --rammem 7 --gpumem 1900"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

name="LSTM/WBPTT_no_init"
pytorch_args="--network tiny_3d_LSTM_net --n_frames 2 --checkpoint_path tiny_3d_LSTM_net_scratch --dataset esatv3_expert_200K --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
 --tensorboard --max_episodes 30000 --batch_size 5 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --time_length 20 --subsample 10 --load_data_in_ram --only_init_state"
dag_args="--number_of_models 1"
condor_args="--wall_time_train $((30*3600)) --rammem 7 --gpumem 1900"
python dag_train.py -t $name $pytorch_args $dag_args $condor_args

python combine_results.py --tags validation_accuracy train_accuracy --mother_dir LSTM --subsample 5 --blog_destination 19-04/19-04-06_LSTM

#---------------------------------------------- Data dependency
for DS in 200K 100K 50K 20K 10K 5K 1K; do 
  name="datadependency/esatv3_expert_${DS}"
  pytorch_args="--network tinyv3_3d_net --n_frames 2 --checkpoint_path tinyv3_3d_net_2_scratch  --dataset esatv3_expert_$DS --discrete --turn_speed 0.8 --speed 0.8 --action_bound 0.9\
  --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 "
  dag_args="--number_of_models 1"
  condor_args="--wall_time_train $((100*2*60+2*3600)) --rammem 6 --gpumem 900 --copy_dataset"
  python dag_train.py -t $name $pytorch_args $dag_args $condor_args
done

python combine_results.py --tags validation_accuracy train_accuracy --mother_dir datadependency --subsample 5 --blog_destination 19-04/19-04-06_datadependency


# --------------------------- DAG EVALUATE ONLINE

condor_args="--wall_time $((2*60*60)) --gpumem 1900 --rammem 7 --cpus 13"
script_args="--z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation"
dag_args="--number_of_models 2"
  
##AlexNet_Scratch_Reference
name="online_NA_evaluation/AlexNet_Scratch_Reference"
model='log_neural_architectures/alex_net_255input/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##AlexNet_Scratch_Shifted Input
name="online_NA_evaluation/AlexNet_Scratch_Shifted Input"
model='log_neural_architectures/alex_net/esatv3_expert_200K/shifted_input/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

#AlexNet_Scratch_Output_Normalization
name="online_NA_evaluation/AlexNet_Scratch_Output_Normalization"
model='log_neural_architectures/alex_net/esatv3_expert_200K/normalized_output/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

#_________________________________________________________________________________

script_args="--z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation"
dag_args="--number_of_models 2"

##AlexNet_Pretrained
name="online_NA_evaluation/AlexNet_Pretrained"
model='log_neural_architectures/alex_net_pretrained/esatv3_expert_200K/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
condor_args="--wall_time $((2*60*60)) --gpumem 1900 --rammem 7 --cpus 13"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##VGG16_Pretrained
name="online_NA_evaluation/VGG16_Pretrained"
model='log_neural_architectures/vgg16_net_pretrained/esatv3_expert_200K/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
condor_args="--wall_time $((2*60*60)) --gpumem 6000 --rammem 7 --cpus 13"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##InceptionNet_Pretrained
name="online_NA_evaluation/InceptionNet_Pretrained"
model='log_neural_architectures/inception_net_pretrained/esatv3_expert_200K/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
condor_args="--wall_time $((2*60*60)) --gpumem 6000 --rammem 7 --cpus 13"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##Res18_Pretrained
name="online_NA_evaluation/Res18_Pretrained"
model='log_neural_architectures/res18_net_pretrained/esatv3_expert_200K/01/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
condor_args="--wall_time $((2*60*60)) --gpumem 1900 --rammem 7 --cpus 13"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##DenseNet_Pretrained
name="online_NA_evaluation/DenseNet_Pretrained"
model='log_neural_architectures/dense_net_pretrained/esatv3_expert_200K/01/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
condor_args="--wall_time $((2*60*60)) --gpumem 6000 --rammem 7 --cpus 13"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##SqueezeNet_Pretrained
name="online_NA_evaluation/SqueezeNet_Pretrained"
model='log_neural_architectures/squeeze_net_pretrained/esatv3_expert_200K/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
condor_args="--wall_time $((2*60*60)) --gpumem 6000 --rammem 7 --cpus 13"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args


#_________________________________________________________________________________
script_args="--z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation"
dag_args="--number_of_models 2"
condor_args="--wall_time $((2*60*60)) --gpumem 800 --rammem 7 --cpus 13"

##TinyNet_Discrete_CE
name="online_NA_evaluation/TinyNet_Discrete_CE"
model='log_neural_architectures/discrete_continuous/tinyv3_CE/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##TinyNet_Discrete_MSE
name="online_NA_evaluation/TinyNet_Discrete_MSE"
model='log_neural_architectures/discrete_continuous/tinyv3_MSE/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##TinyNet_Continuous
name="online_NA_evaluation/TinyNet_Continuous"
model='log_neural_architectures/discrete_continuous/tinyv3_continuous/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

# _________________________________________________________________________________
script_args="--z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation"
dag_args="--number_of_models 2"
condor_args="--wall_time $((2*60*60)) --gpumem 900 --rammem 7 --cpus 13"

##TinyNet_Siamese
name="online_NA_evaluation/TinyNet_Siamese"
model='log_neural_architectures/tinyv3_nfc_net_3/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

##TinyNet_Concat_2
name="online_NA_evaluation/TinyNet_Concat_2"
model='tinyv3_3d_net_2/2/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

#TinyNet_LSTM_FBPTT
name="online_NA_evaluation/TinyNet_LSTM_FBPTT_2"
model='log_neural_architectures/tinyv3_3D_LSTM_net/fbptt/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

#TinyNet_LSTM_SBPTT
name="online_NA_evaluation/TinyNet_LSTM_SBPTT_2"
model='log_neural_architectures/tinyv3_3D_LSTM_net/sbptt/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

#TinyNet_LSTM_WBPTT
name="online_NA_evaluation/TinyNet_LSTM_WBPTT_2"
model='log_neural_architectures/tinyv3_3D_LSTM_net/wbptt/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args

# TinyNet_LSTM_WBPTT_init
name="online_NA_evaluation/TinyNet_LSTM_WBPTT_init"
model='log_neural_architectures/tinyv3_3D_LSTM_net/wbptt_init/1/seed_0'
pytorch_args="--online --tensorboard --checkpoint_path $model --load_config --continue_training"
python dag_evaluate.py -t $name $dag_args $condor_args $script_args $pytorch_args



