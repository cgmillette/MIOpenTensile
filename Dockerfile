FROM ubuntu:18.04

ARG PREFIX=/usr/local
ARG GPU_ARCH=";"
ARG MIOTENSILE_VER="default"

# Support multiarch
RUN dpkg --add-architecture i386

# Add rocm repository
RUN sh -c 'echo deb [arch=amd64 trusted=yes] http://repo.radeon.com/rocm/apt/.apt_3.7/ xenial main > /etc/apt/sources.list.d/rocm.list'

# Install dependencies
RUN apt-get update --fix-missing --allow-insecure-repositories && DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-unauthenticated \
    apt-utils \
    build-essential \
    cmake \
    curl \
    doxygen \
    g++ \
    gdb \
    git \
    hip-rocclr \
    lcov \
    libelf-dev \
    libncurses5-dev \
    libnuma-dev \
    libpthread-stubs0-dev \
    llvm-amdgpu \
    miopengemm \
    pkg-config \
    python \
    python3 \
    python-dev \
    python3-dev \
    python-pip \
    python3-pip \
    python3-distutils \
    python3-venv \
    software-properties-common \
    wget \
    rocm-dev \
    rocm-device-libs \
    rocm-opencl \
    rocm-opencl-dev \
    rocm-cmake \
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install cget
RUN pip3 install cget

# Build using hip-clang
RUN cget -p $PREFIX init --cxx /opt/rocm/llvm/bin/clang++ --std=c++14 -DAMDGPU_TARGETS=${GPU_ARCH}

# Install rocm-cmake
RUN cget -p $PREFIX install RadeonOpenCompute/rocm-cmake@master

# Install dependencies
RUN cget -p $PREFIX install pfultz2/rocm-recipes
ADD requirements.txt /requirements.txt
RUN CXXFLAGS='-isystem $PREFIX/include' cget -p $PREFIX install -f /requirements.txt

RUN export HIPCC_LINK_FLAGS_APPEND='-O3 -parallel-jobs=4'
RUN export HIPCC_COMPILE_FLAGS_APPEND='-O3 -Wno-format-nonliteral -parallel-jobs=4'
 
