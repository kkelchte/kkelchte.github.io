---
title: Noise Augmentation
layout: default
---


# This blog describes a data augmentation step by adding noise to the background

In a factorized control the network should solely focus on the relationship between the obstacle in the foreground and the annotated control. Just to be sure that the factor does not put attention on the background, the background is filled with noise.

The experiments are done with two types of noise:

1. Uniform noise over all three channels
2. OU Noise in x and y direction for each channel

The data is augmented for the following factors:



<img src="/imgs/18-09/18-09-24_example_images.png" alt="Example image of data with noise background" style="width: 2000px;"/>

## 1. Masking fore- and background

The gray background is selected for masking if the RGB value on the three channels are within a gray range [gray_min, gray_max].

This gray range can best be tweaked according to the data:

| dataset | min | max |
|---------|-----|-----|
|poster   | 150 | 200 |
| arc     | 177 | 179 |
|blocked_hole| 170 | 180 |


## 2. Combine foreground with uniform noise background

```
background = np.random.randint(0,255+1,size=img.shape)
inv_mask=np.abs(mask-1)
combined=np.multiply(mask,img)+np.multiply(inv_mask,background)
```

## 3. Create OUNoise background over X, Y, C and combine with foreground

OUNoise is extracted in 3 dimensions for the 3 channels.
A horizontal strip of noise over the columns is repeated over the rows for each channel.
A vertical strip of noise over the rows is repeated over the columns for each channel.
The horizontal and vertical noise images are combined and averaged.
After which they are combined as background with the foreground.

## 4. Demo script

```
for d in arc blocked_hole ceiling doorway radiator floor ; do for t in train_set.txt val_set.txt test_set.txt ; do python augment_data.py --mother_dir $d --txt_set $t; done; done
for d in poster ; do for t in train_set.txt val_set.txt test_set.txt ; do python augment_data.py --mother_dir poster --txt_set $t --gray_min 150 --gray_max 200; done; done
for d in arc ; do for t in train_set.txt val_set.txt test_set.txt ; do python augment_data.py --mother_dir poster --txt_set $t --gray_min 177 --gray_max 179; done; done

# for all_factors_uni and all_factors_ou
mkdir all_factors_uni
cp corridor/*.txt all_factors_uni
for d in arc blocked_hole ceiling doorway floor poster radiator ; do echo --$d; for t in train val test ; do echo $t; while read l ; do echo $l >> all_factors_uni/${t}_set.txt; done < ${d}_uni/${t}_set.txt; done; done

# use combined_corridor for test set
mv all_factors_uni/test_set.txt all_factors_uni/test_set.txt_all_factors
cp all_factors/test_set.txt all_factors_uni/

# test
python main.py --dataset all_factors_uni
```

## 5. Primal results

__naive ensemble__

In a first set of experiments we only train on the dataset with potentially noisy background.

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 88 (2) | 16.76 (8) | 6.41 (4) |
|all_factors_uni| 50 (30) | 24.42 (5.11) | 6.47 (3.37) |
|all_factors_ou| 50 (20) | 19.5(10) | 8 (5) |

Using noise in the backgroun seems to have a positive influence on the online performance and a very bad influence on the offline accuracy. 

It is remarkable to note that some networks from the naive ensemble (not exactly an ensemble) are capable to fly successfully to the end of ESAT or the end of the corridor while the offline test accuracy is very low.

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 88 (2) | 16.76 (8) | 6.41 (4) |
|all_factors_empty_uni| 72 (5) | 14.17 (9) | 5.4 (2.1) |
|all_factors_empty_uni_ou| 73 (10)| 21.8 (6.5) | 5.97 (2.6) |

In case we add uniform noise data and ou noise data to the initial dataset, the trend is less clear.
Because the no-noise data is also available during training the offline accuracy does not drop so strongly.
On the other hand, it is surprising that the online performance is in general worse in the online corridor although the variance is lower.
The negative influence on online performance on ESAT is hard to explain. 
It seems that by combining the two datasets, the generalization that is implied has a negative influence on generalizing to the ESAT environment. 
The OU Noise however seems to have a positive influence on the online performance in ESAT.

These numbers are taken from an average of 10 networks so should be reliable.

__static ensemble__

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 85 (5) | 17 (8) | 5 (2) |
|all_factors_uni| 73 (7) | 18.8 (7) | 7.8 (3) |
|all_factors_ou| 77 (10) | 26.23 (5) | 6.12 (2.6) |

The online performance in the corridor is best for network trained solely on the uniform background data.
The uniform noise seems to have a positive influence on making the ensemble of experts focus on the relevant features so they can detect them in the corridor.
The online performance in the ESAT corridor however is best for OU noise. The OU noise seems to have a positive generalization influence on the networks towards very new environments.

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 85 (5) | 17 (8) | 5 (2) |
|all_factors_empty_uni| 72 (15) | 20 (7) | 5.7(2.5) |
|all_factors_empty_uni_ou| 76 (4)| 22 (5) | 5.78 (2.9) |

Adding data with uniform noise background and ou noise background has a clear improvement on empty background.

It is however surprising that the empty background data is in general best left out when you look at the online performance in both ESAT and the online corridor.


__dynamic ensemble with static ensemble pretrained__

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 60 (10) | 10.31 (6) | 6.29 (3.1) |
|all_factors_uni| 75 (5) | 13.89 (8) | 6.35 (3) |
|all_factors_ou| 70 (10) | 28.41 (4) | 5.78 (3) |

The dynamic ensemble pretrained from the static has no an overall improvement over the static ensembles when looking at the online performance in the corridor.
Except for the online performance in ESAT that reaches a surprisingly high distance (although without real success)

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 60 (10) | 10.31 (6) | 6.29 (3.1) |
|all_factors_empty_uni| 74 (8) | 24 (1.4) | 7.78 (3.3) |
|all_factors_empty_uni_ou| 77 (6) | 24 (0)| 6.13 (2.8) |

Augmenting the data has a positive influence overall for the dynamic model as well, lowering the variance over the online results in ESAT.
The generalization with OU noise has a negative influence on the online performance in the corridor though.

__Conclusion__

Uniform noise background or OU noise background makes a static ensemble indeed focus more on the correct parts of the image resulting in a better online performance in the corridor.
Looking at the dynamic models, this trend is less clear. Having a dataset augmented with uniform background noise gives us the best results in the corridor.
Training the dynamic ensemble with OU background noise gives the best results in ESAT.


## 6. Improvement: sample hyperparameters of OUNoise

Randomly sample the hyperparameters of the OUNoise. 
The pullback force, theta, is sampled from a beta distribution with alpha 2 and beta 2.
The deviation force, sigma, is sampled from a beta distribution with alpha 1 and beta 3.


<img src="/imgs/18-09/18-09-24_example_ou.jpg" alt="Example image with ou noise" style="width: 500px;"/>

## 7. Next step:

The next would be to try this way of data augmentation out on a static dataset as for instance traffic sign recognition.
In this case it would be interesting to see how much of the training data we can make obsolete if we augment the training data by extracting the traffic sign and adding noise to the background. I'll have to ask Davy for a proper traffic sign benchmark.



