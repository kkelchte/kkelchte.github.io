# Let's see what a gridsearch can do

Launch_condor file adjusts the walltime according the learning rate.

```
i=0
echo "i;LR;WD;DO" > /esat/qayd/kkelchte/docker_home/tensorflow/log/gridsearchtags
for LR in 0.5 0.1 0.01 0.001 ; do
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

### Evaluate results:

Script can be found in jupyter 'Evaluate Gridsearch'. Or in the log file:

```
$ tensorboard $(python -c 'for i in range(0,24): print "gridsearch_"+str(i)+" ",')
```

#### Influence of different hyperparams on offline training

**Dropout**

Dropout keep probability is decreased from 0.87 to 0.125 in 5 steps. This leads to slower convergence on the training imitation loss. The resulting loss is around the same for different values of dropout keep probability. No clear trends are visible.


**Weight decay**

It is hard to find a trend in the weight decay. At lr 0.5 a lower weight decay seems to improve on the imitation loss while at lr 0.1 the oposite seems true.

**Learning rate**

The learning rate varies over 0.5, 0.1, 0.01, 0.001. Decreasing the learning rate has a direct impact on the convergence speed. At a learning rate of 0.01 convergence can be expected after more or less 24h. At 0.001 this would result in 10 days.

The runs with lr 0.1 run 5 times longer than 0.5 resulint in 40k steps instead of 8. The convergence in the validation imitation loss varies stronger with a learning rate of 0.1 than with learning rate 0.5.

#### Influence of different hyperparams on online evaluation

Average flying distance over 20 flights:

![Average flying distance over 20 flights]({{ "/imgs/18-01-02-gridsearch_online.png" | absolute_url }})

Only few of the networks trained without crash actually performs well. Due to this low number of succes networks it seems unlikely that we can draw proper conclusions. 

A high **weight decay** seems to make it impossible to train a network that performs well online.

It is not super clear, but especially with a high learning rate, a **higher dropout keep probability**, in other words less severe regularization with dropout, tends to a better online performance. Though again this is arguable as the trend is different with a lower learning rate. But when we look at models that did learn something we see that this is possible with a dropout keep prob of 0.87, 0.75 and even 0.25 (73).

A very low learning rate and longer training might positively influence the learning stability. A similar effect might be visible with a larger batchsize but without the need for extreme long training. The models trained at 0.001 took around 3 to 4 days to train offline with batchsize 32. 

With a batchsize of 64 or 128, the amount of episodes should be 2 to 4 times less making the model converge hopefully in less than 1 day. The batchsize that fits on a 2g GPU with a mobilenet 0.25 network is 256. This will decrease the amount of episodes required for convergence and increase stability in case of higher learning rates. 

A higher learning rate is in general preferable as long as it does not lead to divergence of the performance.

|i|LR|BS|
|-|-|-|
|0|0.5|16|
|1|0.5|32|
|2|0.5|64|
|3|0.5|128|
|4|0.1|16|
|5|0.1|32|
|6|0.1|64|
|7|0.1|128|
|8|0.05|16|
|9|0.05|32|
|10|0.05|64|
|11|0.05|128|
|12|0.01|16|
|13|0.01|32|
|14|0.01|64|
|15|0.01|128|

Training with different batchsizes and learning rates gives the following tendency: the higher the learning rate the lower the validation loss (offline) but not necessarily the better the policy. The only policy capable of flying through the canyon was nr 5. The policy with the lowest validation loss was nr 2, though when testing online this policy couldn't successfully fly through any canyon.

This shows how the validation loss is not representative for the offline training which is problematic in the case of hyperparameter tuning. A new set of validation data should be created that covers the variance expected when flying online. 

![Variance in control in canyon-forest-sandbox dataset]({{ "/imgs/18-01-03-histograms_ctr_canyon_forest_sandbox.png" | absolute_url }})

Looking at the histograms, it seems that the forest has a better distributed control range, which might be easier to train in a regression setting.

A second question is whether the model with the lowest validation imitation loss is be capable of flying online through training/validation worlds. This I strongly doubt as the policy performed bad in 10 different canyons, not showing any intention to avoid collision.

Found a parameter set wrongly: gradient multiplier is 0.001 which makes the feature extracting weight change at a learning rate that is 1000 times smaller. This should not be when training and testing solely in the canyon.

Creating a new dataset with auxd network steering, but keeping the BA control labels. First run should not be used as it fails due to the delay after loading in the network on the GPU. The first 15 frames are also skipped both in data as in steering commands to avoid the influence of the start up delay. The canyon is the same canyon as used for online evaluation.

```
$ start_sing
$ source .entrypoint_graph
$ roscd simulation_supervised
$ ./scripts/create_data.sh -t can_for_san_val -w "canyon forest sandbox" -n 16 -r none -m auxd -p "--load_config True" 
$ cd $HOME/pilot_data
$ for f in canyon forest sandbox ; do \
echo $f; mv $f/val_set.txt $f/val_set_old.txt; \
for d in $(ls can_for_san_val | grep $f | grep 00) ; do \
echo "$PWD/can_for_san_val/$d">>$f/val_set.txt; \
done; done
```

**improvement**

A second gridsearch over learning rate and batch size has more success thanks to the selection of fast evaluation machines.
An overview of the results can be extracted with the following command:

```
$ echo "| model | average online delay | distance | host | "; echo "|-|-|-|-|"; for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ; do d=gridsearch_$i; echo "$d | $(cat $d/xterm* | tail -1 | cut -d '|' -f 2) | $(cat $d/xterm* | tail -1 | cut -d ',' -f 3 | cut -d ':' -f 2) | $(ls $d/*_eval | grep events | head -1 |cut -d '.' -f 5) "; done
```

| model | average online delay | distance | host | 
|-|-|-|-|
gridsearch_0 |  0.007  | 44.7536157472 | kunzite 
gridsearch_1 |  0.007  | 1.3887763962 | garnet 
gridsearch_2 |  0.008  | 1.67935892671 | hematite 
gridsearch_3 |  0.007  | 4.58545984111 | hematite 
gridsearch_4 |  0.007  | 44.7298443638 | garnet 
gridsearch_6 |  0.008  | 44.75238293 | amethyst 
gridsearch_8 |  0.009  | 44.7550088625 | amethyst 
gridsearch_9 |  0.007  | 44.7244905593 | garnet 
gridsearch_10 |  0.006  | 44.7543601293 | amethyst 
gridsearch_11 |  0.007  | 44.7549903748 | citrine 
gridsearch_15 |  0.007  | 44.7442175556 | citrine

It is clear from model 1, 2 and 3 that a high learning rate ( 0.5 ) in combination with a large batchsize ( >32 ) results in bad online performance. Unfortunately this is still not visible in the offline validation unfortunately. The use of the new set of validation data did not improve the representation of the validation loss for the online performance. 

Redoing 2 and 3 ended without any success in online performance which supports previous findings.

The graph shows that model 0 and model 6 saturate after 1h of offline training. Indicating that those two hyperparameters might be most interesting in time efficiency: ( LR:0.5 BS:16 ) or ( LR:0.1 BS:64)

![Offline validation]({{ "/imgs/18-01-05-gridsearch_offline_graph.png" | absolute_url }})
![Offline validation]({{ "/imgs/18-01-05-gridsearch_offline_legend.png" | absolute_url }})





### Failure cases on condor

Check on which machines this failed:
17 out of 100 or better 17% failed.

Added code that restarts disconnected jobs properly.

badguys:
>amethyst, vega, wasat, unuk, emerald

Main reason was the following: decide to leave those 5 machines in blacklist.

```'Job disconnected, attempting to reconnect
    Socket between submit and execute hosts closed unexpectedly
    Trying to reconnect to'
```

goodguys:

>triton, cancer, ymir, garnet, emerald, umbriel, proteus, realgar, quaoar, wasat, ruchba, malachite, virgo, libra, amethyst, ricotta, kunzite, diamond, nickeline, pollux, leo, rosalind, miranda, hematite, lesath, vladimir, opal, vega, vesta

both good and bad: 

>emerald, vega, amethyst, wasat
