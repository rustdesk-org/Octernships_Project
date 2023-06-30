use anyhow::Result;
use thiserror::Error;

use std::{
    io::Write,
    process::{Command, Stdio},
};

/// Errors that can occur when listing a directory.
#[derive(Error, Debug)]
pub enum DirectoryListingError {
    #[error("Authentication failed.")]
    FailedToAuthenticate,
    #[error("The directory was unable to be found.")]
    NoSuchDirectory,
    #[error("Inadequate permissions.")]
    PermissionDenied,
    #[error("An unknown error occured.")]
    Unknown,
}

/// Possible methods for privilege escalation.
#[derive(Copy, Clone)]
pub enum EscalationMethod {
    Polkit,
    Sudo,
    Su,
    None,
}

/// Gets the current user's username.
pub fn get_username() -> String {
    let output = Command::new("whoami")
        .output()
        .expect("failed to execute whoami");

    String::from_utf8(output.stdout).expect("failed to convert whoami output to string")
}

/// Gets the possible privilege escalation methods by checking for the existence of
/// `pkexec`, `sudo`, and `su`, in that order.
///
/// ## Returns:
/// - A `Vec<EscalationMethod>` containing the applicable escalation methods
pub fn determine_escalation_methods() -> Vec<EscalationMethod> {
    let mut results = Vec::new();

    let pkexec = Command::new("command")
        .args(["-v", "pkexec"])
        .stdout(Stdio::null())
        .status()
        .expect("failed to spawn command -v pkcheck");

    if Some(0) == pkexec.code() {
        // polkit exists
        results.push(EscalationMethod::Polkit);
    }

    let sudo = Command::new("command")
        .args(["-v", "sudo"])
        .stdout(Stdio::null())
        .status()
        .expect("failed to spawn command -v sudo");

    if Some(0) == sudo.code() {
        // sudo exists
        results.push(EscalationMethod::Sudo);
    }

    let su = Command::new("command")
        .args(["-v", "su"])
        .stdout(Stdio::null())
        .status()
        .expect("failed to spawn command -v su");

    if Some(0) == su.code() {
        // sudo exists
        results.push(EscalationMethod::Su);
    }

    if results.is_empty() {
        results.push(EscalationMethod::None);
    }

    results
}

