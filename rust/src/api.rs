use std::io::{self, Write};
use std::process::{Command, Stdio};
use rustyline::Editor;

fn main() {
    // Prompt the user for a password
    let mut editor = Editor::<()>::new();
    let password = editor
        .read_password(&format!("Enter your password: "))
        .expect("Failed to read password");

    let mut child = Command::new("sudo")
        .arg("-S")
        .arg("ls")
        .arg("-la")
        .arg("/root/")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to execute command");

    let stdin = child.stdin.as_mut().expect("Failed to open stdin");
    let stdout = child.stdout.as_mut().expect("Failed to open stdout");

    // Send password to sudo through standard input
    stdin.write_all(password.as_bytes()).expect("Failed to write to stdin");

    let mut output = Vec::new();
    stdout.read_to_end(&mut output).expect("Failed to read stdout");

    let output_string = String::from_utf8_lossy(&output);
    println!("Command executed successfully:\n{}", output_string);
}
