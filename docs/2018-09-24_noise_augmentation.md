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



<img src="/imgs/18-09-24_example_images.png" alt="Example image of data with noise background" style="width: 2000px;"/>

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

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 88 (2) | 16.76 (8) | 6.41 (4) |
|all_factors_uni| 50 (15) | / | / |
|all_factors_ou_old| 60 (15) | / | / |
|all_factors_ou| 50 (20) | 19.5(10) | 8 (5) |

It is remarkable to note that some networks from the naive ensemble (not exactly an ensemble) are capable to fly successfully to the end of ESAT or the end of the corridor.

__static ensemble__

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 85 (5) | 17 (8) | 5 (2) |
|all_factors_uni| 73 (7) | 18.8 (7) | 7.8 (3) |
|all_factors_ou_old| 70 (10) | 23.6 (2) | 6.2 (2.6) |
|all_factors_ou| 77 (10) | 26.23 (5) | 6.12 (2.6) |



__dynamic ensemble with static ensemble pretrained__

|dataset| offline test accuracy | online esat | online corridor |
|-|-|-|-|
|all_factors| 60 (10) | 10.31 (6) | 6.29 (3.1) |
|all_factors_uni| 75 (5) | 13.89 (8) | 6.35 (3) |
|all_factors_ou_old| 68 (10) | 22.96 (4) | 7.30 (3) |
|all_factors_ou| 70 (10) | 28.41 (4) | 5.78 (3) |



## 6. Improvement: sample hyperparameters of OUNoise

Randomly sample the hyperparameters of the OUNoise. 
The pullback force, theta, is sampled from a beta distribution with alpha 2 and beta 2.
The deviation force, sigma, is sampled from a beta distribution with alpha 1 and beta 3.
