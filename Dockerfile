# ==============================================================================
# Project Sentinel: Development Environment (V15 - Final Build)
#
# Description:
#   This Dockerfile builds the complete development environment from a stable
#   Ubuntu base. It is intended to be built via CI/CD on a reliable network.
# ==============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    libbpf-dev \
    linux-headers-generic \
    linux-tools-common \
    linux-tools-generic \
    llvm \
    curl \
    ca-certificates \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Use a config file for cargo's network settings
RUN mkdir -p /root/.cargo && \
    echo '[http]\ntimeout = 300' > /root/.cargo/config.toml

# Install Rust toolchain and cargo-bpf
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . "$HOME/.cargo/env" \
    && cargo install cargo-bpf

ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /app
CMD ["/bin/bash"]