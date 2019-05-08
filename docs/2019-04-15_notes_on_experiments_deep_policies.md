---
title: Reproduce Results of Training Deep Policies
layout: default
---

# Training Deep Policy Experiments

## Evaluation of previous chapter on-policy

Conclusion: 
- use tinyv3
- use continuous action space
- possibly concatenate frames


## DAGGER

Increase dataset by visiting more relevant statespaces

Get model trained offline which still can improve (<5/10) and collect data relevant data while evaluating.
Show how a model with less data can actually improve significantly by allowing it to fly iteratively.

```bash
# Pretrain initial model @ pytorch_pilot/pilot
python main.py --network tinyv3_3d_net --n_frames 2 --checkpoint_path tinyv3_3d_net_2_continuous_scratch --dataset esatv3_expert_5K --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 --log_tag DAGGER/5K_concat --load_data_in_ram
# Train baseline model on 10K
python main.py --network tinyv3_3d_net --n_frames 2 --checkpoint_path DAGGER/5K_concat --dataset esatv3_expert_10K --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 20000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 --log_tag DAGGER/10K_concat --load_data_in_ram

# preparation of DAGGER loop
cp ${pilot_data}/esatv3_expert_5K/*.txt ${pilot_data}/DAGGER
i=0
cp -r ${tensorflow_log}/DAGGER/5K_concat ${tensorflow_log}/DAGGER/dagger_model

# While DAGGER-dataset.size < 10K ; do
#   Evaluate dagger model 1 time, 
python run_script.py -t DAGGER/test_iteration_${i} --z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 1 --evaluation -ds --online --tensorboard --checkpoint_path DAGGER/dagger_model --load_config --continue_training 
#   aggregate dataset to DAGGER-dataset 
echo ${pilot_data}/DAGGER/test_iteration_${i}/00000_esatv3 >> $(pilot_data)/DAGGER/train_set.txt
#   clean up frames without control info and mv supervised info to control info
#   and retrain model
python main.py --checkpoint_path DAGGER/dagger_model_${i-1} --dataset DAGGER --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 20000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --load_config --clip 1.0 --log_tag DAGGER/dagger_model --load_data_in_ram

```

## Recovery cameras

Create a dataset of 2 runs with recovery cameras, train scratch concat model, evaluate 10x in esatv3 on-policy.

```bash
# within singularity 
python ~/simsup_ws/src/simulation_supervised/simulation_supervised/python/run_script.py -t esatv3_recovery --owr --z_pos 1 -w esatv3 --random_seed 512  --owr -ds --number_of_runs 2 --no_training --recovery \
  --evaluate_every -1 --final_evaluation_runs 0 --python_project pytorch_pilot_beta/pilot --pause_simulator --online --alpha 1 --tensorboard --turn_speed 0.8 --speed 0.8

# cleanup dataset and copy validation and test set from esatv3_expert_5K
cp ${pilot_data}/esatv3_expert_5K/val_set.txt ${pilot_data}/esatv3_recovery
cp ${pilot_data}/esatv3_expert_5K/test_set.txt ${pilot_data}/esatv3_recovery
for d in ${pilot_data}/esatv3_recovery/00* ; do echo $PWD/$d >> ${pilot_data}/esatv3_recovery/train_set.txt; done

# Train @ pytorch_pilot/pilot
python main.py --network tinyv3_3d_net --n_frames 2 --checkpoint_path tinyv3_3d_net_2_continuous_scratch --dataset esatv3_recovery --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 --log_tag recovery/5K_concat --load_data_in_ram
python main.py --network tinyv3_net --checkpoint_path tinyv3_net_continuous_scratch --dataset esatv3_recovery --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 --log_tag recovery/5K --load_data_in_ram

# Evaluate in singularity @ pytorch_pilot/pilot
python dag_evaluate.py -t recovery/evaluate_5K_concat --number_of_models 2 --wall_time $((2*60*60)) --gpumem 900 --rammem 7 --cpus 13\
  --z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation --online --tensorboard --checkpoint_path recovery/5K_concat --load_config --continue_training
python dag_evaluate.py -t recovery/evaluate_5K --number_of_models 2 --wall_time $((2*60*60)) --gpumem 900 --rammem 7 --cpus 13\
  --z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation --online --tensorboard --checkpoint_path recovery/5K --load_config --continue_training

```


## Epsilon-greedy expert

Create epsilon-greedy dataset of 2 runs, train scratch models and evaluate.

```bash
# within singularity 
python ~/simsup_ws/src/simulation_supervised/simulation_supervised/python/run_script.py -t esatv3_epsilon --z_pos 1 -w esatv3 --random_seed 512 -ds --number_of_runs 2 --no_training \
  --evaluate_every -1 --final_evaluation_runs 0 --python_project pytorch_pilot_beta/pilot --online --alpha 1 --epsilon 0.1 --tensorboard --turn_speed 0.8 --speed 0.8

# cleanup dataset and copy validation and test set from esatv3_expert_5K
cp ${pilot_data}/esatv3_expert_5K/val_set.txt ${pilot_data}/esatv3_epsilon
cp ${pilot_data}/esatv3_expert_5K/test_set.txt ${pilot_data}/esatv3_epsilon
for d in ${pilot_data}/esatv3_epsilon/00* ; do echo $PWD/$d >> ${pilot_data}/esatv3_epsilon/train_set.txt; done

# Train @ pytorch_pilot/pilot
python main.py --network tinyv3_3d_net --n_frames 2 --checkpoint_path tinyv3_3d_net_2_continuous_scratch --dataset esatv3_epsilon --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 --log_tag epsilon/5K_concat --load_data_in_ram
python main.py --network tinyv3_net --checkpoint_path tinyv3_net_continuous_scratch --dataset esatv3_epsilon --turn_speed 0.8 --speed 0.8 --action_bound 0.9 --tensorboard --max_episodes 10000 --batch_size 32 --learning_rate 0.1 --loss MSE --shifted_input --optimizer SGD --continue_training --clip 1.0 --log_tag epsilon/5K --load_data_in_ram

# Evaluate in singularity @ pytorch_pilot/pilot
python dag_evaluate.py -t epsilon/evaluate_5K_concat --number_of_models 2 --wall_time $((2*60*60)) --gpumem 900 --rammem 7 --cpus 13\
  --z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation --online --tensorboard --checkpoint_path epsilon/5K_concat --load_config --continue_training
python dag_evaluate.py -t epsilon/evaluate_5K --number_of_models 2 --wall_time $((2*60*60)) --gpumem 900 --rammem 7 --cpus 13\
  --z_pos 1 -w esatv3 --random_seed 512 --number_of_runs 10 --evaluation --online --tensorboard --checkpoint_path epsilon/5K --load_config --continue_training


```


