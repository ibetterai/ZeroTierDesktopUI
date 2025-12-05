# Research: Windows ARM64 Cross-Compilation Best Practices - 2025-12-04

## Source
- **Primary URLs**:
  - https://patriksvensson.se/posts/2020/05/targeting-arm-for-windows-in-rust
  - https://stackoverflow.com/questions/71404922/how-can-i-create-a-rust-development-environment-on-windows-arm64
  - https://rust-lang.github.io/rustup/cross-compilation.html
- **Search Query**: "Windows ARM64 cross compilation Rust Cargo build best practices Visual Studio 2022"
- **Date Retrieved**: 2025-12-04

## Key Findings

### Cross-Compilation Support
- **Official Status**: Rust fully supports cross-compilation from x64 Windows to ARM64 Windows
- **No Native Hardware Required**: ARM64 binaries can be built entirely on x64 machines
- **Toolchain Requirement**: Only MSVC target available (GNU Windows toolchain does not support ARM64)

### Prerequisites Checklist
1. ✅ Visual Studio 2022 (or above) installed
2. ✅ "ARM64/ARM64EC build tools" component installed via VS Installer
3. ✅ Windows 11 SDK installed
4. ✅ Rust toolchain with `aarch64-pc-windows-msvc` target added
5. ⚠️ Visual Studio Build Tools alone sufficient (full VS IDE not required - much smaller)

### Build Process Best Practices

#### Target Installation
```bash
rustup target add aarch64-pc-windows-msvc
rustup target list  # Verify installation
```

#### Build Command
```bash
cargo build --target aarch64-pc-windows-msvc
cargo build --target aarch64-pc-windows-msvc --release
```

#### Environment Setup
- **Recommended**: Use Visual Studio Developer Command Prompt with ARM64 environment
- **Command**: Run vcvarsall.bat or vcvarsx86_arm64.bat before building
- **Automated**: Can be integrated into Makefile/build scripts

### RUSTFLAGS Configuration
```bash
set RUSTFLAGS=-C target-feature=+crt-static
cargo build --target aarch64-pc-windows-msvc
```
- **Purpose**: Static linking of C runtime (same as x64 builds in current project)
- **Consistency**: Aligns with existing Windows build configuration

### Multi-Architecture Builds
**Pattern from macOS universal binaries**:
- Build x64 target: `cargo build --target x86_64-pc-windows-msvc`
- Build ARM64 target: `cargo build --target aarch64-pc-windows-msvc`
- No `lipo` equivalent on Windows (produce separate executables)

### Visual Studio Component Selection
**Minimal Installation**:
- Base: "Desktop development with C++"
- Individual Components:
  - MSVC v143 - VS 2022 C++ ARM64/ARM64EC build tools (Latest)
  - Windows 11 SDK (10.0.xxxxx.0)
  - C++ CMake tools for Windows (optional, for native lib builds)

**Full VS Not Required**: Build Tools package is sufficient and much smaller

## Implementation Relevance

### Applicable to Project: YES

**Reasoning**:
- Current project builds x64 and x86 Windows binaries using similar cross-compilation approach
- ARM64 follows identical pattern with different target triple
- Visual Studio requirement already documented in README.md

### Integration Notes

1. **Makefile Integration**:
   ```makefile
   windows_arm64: FORCE
       make libui_windows_arm64
       make -C tray clean
       make -C tray zt_lib WIN_ARM64=1
       set "RUSTFLAGS=-C target-feature=+crt-static" && cargo build $(CARGO_FLAGS) --target=aarch64-pc-windows-msvc
   ```

2. **Build Script Consistency**: Use same vcvars pattern as existing x64/x86 builds
   - x64: vcvars64.bat
   - x86: vcvars32.bat
   - ARM64: vcvarsx86_arm64.bat (cross-compile from x64 host)

3. **Output Directory**: `target\aarch64-pc-windows-msvc\release\zerotier_desktop_ui.exe`

### Constraints/Limitations

1. **Native Library Dependencies**:
   - libui-ng must be compiled for ARM64
   - tray library must be compiled for ARM64
   - All static libraries must match target architecture

2. **No Fat Binaries**: Unlike macOS, Windows doesn't support multi-architecture single executables

3. **Testing Limitation**: Cannot test ARM64 binary on x64 machine (requires ARM64 Windows device or VM)

4. **Dependency Compatibility**: All Cargo dependencies must support `aarch64-pc-windows-msvc` (most do, but verify)

## Next Steps

### Further Research Needed
- Meson cross-compilation configuration for libui-ng ARM64
- Tray library Makefile modifications for ARM64
- Testing strategy without native ARM64 hardware

### Requirements Impact
- MUST support cross-compilation from x64 Windows
- MUST document Visual Studio ARM64 component requirements
- SHOULD produce separate ARM64 executable (no fat binary attempt)
- SHOULD verify all Cargo dependencies support ARM64 target
- MUST update README.md with ARM64 build instructions
