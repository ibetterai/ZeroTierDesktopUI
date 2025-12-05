# Requirements Document

## Project Description (Input)
I need to build a binary for Windows ARM64 platform for ZeroTier.

## Introduction

This specification defines the requirements for adding Windows ARM64 (aarch64) platform build support to the ZeroTier Desktop UI application. Currently, the application supports Windows x86 (32-bit) and x86_64 (64-bit) architectures. This enhancement will enable the application to run natively on Windows ARM64 devices, including Snapdragon-powered laptops and future ARM-based Windows devices.

The implementation leverages Rust's cross-compilation capabilities with the `aarch64-pc-windows-msvc` target, extending the existing MSVC-based build infrastructure. All research findings are documented in [.kiro/knowledge/](.kiro/knowledge/).

**Business Value**: Expanding platform support to ARM64 Windows devices increases market reach and provides native performance on emerging ARM-based Windows hardware.

## Requirements

### Requirement 1: Rust ARM64 Toolchain Configuration
**Objective**: As a developer, I want to configure the Rust toolchain for Windows ARM64 compilation, so that I can build ARM64 binaries from the existing development environment.

**Research Reference**: [.kiro/knowledge/research-rust-arm64-toolchain-001.md](.kiro/knowledge/research-rust-arm64-toolchain-001.md)

#### Acceptance Criteria

1. WHEN the build system is initialized THEN the build system SHALL verify that the `aarch64-pc-windows-msvc` Rust target is installed via rustup

2. IF the `aarch64-pc-windows-msvc` target is not installed THEN the build system SHALL provide clear installation instructions directing the user to run `rustup target add aarch64-pc-windows-msvc`

3. WHEN building for ARM64 THEN the build system SHALL pass `--target=aarch64-pc-windows-msvc` to all cargo build commands

4. WHEN building for ARM64 release THEN the build system SHALL set `RUSTFLAGS=-C target-feature=+crt-static` to enable static linking of the C runtime, matching the existing x64 and x86 build configuration

5. WHEN the ARM64 build completes successfully THEN the build system SHALL produce the executable at `target\aarch64-pc-windows-msvc\release\zerotier_desktop_ui.exe`

---

### Requirement 2: Visual Studio ARM64 Build Tools Integration
**Objective**: As a developer, I want the build system to utilize Visual Studio ARM64 build tools, so that native libraries and Rust code can link properly for the ARM64 target.

**Research References**:
- [.kiro/knowledge/research-best-practices-001.md](.kiro/knowledge/research-best-practices-001.md)
- [.kiro/knowledge/research-challenges-001.md](.kiro/knowledge/research-challenges-001.md)

#### Acceptance Criteria

1. WHEN building for ARM64 THEN the build system SHALL require Visual Studio 2022 (or newer) with the "ARM64/ARM64EC build tools" component installed

2. WHEN the ARM64 build process starts THEN the build system SHALL execute the Visual Studio environment setup script `vcvarsx86_arm64.bat` to configure the cross-compilation environment from x64 host to ARM64 target

3. IF Visual Studio ARM64 build tools are not detected THEN the build system SHALL display an error message specifying the required Visual Studio components: "VS 2022 C++ ARM64/ARM64EC build tools (Latest)" and "Windows 11 SDK"

4. WHEN configuring the build environment THEN the build system SHALL support cross-compilation from x64 Windows hosts to ARM64 targets, without requiring native ARM64 hardware

5. WHEN the vcvars environment is activated THEN the build system SHALL verify that the `VSCMD_ARG_TGT_ARCH` environment variable equals `arm64` before proceeding with compilation

---

### Requirement 3: Native Library ARM64 Compilation - libui-ng
**Objective**: As a developer, I want libui-ng to be compiled for ARM64 architecture, so that the Rust application can link against ARM64-native UI library binaries.

**Research Reference**: [.kiro/knowledge/research-meson-arm64-001.md](.kiro/knowledge/research-meson-arm64-001.md)

#### Acceptance Criteria

1. WHEN building libui-ng for ARM64 THEN the build system SHALL create a dedicated build directory `libui-ng/build-arm64` separate from x64/x86 builds

2. WHEN configuring Meson for ARM64 THEN the build system SHALL use a Meson cross file specifying the MSVC ARM64 compiler path `HostX64\ARM64\cl.exe` and setting `host_machine.cpu_family = 'aarch64'`

3. WHEN running Meson setup THEN the build system SHALL pass the flags `--buildtype=release -Db_vscrt=mt --default-library=static --backend=ninja` to match existing Windows build configuration

4. WHEN building with Ninja THEN the build system SHALL execute `ninja -C build-arm64` within the vcvars ARM64 environment to compile the library

5. WHEN libui-ng ARM64 build completes THEN the build system SHALL rename the output library from `libui.a` to `ui.lib` in `build-arm64/meson-out/` to match MSVC naming conventions

6. WHEN linking the Rust ARM64 binary THEN the build script (`build.rs`) SHALL add the cargo link search path `libui-ng/build-arm64/meson-out` for the ARM64 target architecture

---

