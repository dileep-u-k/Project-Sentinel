#![no_std] // This crate can be used in no_std environments if needed.

// This structure must EXACTLY mirror the C struct in `exec_trace.c`.
// `repr(C)` is crucial for ensuring memory layout compatibility.
#[repr(C)]
#[derive(Debug)]
pub struct ExecEvent {
    pub pid: u32,
    pub comm: [u8; 16],
    pub filename: [u8; 128],
}

// Implement a safe parsing function from a raw byte slice.
// This is a professional Rust pattern for handling data from eBPF.
impl ExecEvent {
    pub fn try_from(buf: &[u8]) -> Result<&Self, ()> {
        if buf.len() < core::mem::size_of::<Self>() {
            return Err(());
        }
        // Safety: We've checked the size, and repr(C) ensures layout.
        Ok(unsafe { &*(buf.as_ptr() as *const Self) })
    }
}