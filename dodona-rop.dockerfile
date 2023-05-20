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
        lxml==4.9.2 \
        py-emmet==1.2.0 \
        colour==0.1.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       gcc \
       g++ \
       libc6-dev \
       wget \
       gcc-multilib \
       file

USER runner
WORKDIR /home/runner/workdir
COPY main.sh /main.sh
