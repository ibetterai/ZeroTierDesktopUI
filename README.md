ZeroTier Desktop Tray Application and User Interface
======

This is the system tray application and user interface for controlling a local ZeroTier service on Windows, macOS, and (soon) Linux systems.

# Building

Only macOS and Windows are currently supported. Linux may build but there are still outstanding issues. We're working on full Linux support at least for popular Linux desktop environments that support relatively standard tray application APIs.

## macOS

#### Prerequisites

 * Xcode with standard command line tools and SDKs.
 * Rust (and cargo) with targets `x86_64-apple-darwin` and `aarch64-apple-darwin` installed to enable universal binaries to be built.
 * The [Meson/Ninja](https://mesonbuild.com) build system (for libui-ng).

To build on macOS you should just be able to type `make` from the project root. If all the necessary dependencies are present it should build a `ZeroTier.app` application in the current directory.

## Windows

#### Prerequisites

 * [Microsoft Visual Studio 2022](https://visualstudio.microsoft.com/vs/) with the following components:
   - Desktop development with C++ workload
   - MSVC v143 build tools for x86, x64, and ARM64 (32-bit, 64-bit, and ARM64)
   - Windows 11 SDK (10.0.22621.0 or later)
   - For ARM64 builds: "ARM64/ARM64EC build tools" component
 * Rust (and cargo) with the following targets installed:
   - `x86_64-pc-windows-msvc` (64-bit x86)
   - `i686-pc-windows-msvc` (32-bit x86)
   - `aarch64-pc-windows-msvc` (ARM64) - install with: `rustup target add aarch64-pc-windows-msvc`
 * The [Meson/Ninja](https://mesonbuild.com) build system (for libui-ng).
 * [GCC/G++](https://nuwen.net/mingw.html) with support for both 64-bit and 32-bit builds. Yes, we need both Visual Studio and GCC with GNU make.

#### Building

To build native applications for Windows, just type `make`. This assumes that GNU make, GCC, and Cargo are in your path. The result will be three native EXEs:
 * `target\x86_64-pc-windows-msvc\release\zerotier_desktop_ui.exe` (64-bit x86)
 * `target\i686-pc-windows-msvc\release\zerotier_desktop_ui.exe` (32-bit x86)
 * `target\aarch64-pc-windows-msvc\release\zerotier_desktop_ui.exe` (ARM64)

To build only a specific architecture:
```bash
make windows_64     # Build 64-bit x86 only
make windows_32     # Build 32-bit x86 only
make windows_arm64  # Build ARM64 only
```

**Note on ARM64 builds**: ARM64 binaries can be cross-compiled on x64 Windows hosts without requiring ARM64 hardware. The build system uses Visual Studio's ARM64 cross-compilation toolchain (`vcvarsx86_arm64.bat`).

#### Validating ARM64 Builds (without ARM64 hardware)

To verify that the ARM64 binary was built correctly, you can inspect the binary architecture using Visual Studio's `dumpbin` tool:

```cmd
dumpbin /headers target\aarch64-pc-windows-msvc\release\zerotier_desktop_ui.exe | findstr "machine"
```

Expected output: `machine (AA64)` or `machine (0xAA64)`

#### Troubleshooting

**Error: linker `link.exe` not found**
 * **Solution**: Install Visual Studio 2022 with ARM64 build tools component. Open Visual Studio Installer → Modify → Individual Components → Search "ARM64" → Check "MSVC v143 - VS 2022 C++ ARM64/ARM64EC build tools (Latest)"

**Error: library machine type conflicts (e.g., `LNK1112: module machine type 'x64' conflicts with target machine type 'arm64'`)**
 * **Solution**: Rebuild native libraries for the correct architecture:
   ```bash
   make clean
   make libui_windows_arm64  # Or libui_windows_64, libui_windows_32
   make -C tray clean
   make -C tray zt_lib WIN_ARM64=1  # Or WIN_32BIT=1 for x86
   ```

**Error: vcvars environment not configured**
 * **Solution**: Open the appropriate Visual Studio Developer Command Prompt:
   - For x64: "x64 Native Tools Command Prompt for VS 2022"
   - For ARM64: "x64_arm64 Cross Tools Command Prompt for VS 2022"

## Linux, FreeBSD, Other Open Source Desktops

#### Prerequisites

* Rust (and cargo) with 2021 edition support
* gtk-3
* gdk-3
* gobject-2.0
* glib-2.0
* libaytana-appindicator3

# Directly Incorporated Third Party Code

The ZeroTier desktop UI uses forked and slightly modified versions of the following third party code:

 * [Tray](https://github.com/zserge/tray) by [Serge Zaitsev](https://github.com/zserge), forked to slightly modify behavior in regard to loop timeouts and Mac application settings. We also manually applied a pull request that fixes builds on ARM64 macOS. (MIT license)
 * [LibUI-ng](https://github.com/libui-ng/libui-ng) by Pietro Gagliardi and others. (MIT license)

Other third party dependencies are included in the normal way. See [Cargo.toml](Cargo.toml) for these.

# License

Licensed under the Mozilla Public License (MPL) version 2.0.
