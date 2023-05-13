use std::process::{Command};
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

// 执行ls -la /root，将返回的条目以列表的形式返回
pub fn ls() -> Result<Vec<String>> {
    // 检查/root目录是否存在
    if !Path::new("/root").exists() {
        return Err(anyhow!("/root/ folder does not exist."));
    }

    // 直接执行指令，如果有权限的话直接返回结果 
    let output = Command::new("ls")
        .arg("-la")
        .arg("/root")
        .output()
        .expect("No access permission to the /root directory.");

    // 如果失败，代表用户自己没有权限访问root，尝试使用pkexec提权执行命令
    if !output.status.success() {

        // 执行提权
        let output = Command::new("pkexec")
            .arg("ls")
            .arg("-la")
            .arg("/root")
            .output()
            .expect("Failed to elevate privileges using pkexec.");

        // 使用pkcheck检测agent是否有效，如果无效的话则返回polkit的agent并没有工作正常
        // let has_agent = Command::new("pkcheck")
        //     .arg("--action-id")
        //     .arg("org.freedesktop.policykit.exec")
        //     .output()
        //     .expect("Failed to check if polkit agent is working."); 

        // if !has_agent.status.success() {
        //     return Err(anyhow!("Polkit agent is not working."));
        // } 

        // 使用pkexec提权失败
        if !output.status.success() {
            return Err(anyhow!("Permission Denied"));
        }

        let output_str = String::from_utf8(output.stdout)?;
        return Ok(output_str.lines().map(String::from).collect());
    }

    let output_str = String::from_utf8(output.stdout)?;
    Ok(output_str.lines().map(String::from).collect())
}