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



<img src="/imgs/18-09-24_data_images.png" alt="Example image of data with noise background" style="width: 2000px;"/>

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
for t in train_set.txt val_set.txt test_set.txt ; do python augment_data.py --mother_dir poster --txt_set $t --gray_min 150 --gray_max 200; done

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

