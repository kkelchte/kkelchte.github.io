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

### Evaluate resutls of offline training:

Script can be found in jupyter 'Evaluate Gridsearch'.


**Check highest checkpoint**
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

>17 out of 100 or better 17% failed.
>badguys:
>set(['amethyst', 'vega', 'wasat', 'unuk', 'emerald'])
>goodguys:
>set(['triton', 'cancer', 'ymir', 'garnet', 'emerald', 'umbriel', >'proteus', 'realgar', 'quaoar', 'wasat', 'ruchba', 'malachite', 'virgo', 'libra', 'amethyst', 'ricotta', 'kunzite', 'diamond', 'nickeline', 'pollux', 'leo', 'rosalind', 'miranda', 'hematite', 'lesath', 'vladimir', 'opal', 'vega', 'vesta'])
>both good and bad: 
>set(['emerald', 'vega', 'amethyst', 'wasat'])
