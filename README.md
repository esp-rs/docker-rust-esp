# docker-rust-esp

Provides a `Dockerfile` defining a Rust build environment for the ESP32 and ESP8266. Builds LLVM and Rust with support for the Xtensa ISA.

For more information on the Xtensa Rust toolchain, refer to the following repositories:  
https://github.com/MabezDev/rust-xtensa  
https://github.com/MabezDev/xtensa-rust-quickstart

## Building

Ensure that [Docker](https://www.docker.com/) is installed on your system. At least _4GB_ of RAM (_6GB_+ recommended) should be available to the container; too little memory can cause the build to fail. Note that this process can be lengthy, potentially taking hours depending on your hardware. Please be patient.

To build the image (tagging it with the name `rust-esp`):

```bash
$ git clone https://github.com/jessebraham/docker-rust-esp.git
$ cd docker-rust-esp/
$ docker build -t rust-esp .
```

## Usage

Once the image has been built, from the root directory of your project (ie. that containing `Cargo.toml`), run:

```bash
$ docker run -v $PWD:/project --rm rust-esp
```

This will build the application using `xargo` in `release` mode, targeting the architecture specified in your `.cargo/config` file.

https://github.com/japaric/xargo

Alternatively if you would prefer an interactive session:

```bash
$ docker run -v $PWD:/project -it --rm rust-esp /bin/bash
```
