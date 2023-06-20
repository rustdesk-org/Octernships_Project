use std::{process::Command, io::Write};

/// Rust function that retrieves the username of the current user by executing a terminal command. 
/// It utilizes the underlying operating system's capabilities to obtain the username.
/// Returns a string value.
/// 
/// ### Example
/// ```{rust}
/// fn main() {
///     let username = get_username(); // returns current user's username
///     println!("Hello, {}!", username);
/// }
/// ```

pub fn get_username() -> String {
    let process = Command::new("whoami").output().expect("failed to execute");
    let username = String::from_utf8(process.stdout)
        .expect("failed to convert to string")
        .trim()
        .to_string();

    return username;
}

/// Rust function that uses the sudo command to elevate privilege.
/// Takes in a password as a String argument to grant access to the root folder.
/// 
/// ### Return Values
/// - Returns Some(String) if the function was successfullt executed and the proper rights have been granted.
/// - Returns None if the function fails to execute correctly and the proper rights have not been given to the administrator.
/// 
/// ### Example
/// ```rust
/// fn main() {
///     let return_statement = print_root_folder("pass1234".to_string());
///     println("{:?}", return_statement); // prints the output statement provided the password is correct or throws an error.
/// }
/// ```
pub fn print_root_folder(password : String) -> Option<String> {
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
