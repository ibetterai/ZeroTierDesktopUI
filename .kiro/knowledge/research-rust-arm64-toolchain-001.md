# Research: Rust Windows ARM64 Toolchain - 2025-12-04

## Source
- **Primary URLs**:
  - https://rust-lang.github.io/rustup/installation/windows.html
  - https://doc.rust-lang.org/stable/rustc/platform-support/arm64ec-pc-windows-msvc.html
  - https://rust-lang.github.io/rustup-components-history/aarch64-pc-windows-msvc.html
- **Search Query**: "Rust Windows ARM64 aarch64-pc-windows-msvc toolchain 2025 2026 official documentation installation"
- **Date Retrieved**: 2025-12-04

## Key Findings

### Target Triple
- **Official Target**: `aarch64-pc-windows-msvc`
- **ABI**: MSVC (required for Windows ARM64, GNU toolchain does not support ARM64)
- **Tier**: Tier 2 platform support (rustup components available)

### Installation Methods

#### Native ARM64 Windows Installation
- Download and run `rustup-init.exe` built for `aarch64-pc-windows-msvc`
- Requires Visual C++ Build Tools 2019 or newer (Visual Studio 2019+)
- Default installation configures Rust to target MSVC ABI automatically

#### Cross-Compilation Setup (from x64 Windows)
```bash
rustup target add aarch64-pc-windows-msvc
```

### Build Process
```bash
cargo build --target=aarch64-pc-windows-msvc
```

### Required Dependencies
- **Visual Studio 2022** (or newer) with:
  - ARM64/ARM64EC build tools component
  - Windows 11 SDK
  - MSVC linker and libraries (rustc uses VS linker)

### Latest Version Information
- Rust toolchain: Current stable (available via rustup-components-history)
- Components availability: Tracked at https://rust-lang.github.io/rustup-components-history/aarch64-pc-windows-msvc.html
- No special version constraints found - standard Rust stable/nightly versions support ARM64

## Implementation Relevance

### Applicable to Project: YES

**Reasoning**:
- ZeroTier Desktop UI currently supports `x86_64-pc-windows-msvc` and `i686-pc-windows-msvc`
- Adding `aarch64-pc-windows-msvc` follows the same pattern
- Existing MSVC-based build infrastructure is compatible

### Integration Notes

1. **Cargo.toml**: No changes needed (architecture-agnostic dependencies)
2. **Makefile**: New target `windows_arm64` needed (similar to `windows_64`)
3. **Build Script**: May need ARM64-specific library paths in `build.rs`
4. **Rust Flags**: Requires `-C target-feature=+crt-static` (same as x64)

### Constraints/Limitations

1. **Known Issue**: On ARM64 Windows, VS Installer doesn't register COM component properly
   - **Workaround**: Always run cargo/rustc within x86_arm64 Developer Console (vcvarsx86_arm64.bat)

2. **Linker Dependency**: Cannot build without Visual Studio MSVC toolchain installed

3. **Cross-Compilation Limitation**: While cross-compilation from x64→ARM64 is supported, native library dependencies (libui-ng, tray) must also be compiled for ARM64

## Next Steps

### Further Research Needed
- Meson/Ninja ARM64 cross-compilation for native libraries (libui-ng, tray)
- Visual Studio ARM64 build tools installation and vcvars setup
- Third-party crate compatibility (all dependencies must support ARM64)

### Requirements Impact
- MUST require Visual Studio 2022+ with ARM64 build tools
- MUST add `aarch64-pc-windows-msvc` as build target
- MUST configure vcvars environment before build
- SHOULD support cross-compilation from x64 Windows (don't require native ARM64 machine)
