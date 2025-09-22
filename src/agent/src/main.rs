use anyhow::Context;
use aya::{
    include_bytes_aligned,
    maps::RingBuf,
    programs::KProbe,
    Bpf,
};
use aya_log::BpfLogger;
use log::{info, warn};
use sentinel_common::ExecEvent;
use tokio::signal;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    env_logger::init();

    // The build script now provides the path to the object file via an env var.
    let mut bpf = Bpf::load(include_bytes_aligned!(env!("EBPF_OBJECT_PATH")))?;

    BpfLogger::init(&mut bpf).context("Failed to initialize eBPF logger")?;

    let program: &mut KProbe = bpf.program_mut("x64_sys_execve").unwrap().try_into()?;
    program.load()?;
    program.attach("__x64_sys_execve", 0)
        .context("Failed to attach kprobe")?;

    info!("eBPF program attached to execve syscall. Waiting for events...");

    let mut ring_buf = RingBuf::try_from(bpf.map_mut("rb")?)?;

    tokio::spawn(async move {
        loop {
            match ring_buf.read_async().await {
                Ok(record) => {
                    let event_ptr = record.buf.as_ptr() as *const ExecEvent;
                    let event = unsafe { &*event_ptr };
                    
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
                Err(e) => warn!("Failed to read from ring buffer: {}", e),
            }
        }
    });

    info!("Press Ctrl+C to exit.");
    signal::ctrl_c().await?;
    info!("Exiting...");

    Ok(())
}