use std::process::{Command};
use std::{fs, any};
use std::path::Path;
use anyhow::{Result, anyhow};


// A plain enum without any fields. This is similar to Dart- or C-style enums.
// flutter_rust_bridge is capable of generating code for enums with fields
// (@freezed classes in Dart and tagged unions in C).
pub enum Platform {
    Unknown,
    Android,
    Ios,
    Windows,
    Unix,
    MacIntel,
    MacApple,
    Wasm,
}

// A function definition in Rust. Similar to Dart, the return type must always be named
// and is never inferred.
pub fn platform() -> Platform {
    // This is a macro, a special expression that expands into code. In Rust, all macros
    // end with an exclamation mark and can be invoked with all kinds of brackets (parentheses,
    // brackets and curly braces). However, certain conventions exist, for example the
    // vector macro is almost always invoked as vec![..].
    //
    // The cfg!() macro returns a boolean value based on the current compiler configuration.
    // When attached to expressions (#[cfg(..)] form), they show or hide the expression at compile time.
    // Here, however, they evaluate to runtime values, which may or may not be optimized out
    // by the compiler. A variety of configurations are demonstrated here which cover most of
    // the modern oeprating systems. Try running the Flutter application on different machines
    // and see if it matches your expected OS.
    //
    // Furthermore, in Rust, the last expression in a function is the return value and does
    // not have the trailing semicolon. This entire if-else chain forms a single expression.
    if cfg!(windows) {
        Platform::Windows
    } else if cfg!(target_os = "android") {
        Platform::Android
    } else if cfg!(target_os = "ios") {
        Platform::Ios
    } else if cfg!(all(target_os = "macos", target_arch = "aarch64")) {
        Platform::MacApple
    } else if cfg!(target_os = "macos") {
        Platform::MacIntel
    } else if cfg!(target_family = "wasm") {
        Platform::Wasm
    } else if cfg!(unix) {
        Platform::Unix
    } else {
        Platform::Unknown
    }
}

// The convention for Rust identifiers is the snake_case,
// and they are automatically converted to camelCase on the Dart side.
pub fn rust_release_mode() -> bool {
    cfg!(not(debug_assertions))
}

// 定义执行ls -la /root的策略
trait LsRootStrategy {
    fn execute(&self) -> Result<Vec<String>>;
}

// 直接执行ls -la /root
struct DirectLsStrategy;

impl LsRootStrategy for DirectLsStrategy {
    fn execute(&self) -> Result<Vec<String>> {
        let output = Command::new("ls")
            .arg("-la")
            .arg("/root")
            .output()
            // 没有权限并不会被Command output判断为错误并退出
            .expect("Failed to execute ls -la /root");

        if output.status.success() {
            let output_str = String::from_utf8(output.stdout)?;
            return Ok(output_str.lines().map(String::from).collect());
        }

        Err(anyhow!("Permission Denied"))
    }
}

// 使用pkexec提权执行ls -la /root
struct PkexecLsStrategy;

impl LsRootStrategy for PkexecLsStrategy {
    fn execute(&self) -> Result<Vec<String>> {
        match Command::new("pkexec")
            .arg("ls")
            .arg("-la")
            .arg("/root")
            .output() {
            Ok(output) => {
                if output.status.success() {
                    let output_str = String::from_utf8(output.stdout)?;
                    return Ok(output_str.lines().map(String::from).collect());
                }
                Err(anyhow!("Permission Denied"))
            }
            // 如果没有找到pkexec的话手动处理执行失败，以便于执行下面的sudo方案
            Err(_) => Err(anyhow!("Failed to elevate privileges using pkexec."))
        }
    }
}

// 使用sudo -S提权执行ls -la /root
struct SudoLsStrategy {
    password: String,
}

impl LsRootStrategy for SudoLsStrategy {
    fn execute(&self) -> Result<Vec<String>> {
        if let password = &self.password {
            let echo_cmd = format!("echo {}", password);
            let output = Command::new("sh")
                .arg("-c")
                .arg(format!("{} | sudo -S ls -la /root > /tmp/output.txt", echo_cmd))
                .output()
                .expect("Failed to elevate privileges using sudo.");

            if output.status.success() {
                let output = fs::read_to_string("/tmp/output.txt")
                    .expect("Failed to read output file");

                return Ok(output.lines().map(String::from).collect());
            }
        }

        Err(anyhow!("Password is required"))
    }
}

// 直接或使用polkit尝试获取ls_root的结果
pub fn ls_root_with_polkit() -> Result<Vec<String>> {
    // 检查/root目录是否存在
    if !Path::new("/root").exists() {
        return Err(anyhow!("/root/ folder does not exist."));
    }

    let strategies: Vec<Box<dyn LsRootStrategy>> = vec![
        Box::new(DirectLsStrategy),
        Box::new(PkexecLsStrategy),
    ];

    for strategy in strategies {
        match strategy.execute() {
            Ok(result) => return Ok(result),
            Err(_) => continue,
        };
    }

    // 使用polkit访问失败
    Err(anyhow!("Failed to elevate privileges using polkit."))
}

// 执行ls -la /root，将返回的条目以列表的形式返回，试图使用给定的密码
pub fn ls_root_with_sudo(password: String) -> Result<Vec<String>> {
    // 检查/root目录是否存在
    if !Path::new("/root").exists() {
        return Err(anyhow!("/root/ folder does not exist."));
    }

    let strategy = SudoLsStrategy { password };
    strategy.execute().map_err(|_| anyhow!("Failed to elevate privileges using sudo."))
}

