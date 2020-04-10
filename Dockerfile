FROM ubuntu:latest


## Setting DEBIAN_FRONTEND to noninteractive ensures that apt-get will never
## try to interact with us.
## https://manpages.ubuntu.com/manpages/xenial/man7/debconf.7.html
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y clang curl llvm make pkg-config zlib1g


## Install all ESP-IDF dependencies.
## https://docs.espressif.com/projects/esp-idf/en/latest/get-started/linux-setup.html
RUN apt-get install -y git wget flex bison gperf python python-pip python-setuptools \
                       cmake ninja-build ccache libffi-dev libssl-dev


## Build LLVM for the xtensa target.
## https://github.com/MabezDev/xtensa-rust-quickstart#llvm-xtensa
ENV BUILD_ROOT $HOME/.xtensa
ENV LLVM_ROOT  ${BUILD_ROOT}/llvm-project/llvm
ENV LLVM_BUILD ${LLVM_ROOT}/build

RUN mkdir -p "${BUILD_ROOT}"
WORKDIR ${BUILD_ROOT}
RUN git clone https://github.com/MabezDev/llvm-project

ENV CC  clang
ENV CXX clang++

RUN mkdir -p "${LLVM_BUILD}"
WORKDIR ${LLVM_BUILD}
RUN cmake .. -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" -DCMAKE_BUILD_TYPE=Release -G "Ninja"
RUN cmake --build .


## Install the most recent version of Rust nightly using rustup.
## https://rustup.rs/
WORKDIR /
RUN curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh && \
	chmod +x ./rustup.sh && \
	./rustup.sh  --default-toolchain nightly --profile default -y && \ 
	rm rustup.sh


## Configure the Rust build to use our custom-built version of LLVM in order
## to support the xtensa target. Build and install the Rust compiler.
## https://github.com/MabezDev/xtensa-rust-quickstart#rust-xtensa
ENV RUST_XTENSA ${BUILD_ROOT}/rust-xtensa
ENV RUST_BUILD  ${RUST_XTENSA}/build

WORKDIR ${BUILD_ROOT}
RUN git clone https://github.com/MabezDev/rust-xtensa.git

WORKDIR ${RUST_XTENSA}
RUN mkdir -p "${RUST_BUILD}"
RUN ./configure --llvm-root="${LLVM_BUILD}" --prefix="${RUST_BUILD}"

RUN python x.py build
RUN python x.py install
RUN $HOME/.cargo/bin/rustup toolchain link xtensa ${RUST_BUILD}


## Setup the xtensa-esp32-elf & xtensa-lx106-elf toolchains.
## https://github.com/MabezDev/xtensa-rust-quickstart#xtensa-esp32-elf-toolchain
ENV ESP32_TOOLS   /xtensa-esp32-elf
ENV ESP8266_TOOLS /xtensa-lx106-elf

WORKDIR /

RUN wget https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz && \
	tar xzf xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz && \
	rm xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz
	
RUN wget https://dl.espressif.com/dl/xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
    tar xzf xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz && \
    rm xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz

ENV HOME /root
ENV PATH ${ESP32_TOOLS}/bin:/usr/local/bin:${ESP8266_TOOLS}/bin:${HOME}/.cargo/bin:$PATH


## Setup Xargo to allow for cross-compilation.
## https://github.com/japaric/xargo
## https://github.com/MabezDev/xtensa-rust-quickstart#xargo-or-cargo-xbuild
RUN cargo install xargo
ENV XARGO_RUST_SRC ${RUST_XTENSA}/src
ENV RUSTC          ${RUST_BUILD}/bin/rustc


## By default, build the project located in /project.
WORKDIR /project
CMD [ "xargo", "build", "--release" ]
