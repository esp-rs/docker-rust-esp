# docker-rust-esp

Provides a `Dockerfile` defining a Rust build environment for the ESP32 and ESP8266. Builds [LLVM](https://github.com/MabezDev/llvm-project) and [Rust](https://github.com/MabezDev/rust-xtensa.git) with support for the Xtensa ISA.

Unfortunately, due to a combination of the compilation time, required RAM, and resulting size (12.3GB), this image is not available on [Docker Hub](https://hub.docker.com/).

## Usage

Ensure that [Docker](https://www.docker.com/) is installed on your system. It is recommended that 4GB or more of RAM is available to the container; too little memory can cause the build to fail.

To build the image:

```bash
$ git clone https://github.com/jessebraham/docker-rust-esp.git
$ cd docker-rust-esp/
$ docker build -t rust-esp .
```

Note that this process can be lengthy, potentially taking hours depending on your hardware. Please be patient.

Once the image has been built, from the root directory of your project (ie. that containing `Cargo.toml`), run:

```bash
$ docker run -v $PWD:/project rust-esp
```

This will build the application in release mode targeting the configured architecture.

Alternatively if you would prefer an interactive session:

```bash
$ docker run -v $PWD:/project -it rust-esp /bin/bash
```