### Requirement 4: Native Library ARM64 Compilation - Tray
**Objective**: As a developer, I want the tray system library to be compiled for ARM64 architecture, so that the system tray functionality works correctly on ARM64 Windows.

**Research Reference**: [.kiro/knowledge/research-best-practices-001.md](.kiro/knowledge/research-best-practices-001.md)

#### Acceptance Criteria

1. WHEN building the tray library for ARM64 THEN the build system SHALL support compilation with MSVC ARM64 toolchain via Make

2. WHEN the tray Makefile is invoked for ARM64 THEN the build system SHALL pass a `WIN_ARM64=1` flag (or equivalent) to distinguish ARM64 builds from x64 and x86 builds

3. WHEN compiling tray for ARM64 THEN the build system SHALL use the ARM64 C compiler from the vcvars environment (cl.exe for ARM64 target)

4. WHEN the tray ARM64 build completes THEN the build system SHALL produce a static library `zt_desktop_tray.lib` compiled for the aarch64 architecture

5. WHEN linking the Rust ARM64 binary THEN the build script (`build.rs`) SHALL link against the ARM64-compiled tray library to prevent "library machine type" conflicts

---

### Requirement 5: Makefile Build Targets for ARM64
**Objective**: As a developer, I want dedicated Makefile targets for ARM64 builds, so that I can build ARM64 binaries using the same workflow as existing x64 and x86 builds.

**Research References**:
- [.kiro/knowledge/research-best-practices-001.md](.kiro/knowledge/research-best-practices-001.md)
- [.kiro/knowledge/research-challenges-001.md](.kiro/knowledge/research-challenges-001.md)

#### Acceptance Criteria

1. WHEN a developer runs `make windows_arm64` THEN the build system SHALL execute the complete ARM64 build process including libui-ng, tray, and Rust compilation

2. WHEN the `windows_arm64` target is invoked THEN the build system SHALL first build `libui_windows_arm64` to compile libui-ng for ARM64

3. WHEN building native libraries for ARM64 THEN the build system SHALL clean previous tray builds and rebuild with `WIN_ARM64=1` flag

4. WHEN compiling the Rust ARM64 binary THEN the build system SHALL execute cargo within the vcvars ARM64 environment with `RUSTFLAGS=-C target-feature=+crt-static`

5. WHEN a developer runs `make windows` THEN the build system SHALL build all three Windows targets: x86 (32-bit), x64 (64-bit), and ARM64 (aarch64)

6. WHEN official release builds are created (`make official` with `ZT_OFFICIAL_RELEASE=1`) THEN the build system SHALL include ARM64 binaries alongside x86 and x64 binaries

---

### Requirement 6: Build Script Architecture-Specific Configuration
**Objective**: As a developer, I want the Cargo build script to correctly configure library search paths based on the target architecture, so that the linker finds the appropriate ARM64 libraries.

**Research Reference**: [.kiro/knowledge/research-challenges-001.md](.kiro/knowledge/research-challenges-001.md)

#### Acceptance Criteria

1. WHEN the build script (`build.rs`) runs for the `aarch64-pc-windows-msvc` target THEN the build script SHALL add the library search path `libui-ng/build-arm64/meson-out`

2. WHEN the build script runs for the `x86_64-pc-windows-msvc` target THEN the build script SHALL add the library search path `libui-ng/build/meson-out` (existing behavior)

3. WHEN the build script runs for the `i686-pc-windows-msvc` target THEN the build script SHALL add the library search path `libui-ng/build/meson-out` (existing behavior)

4. WHEN linking native libraries THEN the build script SHALL emit `cargo:rustc-link-lib=static=zt_desktop_tray` and `cargo:rustc-link-lib=static=ui` for all Windows architectures

5. IF the target architecture is ARM64 and the ARM64 library directories do not exist THEN the build script SHALL emit a clear error message instructing the user to build native libraries first with `make libui_windows_arm64`

---

### Requirement 7: Dependency Compatibility Verification
**Objective**: As a developer, I want to ensure all Rust crate dependencies support the ARM64 Windows target, so that the build process completes without dependency-related errors.

**Research Reference**: [.kiro/knowledge/research-challenges-001.md](.kiro/knowledge/research-challenges-001.md)

#### Acceptance Criteria

1. WHEN auditing dependencies THEN the build system SHALL verify that all crates in `Cargo.toml` support the `aarch64-pc-windows-msvc` target

2. IF a dependency does not support ARM64 Windows THEN the development team SHALL either update to a compatible version or replace the dependency with an ARM64-compatible alternative

3. WHEN building for ARM64 THEN the following core dependencies SHALL successfully compile:
   - `serde` and `serde_json` (pure Rust, architecture-agnostic)
   - `ureq` (HTTP client, supports ARM64)
   - `chrono` (date/time, supports ARM64)
   - `parking_lot` (mutex, supports ARM64)
   - `winapi` (Windows APIs, official support for ARM64)
   - `winreg` (registry access, pure Rust, supports ARM64)

4. WHEN dependency issues occur during ARM64 builds THEN the error messages SHALL include the crate name and suggest checking for ARM64 compatibility or updating to the latest version

---

