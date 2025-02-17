FROM nvidia/cuda:11.4.2-cudnn8-runtime-ubuntu20.04

WORKDIR /var/ml

RUN apt-get update && \
    apt-get install -y git

RUN set -x && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        git \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        mercurial \
        openssh-client \
        procps \
        subversion \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && \
    UNAME_M="$(uname -m)" && \
    if [ "${UNAME_M}" = "x86_64" ]; then \
        ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh"; \
        SHA256SUM="2751ab3d678ff0277ae80f9e8a74f218cfc70fe9a9cdc7bb1c137d7e47e33d53"; \
    elif [ "${UNAME_M}" = "s390x" ]; then \
        ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-s390x.sh"; \
        SHA256SUM="a7d1a83279f439e7d8a6c53aa725552e195c0b96ae7e7fa63baefdf0118f7942"; \
    elif [ "${UNAME_M}" = "aarch64" ]; then \
        ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-aarch64.sh"; \
        SHA256SUM="3a3d5a61df5422f7c8c7816217b926ec7e200cc6d62967541adead8ec46d935d"; \
    elif [ "${UNAME_M}" = "ppc64le" ]; then \
        ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-ppc64le.sh"; \
        SHA256SUM="097064807a9adae3f91fc4c5852cd90df2b77fc96505929bb25bf558f1eef76f"; \
    fi && \
    wget "${ANACONDA_URL}" -O anaconda.sh -q && \
    echo "${SHA256SUM} anaconda.sh" > shasum && \
    sha256sum --check --status shasum && \
    /bin/bash anaconda.sh -b -p /opt/conda && \
    rm anaconda.sh shasum && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

COPY ./environment ./encoder4editing/environment

SHELL ["/bin/bash", "--login", "-c"]
RUN conda env create -f encoder4editing/environment/e4e_env.yaml

RUN conda init bash &&\
    conda activate e4e_env && \
    conda install jupyter -y --quiet

RUN apt-get -y update && \
    apt-get -y install build-essential && \
    apt-get -y update && \
    apt-get -y upgrade

RUN apt-get -y install g++ gcc

RUN DEBIAN_FRONTEND="noninteractive" TZ="Europe/London" apt-get install -y cmake protobuf-compiler

COPY . ./encoder4editing/

EXPOSE 8888

CMD /bin/bash --login -c "conda activate e4e_env && jupyter notebook --notebook-dir=/var/ml/encoder4editing/notebooks --ip='*' --port=8888 --no-browser --allow-root"