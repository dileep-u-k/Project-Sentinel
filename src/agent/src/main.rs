use anyhow::Context;
use aya::{
    include_bytes_aligned,
    maps::RingBuf,
    programs::KProbe,
    Bpf,
};
use aya_log::BpfLogger;
use log::{info, warn, debug};
use sentinel_common::ExecEvent;
use tokio::signal;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize the logger for userspace output.
    env_logger::init();

    // Compile and load the eBPF program.
    // This will build the C code and load the resulting object file.
    #[cfg(debug_assertions)]
    let mut bpf = Bpf::load(include_bytes_aligned!(
        "../../target/bpfel-unknown-none/debug/exec-trace"
    ))?;
    #[cfg(not(debug_assertions))]
    let mut bpf = Bpf::load(include_bytes_aligned!(
        "../../target/bpfel-unknown-none/release/exec-trace"
    ))?;

    // Initialize the eBPF logger to stream logs from the BPF program.
    BpfLogger::init(&mut bpf).context("Failed to initialize eBPF logger")?;

    // Get a handle to the kprobe and attach it.
    let program: &mut KProbe = bpf.program_mut("x64_sys_execve").unwrap().try_into()?;
    program.load()?;
    program.attach("__x64_sys_execve", 0)
        .context("Failed to attach kprobe")?;
    
    info!("eBPF program attached to execve syscall. Waiting for events...");

    // Get a handle to the ring buffer.
    let mut ring_buf = RingBuf::from_map(bpf.map_mut("rb").unwrap())?;

    // Start a separate async task to listen for events.
    let event_handle = tokio::spawn(async move {
        loop {
            // Wait for an event from the ring buffer.
            if let Some(buf) = ring_buf.next() {
                // Try to parse the event from the raw bytes.
                match ExecEvent::try_from(&buf) {
                    Ok(event) => {
                        // Safely convert the byte arrays to strings, trimming null bytes.
                        let comm = String::from_utf8_lossy(&event.comm);
                        let filename = String::from_utf8_lossy(&event.filename);
                        
                        let trimmed_comm = comm.trim_end_matches('\0');
                        let trimmed_filename = filename.trim_end_matches('\0');

                        info!(
                            "PID: {:<6} | COMM: {:<15} | FILENAME: {}",
                            event.pid,
                            trimmed_comm,
                            trimmed_filename
                        );
                    }
                    Err(_) => {
                        warn!("Failed to parse event from ring buffer.");
                    }
                }
            }
        }
    });

    // Wait for a Ctrl+C signal to gracefully exit.
    info!("Press Ctrl+C to exit.");
    signal::ctrl_c().await?;
    info!("Exiting...");

    // Abort the event handling task.
    event_handle.abort();

    Ok(())
}