### Requirement 8: Build Validation and Verification
**Objective**: As a developer, I want to validate that the compiled binary is correctly built for ARM64 architecture, so that I can confirm the build process succeeded even without ARM64 hardware for runtime testing.

**Research Reference**: [.kiro/knowledge/research-challenges-001.md](.kiro/knowledge/research-challenges-001.md)

#### Acceptance Criteria

1. WHEN the ARM64 build completes THEN the build system SHALL provide an optional verification step using `dumpbin /headers` to confirm the executable's target architecture

2. WHEN running the verification command `dumpbin /headers target\aarch64-pc-windows-msvc\release\zerotier_desktop_ui.exe | findstr "machine"` THEN the output SHALL contain `AA64` or `ARM64` indicating correct architecture

3. IF the verification shows an incorrect architecture (e.g., `x64` or `x86`) THEN the build system SHALL report a build failure and suggest checking native library architectures

4. WHEN ARM64 binaries are produced THEN the build documentation SHALL acknowledge the limitation that runtime testing requires ARM64 Windows hardware or a compatible virtual machine

5. WHERE developers lack ARM64 hardware THEN the build system SHALL document alternative validation methods: binary inspection with dumpbin, dependency analysis, and manual installation testing instructions for users with ARM64 devices

---

### Requirement 9: Documentation and Developer Experience
**Objective**: As a developer, I want comprehensive documentation for the ARM64 build process, so that I can successfully build ARM64 binaries and troubleshoot common issues.

**Research References**:
- [.kiro/knowledge/research-rust-arm64-toolchain-001.md](.kiro/knowledge/research-rust-arm64-toolchain-001.md)
- [.kiro/knowledge/research-challenges-001.md](.kiro/knowledge/research-challenges-001.md)

#### Acceptance Criteria

1. WHEN the README.md is updated THEN the documentation SHALL include a dedicated section for Windows ARM64 build prerequisites listing:
   - Visual Studio 2022 with "ARM64/ARM64EC build tools" component
   - Windows 11 SDK
   - Rust with `aarch64-pc-windows-msvc` target installed

2. WHEN developers reference build instructions THEN the documentation SHALL provide step-by-step commands for ARM64 builds:
   ```bash
   rustup target add aarch64-pc-windows-msvc
   make windows_arm64
   ```

3. WHEN encountering common errors THEN the documentation SHALL include a troubleshooting section addressing:
   - "linker `link.exe` not found" → Install VS ARM64 build tools
   - "library machine type conflicts" → Rebuild native libraries for ARM64
   - "vcvars not configured" → Run build from proper Developer Console

4. WHEN the build system is described THEN the documentation SHALL note that ARM64 builds support cross-compilation from x64 Windows hosts, eliminating the need for ARM64 hardware during development

5. WHEN third-party developers contribute THEN the documentation SHALL reference the research knowledge base in `.kiro/knowledge/` for detailed technical background on ARM64 build decisions

---

### Requirement 10: Meson Cross File Configuration
**Objective**: As a developer, I want a properly configured Meson cross-compilation file for ARM64, so that native libraries can be built for the ARM64 target without manual compiler path configuration.

**Research Reference**: [.kiro/knowledge/research-meson-arm64-001.md](.kiro/knowledge/research-meson-arm64-001.md)

#### Acceptance Criteria

1. WHEN the project is configured for ARM64 builds THEN the repository SHALL include a Meson cross file `arm64-windows.txt` (or similar name) at the project root

2. WHEN the Meson cross file is defined THEN the `[binaries]` section SHALL specify the MSVC ARM64 compiler paths for C and C++:
   ```ini
   c = ['...\VC\Tools\MSVC\{version}\bin\HostX64\ARM64\cl.exe']
   cpp = ['...\VC\Tools\MSVC\{version}\bin\HostX64\ARM64\cl.exe']
   ```

3. WHEN the Meson cross file is defined THEN the `[host_machine]` section SHALL specify:
   ```ini
   system = 'windows'
   cpu_family = 'aarch64'
   cpu = 'aarch64'
   endian = 'little'
   ```

4. WHEN building libui-ng for ARM64 THEN the Makefile SHALL invoke Meson with `--cross-file=arm64-windows.txt` to apply the ARM64 cross-compilation configuration

5. IF the MSVC version in the cross file path becomes outdated THEN the cross file SHALL include comments instructing developers to update the version number or use vcvars environment-based detection as an alternative

---

## Summary

This requirements document defines 10 major requirement areas with 52 total acceptance criteria for implementing Windows ARM64 build support. All requirements are based on thorough research documented in `.kiro/knowledge/` and follow EARS (Easy Approach to Requirements Syntax) format for clarity and testability.

**Key Implementation Areas**:
1. Rust toolchain configuration for `aarch64-pc-windows-msvc`
2. Visual Studio ARM64 build tools integration with vcvars
3. Native library ARM64 compilation (libui-ng and tray)
4. Makefile targets for ARM64 builds
5. Architecture-specific build script configuration
6. Dependency compatibility verification
7. Build validation and verification methods
8. Comprehensive documentation
9. Meson cross-compilation file configuration

**Next Phase**: Design document will detail the technical implementation approach, file modifications, and integration strategy.
