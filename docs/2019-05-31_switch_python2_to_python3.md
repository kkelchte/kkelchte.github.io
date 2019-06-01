---
title: Switching from python 2.7 to python 3.7.3
layout: default
---

With the new fedora version, matplotlib < six < Tkinter fails to find package.
Transition of offline (singularity-free) code to python 3.

## Create env3 with installed dependencies

```
virtualenv -p python3 env3
pip install astor h5py html5lib ipaddress ipython Jinja2 jsonschema jupyter matplotlib numpy  Pillow  pyparsing PyYAML scikit-image scipy subprocess32 tablib tensorboard tensorflow  torch  torchvision
```

## adjust code in pilot_pytorch

```python
print abc 
print(abc)
```

Add models folder as package to python path to avoid issues with relative package references.
```
export PYTHONPATH=$PYTHONPATH:/PATH/TO/PILOT/MODELS
```

Change dict.keys() to list(dict.keys())

Change Error.message() to Error.args()

## Inspect interaction singularity (python 2.7) and pytorch (python 3.7)

python 2.7 is globally installed in singularity ==> only cuda and singularity libs are added to LD_LIBRARY_PATH:
```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/.singularity.d/libs/:/usr/local/cuda/lib64:/usr/local/cudnn/lib64
export TF_CPP_MIN_LOG_LEVEL=3
```
