use std::{process::Command, io::Write};

pub fn get_username() -> String {
    let process = Command::new("whoami").output().expect("failed to execute");
    let username = String::from_utf8(process.stdout)
        .expect("failed to convert to string")
        .trim()
        .to_string();

    return username;
}

pub fn print_home_folder(password : String) -> Option<String> {
    let mut command = Command::new("sudo")
        .args(["-k","-S", "ls", "-la", "/root/"])
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn()
        .expect("failed to execute command");

    let mut input = command.stdin.take().expect("failed to open stdin");
    std::thread::spawn(move || {input.write_all(password.as_bytes()).expect("failed to write to stdin")});

    let output = command
        .wait_with_output()
        .expect("failed to wait for child process");

    if output.status.code() == Some(0) {
        return Some(String::from_utf8(output.stdout).expect("failed to convert to string"));
    } else {
        return None;
    }
}
