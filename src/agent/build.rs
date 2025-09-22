use std::process::Command;

fn main() {
    // This build script triggers the `cargo bpf build` command for our eBPF C code.
    // This ensures that the eBPF program is compiled before the agent itself.
    let status = Command::new("cargo")
        .args([
            "bpf",
            "build",
            "--manifest-path",
            "../bpf/Cargo.toml", // Path to the bpf crate
            "--target-dir",
            "../../target", // Output to the main target directory
        ])
        .status()
        .expect("failed to build eBPF program");

    assert!(status.success());
    println!("cargo:rerun-if-changed=../bpf");
}