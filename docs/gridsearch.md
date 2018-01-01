# Let's see what a gridsearch can do

Launch_condor file adjusts the walltime according the learning rate.

```
i=0
echo "i;LR;WD;DO" > /esat/qayd/kkelchte/docker_home/tensorflow/log/gridsearchtags
for LR in 0.5 0.1 0.01 0.001 0.0001 ; do
       for WD in 20 10 4 2 1 ; do
               for DO in 0.87 0.75 0.5 0.25 0.125 ; do
                       echo gridsearch_$i
                       echo "${i};$LR;${WD}e-05;$DO" >> /esat/qayd/kkelchte/docker_home/tensorflow/log/gridsearchtags
                       WT=$(python -c "print min(60*60*0.5/$LR,40000.0)")
                       ME=$(python -c "print int(80*(0.5/$LR))")
                      ./condor_task_offline.sh -t gridsearch_$i -q $WT -e true -n 20 -w "canyon" -p "--learning_rate $LR --max_episodes $ME --scratch True --dataset canyon --weight_decay ${WD}e-05  --random_seed 512 --dropout_keep_prob $DO"
                       i=$((i+1))
               done
       done
done
```
