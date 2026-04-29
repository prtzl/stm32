FROM fedora:44

RUN dnf update -y && dnf install -y \
    git \
    wget \
    lbzip2 \
    make \
    cmake \
    glibc-locale-source \
    findutils \
    clang-tools-extra \
    arm-none-eabi-gcc-cs \
    arm-none-eabi-gcc-cs-c++ \
    arm-none-eabi-newlib \
    arm-none-eabi-binutils-cs

# Fedora has nice and fresh pacakges, but perhaps in companies or long term projects
# it might be important to stay on exactly the same version or even binaries.
# Leaving this here for future
# RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 -O /tmp/gcc-arm-none-eabi-10.3.tar.bz2
# RUN mkdir -p /opt/gcc-arm-none-eabi-10.3
# RUN tar -xf /tmp/gcc-arm-none-eabi-10.3.tar.bz2 -C /opt/gcc-arm-none-eabi-10.3 --strip-components=1
# RUN ln -s /opt/gcc-arm-none-eabi-10.3/bin/* /usr/local/bin
# RUN rm -rf /tmp/*

ARG UID
ARG GID
ARG USERNAME
ARG GROUPNAME
RUN groupadd --gid $GID $GROUPNAME || true
RUN useradd --uid $UID --gid $GID $USERNAME
RUN usermod --append --groups $GROUPNAME $USERNAME
RUN usermod --shell /bin/bash $USERNAME

USER $USERNAME
