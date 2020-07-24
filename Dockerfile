FROM       ubuntu:latest
MAINTAINER Jesse Braham <jesse@beta7.io>


## Update apt's package cache and install all build dependencies. Clean up the
## package cache when we're finished.
##
## Setting DEBIAN_FRONTEND to noninteractive ensures that `apt-get` will never
## try to interact with us.
## https://manpages.ubuntu.com/manpages/xenial/man7/debconf.7.html
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    clang \
    cmake \
    curl \
    git \
    libssl-dev \
    llvm make \
    pkg-config \
    wget \
    zlib1g \
 && rm -rf /var/lib/apt/lists/*


## Install the most recent version of the nightly Rust toolchain using rustup.
## Use the minimal profile to keep the image size down as much as possible.
## https://rustup.rs/
ENV HOME /root

WORKDIR ${HOME}
RUN curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh \
 && chmod +x rustup.sh \
 && ./rustup.sh --default-toolchain nightly --profile minimal -y \ 
 && rm rustup.sh


## Check out the Xtensa fork of Rust. Build and install LLVM and Rust with
## support for the Xtensa target.
## https://github.com/MabezDev/xtensa-rust-quickstart#rust-xtensa
##
## When done, remove any documentation, build artifacts, or files/directories
## which are otherwise not required; this drastically reduces the size of the
## resulting image.
ENV BUILD_ROOT  ${HOME}/.xtensa
ENV RUST_XTENSA ${BUILD_ROOT}/rust-xtensa
ENV RUST_BUILD  ${RUST_XTENSA}/build

WORKDIR ${BUILD_ROOT}
RUN git clone https://github.com/MabezDev/rust-xtensa.git \
 && cd "${RUST_XTENSA}" \
 && git checkout fc20a1b835a1db5098cf4ac8dc54f2c59ac36d12 \
 && mkdir -p "${RUST_BUILD}" \
 && ./configure --experimental-targets="Xtensa" --prefix="${RUST_BUILD}" \
 && python x.py build \
 && python x.py install \
 && $HOME/.cargo/bin/rustup toolchain link xtensa "${RUST_BUILD}" \
 && find . -maxdepth 1 -not -name "." \
                       -not -name ".." \
                       -not -name "build" \
                       -not -name "src" \
                       -not -name "Cargo.lock" \
                       -exec rm -rv {} + \
 && cd "${RUST_BUILD}" \
 && rm -rf bootstrap cache tmp \
 && cd "${RUST_BUILD}/x86_64-unknown-linux-gnu" \
 && rm -rf compiler-doc crate-docs doc md-doc stage0* stage1*


## Set up the xtensa-esp32-elf & xtensa-lx106-elf toolchains. Set the PATH
## environment variable to include all relevant executable directories.
## https://github.com/MabezDev/xtensa-rust-quickstart#xtensa-esp32-elf-toolchain
ENV ESP32_TOOLS   ${BUILD_ROOT}/xtensa-esp32-elf
ENV ESP8266_TOOLS ${BUILD_ROOT}/xtensa-lx106-elf

WORKDIR ${BUILD_ROOT}
RUN wget https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_2_0-esp-2020r2-linux-amd64.tar.gz \
 && tar xzf xtensa-esp32-elf-gcc8_2_0-esp-2020r2-linux-amd64.tar.gz \
 && rm xtensa-esp32-elf-gcc8_2_0-esp-2020r2-linux-amd64.tar.gz \
 && wget https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz \
 && tar xzf xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz \
 && rm xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz

ENV PATH ${ESP32_TOOLS}/bin:${ESP8266_TOOLS}/bin:${HOME}/.cargo/bin:$PATH


## Set up Xargo to allow for cross-compilation.
## https://github.com/japaric/xargo
## https://github.com/MabezDev/xtensa-rust-quickstart#xargo-or-cargo-xbuild
RUN cargo install xargo

ENV RUSTC          ${RUST_BUILD}/bin/rustc
ENV XARGO_RUST_SRC ${RUST_XTENSA}/src


## By default, build the project located in /project. Additional parameters
## can be passed to `xargo build` during the invocation of this image.
WORKDIR /project
CMD ["xargo", "build", "--release"]
