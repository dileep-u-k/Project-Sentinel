# ==============================================================================
# Project Sentinel: Makefile
#
# Description:
#   Provides a simple, unified interface for building and running the
#   eBPF program and the userspace agent.
#
# Targets:
#   build:       Builds both the eBPF program and the Rust agent.
#   build-bpf:   Builds only the eBPF C code using cargo-bpf.
#   build-agent: Builds only the Rust userspace agent.
#   run:         Builds and runs the agent (requires sudo/root).
#   clean:       Cleans all build artifacts.
# ==============================================================================

.PHONY: build build-bpf build-agent run clean

# Define the output directory for build artifacts
TARGET_DIR := ./target

# Default target
all: build

# Build both BPF program and the agent
build: build-bpf build-agent

# Build the eBPF program using cargo-bpf
# This is the modern, idiomatic way for Aya projects.
build-bpf:
	@echo "Building eBPF program..."
	cd src/bpf && cargo bpf build --target-dir ../../target

# Build the Rust userspace agent
build-agent:
	@echo "Building userspace agent..."
	cd src/agent && cargo build --target-dir ../../target

# Build and run the agent
# Requires root privileges to load eBPF programs.
run: build
	@echo "Running Sentinel Agent (requires sudo)..."
	sudo ./target/debug/sentinel-agent

# Clean all build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cargo clean --manifest-path src/agent/Cargo.toml
	cargo clean --manifest-path src/bpf/Cargo.toml
	rm -rf $(TARGET_DIR)