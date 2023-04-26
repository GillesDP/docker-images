FROM python:3.10.10-slim-bullseye

# Environment Kotlin
ENV SDKMAN_DIR /usr/local/sdkman
ENV PATH $SDKMAN_DIR/candidates/kotlin/current/bin:$PATH
ENV NODE_PATH /usr/lib/node_modules
# Add manual directory for default-jdk
RUN mkdir -p /usr/share/man/man1mkdir -p /usr/share/man/man1 \
 && apt-get update \
 # Install additional dependencies
 && apt-get install -y --no-install-recommends \
       procps=2:3.3.17-5 \
       dos2unix=7.4.1-1 \
       curl=7.74.0-1.3+deb11u7 \
       zip=3.0-12 \
       unzip=6.0-26+deb11u1 \
 && curl https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb --output packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && rm packages-microsoft-prod.deb \
 # Add nodejs v18
 && bash -c 'set -o pipefail && curl -fsSL https://deb.nodesource.com/setup_18.x | bash -' \
 # Install programming languages
 && apt-get install -y --no-install-recommends \
       # TESTed Java and Kotlin judge dependency
       openjdk-17-jdk=17.0.6+10-1~deb11u1 \
       checkstyle=8.36.1-1 \
       # TESTed Haskell judge dependency
       haskell-platform=2014.2.0.0.debian8 \
       hlint=3.1.6-1 \
       # TESTed C judge dependency
       gcc=4:10.2.1-1 \
       cppcheck=2.3-1 \
       # TESTed Javascript judge dependency
       nodejs \
       # TESTed bash judge dependency
       shellcheck=0.7.1-1+deb11u1 \
       # C# dependency
       dotnet-sdk-6.0=6.0.405-1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 # TESTed Judge depencencies
 && pip install --no-cache-dir --upgrade jsonschema==4.4.0 psutil==5.9.0 mako==1.1.6 pydantic==1.9.0 typing_inspect==0.7.1 pylint==2.6.0 lark==0.10.1 pyyaml==6.0 Pygments==2.11.2 python-i18n==0.3.9 \
 # TESTed Kotlin judge dependencies
 && bash -c 'set -o pipefail && curl -s "https://get.sdkman.io?rcupdate=false" | bash' \
 && chmod a+x "$SDKMAN_DIR/bin/sdkman-init.sh" \
 && bash -c "source \"$SDKMAN_DIR/bin/sdkman-init.sh\" && sdk install kotlin 1.6.10" \
 && curl -sSLO https://github.com/pinterest/ktlint/releases/download/0.43.2/ktlint \
 && chmod a+x ktlint \
 && mv ktlint /usr/local/bin \
 # JavaScript dependencies
 && npm install -g eslint@8.7 abstract-syntax-tree@2.17.6 \
 # Haskell dependencies
 && cabal update \
 && cabal v1-install --global aeson \
 # Make sure the students can't find our secret path, which is mounted in
 # /mnt with a secure random name.
 && chmod 711 /mnt \
 # Add the user which will run the student's code and the judge.
 && useradd -m runner \
 && mkdir /home/runner/workdir \
 && chown -R runner:runner /home/runner/workdir

# Install x86 (32 bit) libraries
RUN apt-get update && \
    apt-get install -y gcc-multilib

# Added for compiling and running Assembly (x86, x64, ARM, Aarch64)
RUN apt-get update && \
    apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu binutils-aarch64-linux-gnu-dbg && \
    apt-get install -y gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabihf binutils-arm-linux-gnueabihf-dbg && \
    apt-get install -y qemu-user qemu-user-static build-essential && \
    apt-get install -y valgrind
    
# Cross-compiling and installing Valgrind for Aarch64
RUN apt-get update && \
    apt-get install -y wget
RUN wget https://sourceware.org/pub/valgrind/valgrind-3.20.0.tar.bz2 && \
    tar -xf valgrind-3.20.0.tar.bz2
WORKDIR valgrind-3.20.0
RUN ./configure --host=aarch64-unknown-linux --target=aarch64-unknown-linux --prefix=/opt/valgrind-aarch64 CC=aarch64-linux-gnu-gcc LD=aarch64-linux-gnu-ld CFLAGS="-static" LDFLAGS="-static"
RUN make -j2
RUN make install
RUN mv /opt/valgrind-aarch64/libexec/valgrind/cachegrind-arm64-linux /opt/valgrind-aarch64/libexec/valgrind/cachegrind-arm64-linux-orig
WORKDIR /opt/valgrind-aarch64/libexec/valgrind
RUN touch cachegrind-arm64-linux
RUN echo '#!/bin/sh' >> cachegrind-arm64-linux
RUN echo 'qemu-aarch64 /opt/valgrind-aarch64/libexec/valgrind/cachegrind-arm64-linux-orig $@' >> cachegrind-arm64-linux
RUN chmod +x /opt/valgrind-aarch64/libexec/valgrind/cachegrind-arm64-linux

# Cross-compiling and installing Valgrind for arm32
WORKDIR /
RUN wget https://sourceware.org/pub/valgrind/valgrind-3.20.0.tar.bz2 && \
    tar -xf valgrind-3.20.0.tar.bz2
WORKDIR valgrind-3.20.0
RUN make distclean
RUN ./configure --host=armv7-linux-gnueabihf --target=armv7-linux-gnueabihf --prefix=/opt/valgrind-arm32 CC=arm-linux-gnueabihf-gcc LD=arm-linux-gnueabihf-ld CFLAGS="-fPIC" LDFLAGS="" CXXFLAGS="-fPIC"
RUN make -j2
RUN make install
RUN mv /opt/valgrind-arm32/libexec/valgrind/cachegrind-arm-linux /opt/valgrind-arm32/libexec/valgrind/cachegrind-arm-linux-orig
WORKDIR /opt/valgrind-arm32/libexec/valgrind
RUN touch cachegrind-arm-linux
RUN echo -e '#!/bin/sh\nqemu-arm /opt/valgrind-arm32/libexec/valgrind/cachegrind-arm-linux-orig $@' >> cachegrind-arm-linux
RUN chmod +x cachegrind-arm-linux

RUN apt-get remove -y binfmt-support
    
USER runner
WORKDIR /home/runner/workdir

COPY main.sh /main.sh
