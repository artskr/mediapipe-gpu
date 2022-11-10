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

MAINTAINER <mediapipe@google.com>

COPY . /WET

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

RUN python3.8 -m pip install -e code/

RUN python3.8 -m pip install -U pip \
    && python3.8 -m pip install wheel \
    && python3.8 -m install --upgrade setuptools \
    && python3.8 -m install future \
    && python3.8 -m pip install --default-timeout=100 future

RUN python3.8 -m pip install -r code/requirementsDocker.txt --extra-index-url https://download.pytorch.org/whl/cu113
RUN python3.8 -m pip install git+https://github.com/elliottzheng/face-detection.git@master
RUN python3.8 -m pip uninstall -y opencv-python opencv-contrib-python

RUN chmod +x code/third_party_mp/setup_opencv.sh
RUN code/third_party_mp/setup_opencv.sh

# Install cudnn
ENV OS=ubuntu2004
ENV cudnn_version=8.0.5.39
ENV cuda_version=cuda11.1
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/${OS}/x86_64/cuda-${OS}.pin
RUN mv cuda-${OS}.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/${OS}/x86_64/7fa2af80.pub
RUN add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/${OS}/x86_64/ /"
RUN apt-get update
RUN apt-get install libcudnn8=${cudnn_version}-1+${cuda_version}
RUN apt-get install libcudnn8-dev=${cudnn_version}-1+${cuda_version}

# Install bazel
ARG BAZEL_VERSION=5.2.0
RUN mkdir /bazel && \
    wget --no-check-certificate -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    wget --no-check-certificate -O  /bazel/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh  && \
    rm -f /bazel/installer.sh

RUN ln -s /usr/bin/python3.8 /usr/bin/python

WORKDIR /WET/code/third_party_mp/mediapipe-gpu
RUN python setup.py install --link-opencv
WORKDIR /WET

RUN chmod +x data/download_example_data.sh
RUN data/download_example_data.sh


# Remove unnecessary apt files from the docker image
RUN (apt-get autoremove -y; \
    apt-get autoclean -y)

# Force Qt windows used by OpenCV to show properly
ENV QT_X11_NO_MITSHM=1
ENV TF_CUDA_PATHS=/usr/local/cuda-11.1,/usr/lib/x86_64-linux-gnu,/usr/include
ENV PATH=/usr/local/cuda-11.1/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64,/usr/local/cuda-11.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
RUN ldconfig
