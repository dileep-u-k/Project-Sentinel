/*
 * ==============================================================================
 * Project Sentinel: Kernel Type Definitions (vmlinux.h)
 *
 * This file is NOT provided. It must be generated on your development machine.
 * It contains all type definitions for your specific Linux kernel version,
 * enabling the "Compile Once - Run Everywhere" (CO-RE) paradigm.
 *
 * HOW TO GENERATE THIS FILE:
 * 1. Ensure you have the 'bpftool' utility installed.
 * (e.g., on Debian/Ubuntu: sudo apt install linux-tools-common linux-tools-generic)
 * 2. Run the following command from the root of the project directory:
 *
 * bpftool btf dump file /sys/kernel/btf/vmlinux format c > src/bpf/vmlinux.h
 *
 * ==============================================================================
 */
// This file will be populated by the 'bpftool' command.