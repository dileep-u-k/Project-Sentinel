#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

// Define a common structure for passing data from kernel to userspace.
// This must be mirrored in the Rust userspace code.
#define TASK_COMM_LEN 16
#define FILENAME_LEN 128

struct exec_event_t {
    __u32 pid;
    __u8 comm[TASK_COMM_LEN];
    __u8 filename[FILENAME_LEN];
};

// Define the ring buffer map for sending data to userspace.
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024); // 256 KB
} rb SEC(".maps");

// kprobe attached to the entry of the execve syscall.
SEC("kprobe/__x64_sys_execve")
int BPF_KPROBE(__x64_sys_execve, struct pt_regs *ctx) {
    // Get the Process ID and command name.
    __u64 id = bpf_get_current_pid_tgid();
    __u32 pid = id >> 32;

    // Reserve a spot in the ring buffer.
    struct exec_event_t *event;
    event = bpf_ringbuf_reserve(&rb, sizeof(*event), 0);
    if (!event) {
        return 0; // Not enough space in the buffer.
    }

    // Fill the event data.
    event->pid = pid;
    bpf_get_current_comm(&event->comm, sizeof(event->comm));

    // Get the filename argument from the syscall.
    // The filename is the first argument to execve, stored in PT_REGS_PARM1(ctx).
    const char __user *filename_ptr = (const char __user *)PT_REGS_PARM1(ctx);
    bpf_probe_read_user_str(&event->filename, sizeof(event->filename), filename_ptr);

    // Submit the event to the ring buffer.
    bpf_ringbuf_submit(event, 0);

    return 0;
}

// All eBPF programs must have a license.
char LICENSE[] SEC("license") = "GPL";