/// Gets the contents of `/root` using the specified privilege escalation method.
///
/// ## Arguments:
/// - `method`: The privilege escalation method to use
/// - `username`: The username to use for `su` (if applicable)
/// - `password`: The password to use for `sudo` or `su` (if applicable)
///
/// ## Returns:
/// - An `Ok<String>` if `ls` has a 0 exit code
/// - An `Err<DirectoryListingError>` otherwise
///
/// The error returned is one of the following:
/// - `DirectoryListingError::FailedToAuthenticate` if `sudo` or `su` exits with 1, or `pkexec` exits with 126 or 127
/// - `DirectoryListingError::NoSuchDirectory` if `ls` exits with 2 and the error message contains "No such file or directory"
/// - `DirectoryListingError::PermissionDenied` if `ls` exits with 2 and the error message contains "Permission denied"
/// - `DirectoryListingError::Unknown` otherwise
pub fn get_directory_listing(
    method: EscalationMethod,
    username: Option<String>,
    password: Option<String>,
) -> Result<String> {
    match method {
        EscalationMethod::Polkit => {
            let pkexec = Command::new("pkexec")
                .args(["ls", "-la", "/root"])
                .stdin(Stdio::null())
                .stderr(Stdio::piped())
                .stdout(Stdio::piped())
                .spawn()
                .expect("failed to run pkexec");

            let output = pkexec.wait_with_output().expect("failed to wait on pkexec");

            match output.status.code() {
                // ls successful
                Some(0) => Ok(String::from_utf8(output.stdout)
                    .expect("failed to convert pkexec output to string")),

                // pkexec failed
                Some(126 | 127) => Err(DirectoryListingError::FailedToAuthenticate.into()),

                // ls failed
                Some(2) => {
                    let stderr = String::from_utf8(output.stderr)
                        .expect("failed to convert ls output to string");

                    if stderr.contains("Permission denied") {
                        Err(DirectoryListingError::PermissionDenied.into())
                    } else if stderr.contains("No such file or directory") {
                        Err(DirectoryListingError::NoSuchDirectory.into())
                    } else {
                        Err(DirectoryListingError::Unknown.into())
                    }
                }

                _ => Err(DirectoryListingError::Unknown.into()),
            }
        }

        EscalationMethod::Sudo => {
            let password = password.expect("password is required for sudo");

            let mut sudo = Command::new("sudo")
                .args(["-k", "-S", "ls", "-la", "/root"])
                .stdin(Stdio::piped())
                .stderr(Stdio::piped())
                .stdout(Stdio::piped())
                .spawn()
                .expect("failed to run sudo");

            sudo.stdin
                .take()
                .expect("failed to take stdin")
                .write_all(password.as_bytes())
                .expect("failed to write password to sudo");

            let output = sudo.wait_with_output().expect("failed to wait on sudo");

            match output.status.code() {
                // ls successful
                Some(0) => Ok(String::from_utf8(output.stdout)
                    .expect("failed to convert sudo output to string")),

                // sudo failed
                Some(1) => Err(DirectoryListingError::FailedToAuthenticate.into()),

                // ls failed
                Some(2) => {
                    let stderr = String::from_utf8(output.stderr)
                        .expect("failed to convert ls output to string");

                    if stderr.contains("Permission denied") {
                        Err(DirectoryListingError::PermissionDenied.into())
                    } else if stderr.contains("No such file or directory") {
                        Err(DirectoryListingError::NoSuchDirectory.into())
                    } else {
                        Err(DirectoryListingError::Unknown.into())
                    }
                }

                _ => Err(DirectoryListingError::Unknown.into()),
            }
        }

        EscalationMethod::Su => {
            let username = username.expect("username is required for su");
            let password = password.expect("password is required for su");

            let mut su = Command::new("su")
                .args(["-c", "ls -la /root", &username])
                .stdin(Stdio::piped())
                .stderr(Stdio::null())
                .stdout(Stdio::piped())
                .spawn()
                .expect("failed to run su");

            su.stdin
                .take()
                .expect("failed to take stdin")
                .write_all(password.as_bytes())
                .expect("failed to write password to su");

            let output = su.wait_with_output().expect("failed to wait on su");

            match output.status.code() {
                // ls successful
                Some(0) => Ok(String::from_utf8(output.stdout)
                    .expect("failed to convert su output to string")),

                // su failed
                Some(1) => Err(DirectoryListingError::FailedToAuthenticate.into()),

                // ls failed
                Some(2) => {
                    let stderr = String::from_utf8(output.stderr)
                        .expect("failed to convert ls output to string");

                    if stderr.contains("Permission denied") {
                        Err(DirectoryListingError::PermissionDenied.into())
                    } else if stderr.contains("No such file or directory") {
                        Err(DirectoryListingError::NoSuchDirectory.into())
                    } else {
                        Err(DirectoryListingError::Unknown.into())
                    }
                }

                _ => Err(DirectoryListingError::Unknown.into()),
            }
        }

        EscalationMethod::None => {
            let ls = Command::new("ls")
                .args(["-la", "/root"])
                .stdin(Stdio::null())
                .stderr(Stdio::piped())
                .stdout(Stdio::piped())
                .spawn()
                .expect("failed to run ls");

            let output = ls.wait_with_output().expect("failed to wait on ls");

            match output.status.code() {
                // ls succeeded
                Some(0) => Ok(String::from_utf8(output.stdout)
                    .expect("failed to convert ls output to string")),

                // ls failed
                Some(2) => {
                    let stderr = String::from_utf8(output.stderr)
                        .expect("failed to convert ls output to string");

                    if stderr.contains("Permission denied") {
                        Err(DirectoryListingError::PermissionDenied.into())
                    } else if stderr.contains("No such file or directory") {
                        Err(DirectoryListingError::NoSuchDirectory.into())
                    } else {
                        Err(DirectoryListingError::Unknown.into())
                    }
                }

                _ => Err(DirectoryListingError::Unknown.into()),
            }
        }
    }
}
