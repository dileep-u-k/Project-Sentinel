use std::path::PathBuf;
use aya_builder::BpfBuilder;

fn main() {
    let target_dir = PathBuf::from("../../target");
    let bpf_source = PathBuf::from("../bpf/exec_trace.c");

    // Build the eBPF program
    let built_bpf = BpfBuilder::new()
        .source_file(&bpf_source)
        .target_dir(&target_dir)
        .build()
        .expect("Failed to build eBPF program");

    // The include_bytes_aligned! macro needs the path to the compiled object file
    // relative to the build.rs script.
    // The aya-builder library helpfully provides the path for us.
    println!("cargo:rustc-env=EBPF_OBJECT_PATH={}", built_bpf.to_str().unwrap());
    println!("cargo:rerun-if-changed={}", bpf_source.to_str().unwrap());
}