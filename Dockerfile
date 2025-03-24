FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

# Avoid timezone prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ca-certificates \
    build-essential \
    cmake \
    gcc \
    g++ \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-glx \
    python3.9 \
    python3.9-dev \
    python3.9-distutils \
    python3-pip \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    openssh-server \
    locales \
    sudo \
    unzip \
    coreutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
  
# Configure locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add Microsoft's GPG key and repository for VSCode
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
# Make Python 3.9 the default python
RUN ln -sf /usr/bin/python3.9 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.9 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Set up work directory
WORKDIR /app

# Clone the repository and initialize submodules
RUN git clone https://github.com/ais-lab/pl2map.git /app && \
    git submodule update --init --recursive

# Install PyTorch with CUDA 11.3 support
RUN pip install --no-cache-dir torch==1.12.0+cu113 torchvision==0.13.0+cu113 -f https://download.pytorch.org/whl/torch_stable.html

# Install project dependencies
RUN pip install --no-cache-dir \
    pathlib \
    open3d \
    omegaconf \
    h5py \
    scipy \
    matplotlib \
    tqdm \
    pyyaml \
    opencv-python \
    poselib \
    visdom \
    scikit-image \
    numpy==1.26.3 \
    gdown

# Install the third-party dependencies from submodules
RUN pip install --no-cache-dir -e ./third_party/pytlsd && \
    pip install --no-cache-dir -e ./third_party/DeepLSD

# Install VSCode
RUN apt-get update && apt-get install -y code && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for VSCode
RUN useradd -m -s /bin/bash -G sudo vscode && \
    echo "vscode:vscode" | chpasswd && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up VSCode extensions
USER vscode
RUN mkdir -p /home/vscode/.vscode-server/extensions

# Install popular Python extensions for VSCode
RUN code --install-extension ms-python.python \
    --install-extension ms-python.vscode-pylance \
    --install-extension ms-toolsai.jupyter \
    --install-extension ms-vscode.cmake-tools \
    --install-extension njpwerner.autodocstring \
    --install-extension kevinrose.vsc-python-indent \
    --install-extension donjayamanne.python-extension-pack \
    --install-extension visualstudioexptteam.vscodeintellicode || true
    
# Set environment variables for GPU support
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV PYTHONPATH "${PYTHONPATH}:/app"

# Switch back to the app directory
WORKDIR /app
RUN sudo chown -R vscode:vscode /app

# Prepare scripts for downloading
RUN chmod +x /app/prepare_scripts/*.sh
RUN /bin/bash -x /app/prepare_scripts/seven_scenes.sh || (echo "Script failed" && exit 2)
RUN /app/prepare_scripts/seven_scenes.sh
RUN /app/prepare_scripts/cambridge.sh
RUN /app/prepare_scripts/indoor6.sh
RUN /app/prepare_scripts/download_pre_trained_models.sh


# Default command to activate an interactive bash session
CMD ["/bin/bash"]