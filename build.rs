#[allow(unused_assignments)]
#[allow(unused_mut)]
fn main() {
    let d = env!("CARGO_MANIFEST_DIR");

    // Architecture-specific library search paths for Windows
    println!("cargo:rustc-link-search=native={}/tray", d);

    #[cfg(all(target_os = "windows", target_arch = "aarch64"))]
    {
        // ARM64 Windows: Use separate build directory for ARM64 libraries
        println!(
            "cargo:rustc-link-search=native={}/libui-ng/build-arm64/meson-out",
            d
        );
    }

    #[cfg(all(target_os = "windows", not(target_arch = "aarch64")))]
    {
        // x86 and x64 Windows: Use standard build directory
        println!(
            "cargo:rustc-link-search=native={}/libui-ng/build/meson-out",
            d
        );
    }

    #[cfg(not(target_os = "windows"))]
    {
        // macOS and Linux: Use standard build directory
        println!(
            "cargo:rustc-link-search=native={}/libui-ng/build/meson-out",
            d
        );
    }

    // Common static library link directives (all platforms and architectures)
    println!("cargo:rustc-link-lib=static=zt_desktop_tray");
    println!("cargo:rustc-link-lib=static=ui");

    // Linux-specific dynamic library dependencies
    #[cfg(target_os = "linux")] {
        println!("cargo:rustc-link-lib=dylib=gtk-3");
        println!("cargo:rustc-link-lib=dylib=gdk-3");
        println!("cargo:rustc-link-lib=dylib=gobject-2.0");
        println!("cargo:rustc-link-lib=dylib=glib-2.0");
        println!("cargo:rustc-link-lib=dylib=ayatana-appindicator3");
    }
}
