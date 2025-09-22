use std::path::PathBuf;
// CORRECTED: Use the modern 'aya_build' crate
use aya_build::BpfBuilder;

fn main() {
    let target_dir = PathBuf::from("../../target");
    let bpf_source = PathBuf::from("../bpf/exec_trace.c");

    let built_bpf = BpfBuilder::new()
        .source_file(&bpf_source)
        .target_dir(&target_dir)
        .build()
        .expect("Failed to build eBPF program");

    println!("cargo:rustc-env=EBPF_OBJECT_PATH={}", built_bpf.to_str().unwrap());
    println!("cargo:rerun-if-changed={}", bpf_source.to_str().unwrap());
}