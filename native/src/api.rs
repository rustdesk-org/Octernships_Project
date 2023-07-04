use anyhow::{anyhow, Result};
use std::io::Write;
use std::process::{Command, Stdio};
pub fn passing_complex_structs(password: String) -> Result<String> {
    let command_output = if cfg!(windows) {
        Command::new("cmd")
            .args(&["/C", "dir", "/root/"])
            .output()?
    } else {
        let mut child = Command::new("sudo")
            .args(&["-S", "ls", "-la", "/root/"])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()?;

        if let Some(child_stdin) = child.stdin.as_mut() {
            child_stdin.write_all(password.as_bytes())?;
        } else {
            return Err(anyhow!("Failed to open stdin for sudo command"));
        }

        let output = child.wait_with_output()?;
        output
    };

    let stdout = String::from_utf8_lossy(&command_output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&command_output.stderr).to_string();

    let result = format!("Standard Output:\n{}\nStandard Error:\n{}", stdout, stderr);
    Ok(result)
}
