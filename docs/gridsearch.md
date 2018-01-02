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

A high weight decay seems to make a proper learning too hard. 

It is not super clear, but especially with a high learning rate, a higher dropout keep probability or so less severe regularization with dropout tends to a better online performance. Though again this is arguable as the trend is different with a lower learning rate.

A very low learning rate and longer training might positively influence the learning stability. A similar effect might be visible with a larger batchsize but without the need for extreme long training. The models trained at 0.001 took around 3 to 4 days to train offline with batchsize 32. 

With a batchsize of 64 or 128, the amount of episodes should be 2 to 4 times less making the model converge hopefully in less than 1 day. __TODO__ increase batchsize as big as possible while it fits on a 2g GPU. According to this relative increase the learning rate can be increased keeping stability at an equal level resulting in a faster convergence.


#### Check condor failure cases

**Check highest checkpoint in offline training**

```
gridsearch_0 : lr: 0.5 wd: 20e-05 do: 0.8 : 7900
gridsearch_1 : lr: 0.5 wd: 20e-05 do: 0.7 : 7900
gridsearch_2 : lr: 0.5 wd: 20e-05 do: 0. : 7900
gridsearch_3 : lr: 0.5 wd: 20e-05 do: 0.2 : 7900
gridsearch_4 : lr: 0.5 wd: 20e-05 do: 0.12 : 7900
------------------------
gridsearch_5 : lr: 0.5 wd: 10e-05 do: 0.8 : 7900
gridsearch_6 : lr: 0.5 wd: 10e-05 do: 0.7 : 7900
gridsearch_7 : lr: 0.5 wd: 10e-05 do: 0. : 7900
gridsearch_8 : lr: 0.5 wd: 10e-05 do: 0.2 : 7900
gridsearch_9 : lr: 0.5 wd: 10e-05 do: 0.12 : no checkpoint
------------------------
gridsearch_10 : lr: 0.5 wd: 4e-05 do: 0.8 : 7900
gridsearch_11 : lr: 0.5 wd: 4e-05 do: 0.7 : 7900
gridsearch_12 : lr: 0.5 wd: 4e-05 do: 0. : no checkpoint
gridsearch_13 : lr: 0.5 wd: 4e-05 do: 0.2 : 7900
gridsearch_14 : lr: 0.5 wd: 4e-05 do: 0.12 : no checkpoint
------------------------
gridsearch_15 : lr: 0.5 wd: 2e-05 do: 0.8 : 7900
gridsearch_16 : lr: 0.5 wd: 2e-05 do: 0.7 : 7900
gridsearch_17 : lr: 0.5 wd: 2e-05 do: 0. : 7900
gridsearch_18 : lr: 0.5 wd: 2e-05 do: 0.2 : 7900
gridsearch_19 : lr: 0.5 wd: 2e-05 do: 0.12 : 7900
------------------------
gridsearch_20 : lr: 0.5 wd: 1e-05 do: 0.8 : 7900
gridsearch_21 : lr: 0.5 wd: 1e-05 do: 0.7 : 7900
gridsearch_22 : lr: 0.5 wd: 1e-05 do: 0. : 7900
gridsearch_23 : lr: 0.5 wd: 1e-05 do: 0.2 : 7900
gridsearch_24 : lr: 0.5 wd: 1e-05 do: 0.12 : 7900
------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%
gridsearch_25 : lr: 0.1 wd: 20e-05 do: 0.8 : 39900
gridsearch_26 : lr: 0.1 wd: 20e-05 do: 0.7 : 39900
gridsearch_27 : lr: 0.1 wd: 20e-05 do: 0. : 39900
gridsearch_28 : lr: 0.1 wd: 20e-05 do: 0.2 : 39900
gridsearch_29 : lr: 0.1 wd: 20e-05 do: 0.12 : no checkpoint
------------------------
gridsearch_30 : lr: 0.1 wd: 10e-05 do: 0.8 : 8000
gridsearch_31 : lr: 0.1 wd: 10e-05 do: 0.7 : no checkpoint
gridsearch_32 : lr: 0.1 wd: 10e-05 do: 0. : no checkpoint
gridsearch_33 : lr: 0.1 wd: 10e-05 do: 0.2 : 39900
gridsearch_34 : lr: 0.1 wd: 10e-05 do: 0.12 : 39900
------------------------
gridsearch_35 : lr: 0.1 wd: 4e-05 do: 0.8 : 39900
gridsearch_36 : lr: 0.1 wd: 4e-05 do: 0.7 : 39900
gridsearch_37 : lr: 0.1 wd: 4e-05 do: 0. : no checkpoint
gridsearch_38 : lr: 0.1 wd: 4e-05 do: 0.2 : no checkpoint
gridsearch_39 : lr: 0.1 wd: 4e-05 do: 0.12 : no checkpoint
------------------------
gridsearch_40 : lr: 0.1 wd: 2e-05 do: 0.8 : 2000
gridsearch_41 : lr: 0.1 wd: 2e-05 do: 0.7 : 39900
gridsearch_42 : lr: 0.1 wd: 2e-05 do: 0. : 39900
gridsearch_43 : lr: 0.1 wd: 2e-05 do: 0.2 : 2000
gridsearch_44 : lr: 0.1 wd: 2e-05 do: 0.12 : 39900
------------------------
gridsearch_45 : lr: 0.1 wd: 1e-05 do: 0.8 : no checkpoint
gridsearch_46 : lr: 0.1 wd: 1e-05 do: 0.7 : 39900
gridsearch_47 : lr: 0.1 wd: 1e-05 do: 0. : 39900
gridsearch_48 : lr: 0.1 wd: 1e-05 do: 0.2 : no checkpoint
gridsearch_49 : lr: 0.1 wd: 1e-05 do: 0.12 : 39900
------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%
gridsearch_50 : lr: 0.01 wd: 20e-05 do: 0.8 : 92000
gridsearch_51 : lr: 0.01 wd: 20e-05 do: 0.7 : 92000
gridsearch_52 : lr: 0.01 wd: 20e-05 do: 0. : 8000
gridsearch_53 : lr: 0.01 wd: 20e-05 do: 0.2 : no checkpoint
gridsearch_54 : lr: 0.01 wd: 20e-05 do: 0.12 : 2000
------------------------
gridsearch_55 : lr: 0.01 wd: 10e-05 do: 0.8 : no checkpoint
gridsearch_56 : lr: 0.01 wd: 10e-05 do: 0.7 : 96000
gridsearch_57 : lr: 0.01 wd: 10e-05 do: 0. : 96000
gridsearch_58 : lr: 0.01 wd: 10e-05 do: 0.2 : no checkpoint
gridsearch_59 : lr: 0.01 wd: 10e-05 do: 0.12 : 96000
------------------------
gridsearch_60 : lr: 0.01 wd: 4e-05 do: 0.8 : no checkpoint
gridsearch_61 : lr: 0.01 wd: 4e-05 do: 0.7 : 94000
gridsearch_62 : lr: 0.01 wd: 4e-05 do: 0. : 98000
gridsearch_63 : lr: 0.01 wd: 4e-05 do: 0.2 : 98000
gridsearch_64 : lr: 0.01 wd: 4e-05 do: 0.12 : 98000
------------------------
gridsearch_65 : lr: 0.01 wd: 2e-05 do: 0.8 : 98000
gridsearch_66 : lr: 0.01 wd: 2e-05 do: 0.7 : 98000
gridsearch_67 : lr: 0.01 wd: 2e-05 do: 0. : 96000
gridsearch_68 : lr: 0.01 wd: 2e-05 do: 0.2 : 96000
gridsearch_69 : lr: 0.01 wd: 2e-05 do: 0.12 : 98000
------------------------
gridsearch_70 : lr: 0.01 wd: 1e-05 do: 0.8 : 98000
gridsearch_71 : lr: 0.01 wd: 1e-05 do: 0.7 : 94000
gridsearch_72 : lr: 0.01 wd: 1e-05 do: 0. : 98000
gridsearch_73 : lr: 0.01 wd: 1e-05 do: 0.2 : 96000
gridsearch_74 : lr: 0.01 wd: 1e-05 do: 0.12 : 96000
------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%
gridsearch_75 : lr: 0.001 wd: 20e-05 do: 0.8 : 8000
gridsearch_76 : lr: 0.001 wd: 20e-05 do: 0.7 : 98000
gridsearch_77 : lr: 0.001 wd: 20e-05 do: 0. : 6000
gridsearch_78 : lr: 0.001 wd: 20e-05 do: 0.2 : 96000
gridsearch_79 : lr: 0.001 wd: 20e-05 do: 0.12 : no checkpoint
------------------------
gridsearch_80 : lr: 0.001 wd: 10e-05 do: 0.8 : 94000
gridsearch_81 : lr: 0.001 wd: 10e-05 do: 0.7 : 982000
gridsearch_82 : lr: 0.001 wd: 10e-05 do: 0. : 984000
gridsearch_83 : lr: 0.001 wd: 10e-05 do: 0.2 : 984000
gridsearch_84 : lr: 0.001 wd: 10e-05 do: 0.12 : no checkpoint
------------------------
gridsearch_85 : lr: 0.001 wd: 4e-05 do: 0.8 : 2000
gridsearch_86 : lr: 0.001 wd: 4e-05 do: 0.7 : 8000
gridsearch_87 : lr: 0.001 wd: 4e-05 do: 0. : 960000
gridsearch_88 : lr: 0.001 wd: 4e-05 do: 0.2 : 990000
gridsearch_89 : lr: 0.001 wd: 4e-05 do: 0.12 : 992000
------------------------
gridsearch_90 : lr: 0.001 wd: 2e-05 do: 0.8 : 98000
gridsearch_91 : lr: 0.001 wd: 2e-05 do: 0.7 : 994000
gridsearch_92 : lr: 0.001 wd: 2e-05 do: 0. : 998000
gridsearch_93 : lr: 0.001 wd: 2e-05 do: 0.2 : 988000
gridsearch_94 : lr: 0.001 wd: 2e-05 do: 0.12 : 962000
------------------------
gridsearch_95 : lr: 0.001 wd: 1e-05 do: 0.8 : 976000
gridsearch_96 : lr: 0.001 wd: 1e-05 do: 0.7 : 972000
gridsearch_97 : lr: 0.001 wd: 1e-05 do: 0. : 950000
gridsearch_98 : lr: 0.001 wd: 1e-05 do: 0.2 : 956000
gridsearch_99 : lr: 0.001 wd: 1e-05 do: 0.12 : 980000
```

**Check on which machines this failed**

17 out of 100 or better 17% failed.

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
