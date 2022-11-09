# Copyright 2019 The MediaPipe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM nvidia/cudagl:11.1.1-devel-ubuntu20.04
#FROM nvidia/cuda:11.1.1-cudnn8-devel-ubuntu20.04
#FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
#FROM nvidia/cudagl:10.1-devel-ubuntu18.04
MAINTAINER <mediapipe@google.com>

WORKDIR /io
WORKDIR /mediapipe

ENV DEBIAN_FRONTEND=noninteractive

#RUN rm /etc/apt/sources.list.d/cuda.list
#RUN rm /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update


RUN apt-get install -y --no-install-recommends \
    build-essential \
    gcc-8 g++-8 \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    wget \
    unzip \
    python3-dev \
    python3-opencv \
    python3-pip \
    libopencv-core-dev \
    libopencv-highgui-dev \
    libopencv-imgproc-dev \
    libopencv-video-dev \
    libopencv-calib3d-dev \
    libopencv-features2d-dev \
    software-properties-common \
    python3-venv libprotobuf-dev protobuf-compiler cmake libgtk2.0-dev \
    mesa-common-dev libegl1-mesa-dev libgles2-mesa-dev mesa-utils \
    pkg-config libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev  && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && apt-get install -y openjdk-8-jdk && \
    apt-get install -y mesa-common-dev libegl1-mesa-dev libgles2-mesa-dev && \
    apt-get install -y mesa-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade setuptools
RUN pip3 install wheel
RUN pip3 install future
RUN pip3 install --default-timeout=100 future
RUN pip3 install gdown absl-py numpy opencv-contrib-python==4.3.0.38  protobuf==3.19.6
RUN pip3 install six==1.14.0
RUN pip3 install tensorflow==2.5.0
RUN pip3 install tf_slim

RUN ln -s /usr/bin/python3.8 /usr/bin/python

# Install bazel
ARG BAZEL_VERSION=5.2.0
RUN mkdir /bazel && \
    wget --no-check-certificate -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    wget --no-check-certificate -O  /bazel/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh  && \
    rm -f /bazel/installer.sh

COPY . /mediapipe/

# Install cudnn libraries (optional, not sure if speeds up)
#RUN dpkg -i utils/libcudnn8_8.0.5.39-1+cuda11.1_amd64.deb  && dpkg -i utils/libcudnn8-dev_8.0.5.39-1+cuda11.1_amd64.deb

# Build and install Mediapipe wheel
RUN python setup.py gen_protos && python setup.py bdist_wheel
RUN python -m pip install dist/*.whl

# If we want the docker image to contain the pre-built object_detection_offline_demo binary, do the following
# RUN bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/examples/desktop/demo:object_detection_tensorflow_demo
ENV TF_CUDA_PATHS=/usr/local/cuda-11.1,/usr/lib/x86_64-linux-gnu,/usr/include
