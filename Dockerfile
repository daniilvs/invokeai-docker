FROM nvcr.io/nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04

# Install OS packages
ARG PYTHON_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \ 
    zlib1g-dev \ 
    libncurses5-dev \ 
    libgdbm-dev \ 
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    libsqlite3-dev \
    libbz2-dev \
    wget \
    git-core \
    unzip \
    zsh \
    poppler-utils \ 
    libgl1-mesa-glx \
    libglib2.0-0 \
    # python3-setuptools \
   
    # python${PYTHON_VERSION} \
    # # python${PYTHON_VERSION}-dev \
    # python${PYTHON_VERSION}-distutils \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/tmp/* /var/lib/apt/lists/*

RUN wget https://www.python.org/ftp/python/3.11.3/Python-3.11.3.tgz \
    tar -xf Python-3.11.3.tgz \
    ./configure --enable-optimizations \
    make -j 12 \
    sudo make install

# Set the default python version
RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1
    
# Install Nvidia Container Toolkit
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
   sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

WORKDIR /tmp

# Install pip
ARG PIP_VERSION
RUN wget https://github.com/pypa/pip/archive/refs/tags/${PIP_VERSION}.zip \
    && unzip ${PIP_VERSION}.zip \
    && cd pip-${PIP_VERSION} \
    && python setup.py install

# Install pytorch & torchvision
ARG CUDA_VERSION
ARG PYTORCH_VERSION
ARG TORCHVISION_VERSION
RUN --mount=type=cache,target=/root/.cache \
    pip install torch==${PYTORCH_VERSION}+${CUDA_VERSION} \
    torchvision==${TORCHVISION_VERSION}+${CUDA_VERSION} \
    -f https://download.pytorch.org/whl/${CUDA_VERSION}/torch_stable.html

WORKDIR /root

# Install invoke.ai
ARG INVOKE_AI_VERSION
RUN git clone https://github.com/invoke-ai/InvokeAI.git \
    && cd ./InvokeAI && git checkout ${INVOKE_AI_VERSION} \
    && pip install -r environments-and-requirements/requirements-base.txt

WORKDIR /root/InvokeAI

RUN cd scripts \
    && ln -s ../ldm ldm \
    && ln -s ../backend backend \
    && ln -s ../frontend frontend \
    && ln -s ../static scripts
    
#RUN pip install git+https://github.com/huggingface/transformers
#WORKDIR /root/InvokeAI/venv/scripts
#   
#RUN yes | pip uninstall tqdm \
#    && yes | pip install tqdm
    
WORKDIR /root/InvokeAI

RUN python scripts/configure_invokeai.py -y

COPY ./entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT sh /usr/bin/entrypoint.sh
