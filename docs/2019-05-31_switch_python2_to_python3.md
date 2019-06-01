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

## FAILURE: TENSORFLOW NEEDS AVX

Tensorflow wheels available now are all installed with AVX requirements.
This means that tensorflow can only run on machines with 'has_avx' which are only the good ones, so we miss a lot of computation opportunity.
Solution is to have an adjusted compiled tensorflow version which do not require AVX, but this does require some ugly bazel building which I don't want to do.

I use tensorflow for writing summaries to tensorboard (not super necessary) and to load data multithreaded (super necessary but could also be written with multithread library).
If I translate my data reading code to run without tensorflow I do get rid of this badly maintain library which is a super gain.
However, this might be a bit harde to program than I think...

For now, switch for training offline back to python 2.7 and parse results in python 3.7.

In singularity tensorflow and python 2.7 are installed so they will never stop working, unless new 'multithreading' library becomes a requirement for which it has to be added to the singularity image.

