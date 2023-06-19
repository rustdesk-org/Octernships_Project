use std::os::raw::c_char;
use std::ffi::CStr;
use libc::{c_int, c_uchar};
use std::process::Command;
use std::io::{self, Write};

#[no_mangle]
pub extern "C" fn run_ls() -> c_int {
    let output = Command::new("sudo")
        .arg("ls")
        .arg("-la")
        .arg("/root/")
        .output()
        .expect("Failed to execute command");

    if output.status.success() {
        let stdout = output.stdout;
        io::stdout().write_all(&stdout).unwrap();
        stdout.len() as c_int
    } else {
        let stderr = output.stderr;
        io::stderr().write_all(&stderr).unwrap();
        stderr.len() as c_int
    }
}

#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_uchar) {
    unsafe {
        if !ptr.is_null() {
            libc::free(ptr as *mut libc::c_void);
        }
    }
}
