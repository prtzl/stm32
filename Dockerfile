FROM fedora:34

RUN dnf update -y && dnf install -y \
    git \
    wget \
    lbzip2 \
    make \
    cmake \
    glibc-locale-source \
    findutils \
    clang-tools-extra

RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 -O /tmp/gcc-arm-none-eabi-10.3.tar.bz2
RUN mkdir -p /opt/gcc-arm-none-eabi-10.3
RUN tar -xf /tmp/gcc-arm-none-eabi-10.3.tar.bz2 -C /opt/gcc-arm-none-eabi-10.3 --strip-components=1
RUN ln -s /opt/gcc-arm-none-eabi-10.3/bin/* /usr/local/bin
RUN rm -rf /tmp/*

ARG UID
ARG GID
ARG USERNAME
ARG GROUPNAME
RUN groupadd --gid $GID $GROUPNAME
RUN useradd --uid $UID --gid $GID $USERNAME
RUN usermod --append --groups $GROUPNAME $USERNAME
RUN usermod --shell /bin/bash $USERNAME

USER $USERNAME
