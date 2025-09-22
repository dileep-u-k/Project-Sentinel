use std::process::Command;

fn main() {
    let status = Command::new("cargo")
        .args([
            "bpf",
            "build",
            "--manifest-path",
            "../bpf/Cargo.toml",
            "--target-dir",
            "../../target",
        ])
        .status()
        .expect("failed to build eBPF program");

    assert!(status.success());
    println!("cargo:rerun-if-changed=../bpf");
}