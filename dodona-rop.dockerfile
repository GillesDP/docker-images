FROM python:3.11.3-slim-bullseye

RUN apt-get update && \
    # install procps, otherwise pkill cannot be not found
    apt-get -y install --no-install-recommends \
        procps=2:3.3.17-5 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    chmod 711 /mnt && \
    useradd -m runner && \
    mkdir -p /home/runner/workdir && \
    chown -R runner:runner /home/runner && \
    chown -R runner:runner /mnt && \
    pip install --no-cache-dir --upgrade \
        beautifulsoup4==4.11.2 \
        lxml==4.9.2 \
        py-emmet==1.2.0 \
        colour==0.1.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       gcc \
       g++ \
       libc6-dev \
       wget \
       gcc-multilib
    
# Added for compiling and running Assembly (x86, x64, ARM, Aarch64)
#RUN apt-get update && \
#    apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu binutils-aarch64-linux-gnu-dbg && \
#    apt-get install -y gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabihf binutils-arm-linux-gnueabihf-dbg && \
#    apt-get install -y ninja-build bison flex libpixman-1-dev libglib2.0-dev pkg-config ninja-build build-essential

# Compile qemu-user
#RUN wget https://download.qemu.org/qemu-8.0.0.tar.xz && \
#    tar xvJf qemu-8.0.0.tar.xz
#WORKDIR qemu-8.0.0
#RUN ./configure --target-list=aarch64-linux-user,arm-linux-user
#RUN make -j2 && make install

USER runner
WORKDIR /home/runner/workdir
COPY main.sh /main.sh
