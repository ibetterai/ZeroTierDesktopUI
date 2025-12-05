# Research: Meson/Ninja Windows ARM64 Cross-Compilation - 2025-12-04

## Source
- **Primary URLs**:
  - https://mesonbuild.com/Cross-compilation.html
  - https://mesonbuild.com/Machine-files.html
  - https://github.com/mesonbuild/meson/issues/14752
  - https://github.com/mesonbuild/meson/issues/4402
- **Search Query**: "Meson Ninja Windows ARM64 cross compile libui native libraries aarch64"
- **Date Retrieved**: 2025-12-04

## Key Findings

### Cross-Compilation Support
- **Official Support**: Meson supports Windows ARM64 cross-compilation via cross files
- **Compiler**: Use MSVC ARM64 compiler (cl.exe) from Visual Studio
- **Alternative**: clang-cl with `--target=aarch64-win32-msvc` (experimental)

### Cross File Configuration

#### Recommended: MSVC ARM64 Compiler
```ini
[binaries]
c = ['C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\HostX64\ARM64\cl.exe']
cpp = ['C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\HostX64\ARM64\cl.exe']
ar = ['C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\HostX64\ARM64\lib.exe']

[host_machine]
system = 'windows'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
```

#### Alternative: Clang-CL (has architecture detection issues)
```ini
[binaries]
c = 'clang-cl'
cpp = 'clang-cl'
ar = 'llvm-lib'

[properties]
c_args = ['--target=aarch64-win32-msvc']
cpp_args = ['--target=aarch64-win32-msvc']
```

### Build Process
```bash
# Setup with cross file
meson setup --cross-file=arm64-windows.txt build-arm64 --buildtype=release --default-library=static

# Build
ninja -C build-arm64
```

### MSVC Compiler Path Discovery
- **Version-Specific**: Path includes MSVC version (e.g., 14.44.35207)
- **Dynamic Discovery**: Use `vswhere.exe` or vcvarsall.bat to find latest version
- **Fallback**: Hardcode latest stable version path

### Known Issues

#### Issue #14752: Library Machine Type Conflicts
- **Problem**: Cross-compile for ARM64 Windows fails at link stage with "library machine type 'x64' conflicts with target machine type 'arm64'"
- **Root Cause**: Some dependencies link against x64 libraries during ARM64 build
- **Solution**: Ensure ALL dependencies (including Windows SDK libs) are ARM64 versions
- **Workaround**: Specify ARM64 library paths explicitly in cross file

#### Issue #7751: Clang-CL Architecture Detection
- **Problem**: Meson detects wrong architecture when using clang-cl with --target flag
- **Status**: Workarounds exist but MSVC cl.exe is more reliable

### Best Practices

1. **Use MSVC cl.exe**: More reliable than clang-cl for Windows ARM64
2. **Static Libraries**: Specify `--default-library=static` for easier linking
3. **Separate Build Directory**: Use dedicated build dir for ARM64 (e.g., `build-arm64`)
4. **Version-Agnostic Paths**: Use vcvarsall.bat environment rather than hardcoded paths
5. **Match Build Type**: Use same buildtype as main project (release for distribution)

## Implementation Relevance

### Applicable to Project: YES

**Reasoning**:
- Project currently uses Meson/Ninja to build libui-ng
- ARM64 requires separate Meson cross-compilation setup
- Existing Makefile patterns can be extended

### Integration Notes

#### Makefile Target
```makefile
libui_windows_arm64: FORCE
    -rmdir /Q /S libui-ng\build-arm64
    cd libui-ng && "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsx86_arm64.bat" && meson setup build-arm64 --cross-file=../arm64-windows.txt --buildtype=release -Db_vscrt=mt --default-library=static --backend=ninja
    cd libui-ng && "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsx86_arm64.bat" && ninja -C build-arm64 -j 12
    cd libui-ng\build-arm64\meson-out && rename libui.a ui.lib
```

#### Cross File Creation
- **Location**: Project root as `arm64-windows.txt`
- **Content**: MSVC ARM64 compiler paths with dynamic version detection
- **Maintenance**: Update when Visual Studio version changes

#### Build Script Integration (build.rs)
```rust
println!("cargo:rustc-link-search=native={}/libui-ng/build-arm64/meson-out", d);
```

### Constraints/Limitations

1. **Library Machine Type Conflicts**: Must ensure all dependencies are ARM64
   - Windows SDK ARM64 libraries required
   - Third-party libs must be recompiled for ARM64

2. **vcvars Requirement**: Must run within ARM64 cross-compilation environment
   - Call vcvarsx86_arm64.bat before meson/ninja
   - Environment setup is mandatory

3. **Separate Build Directory**: Cannot reuse x64 build directory
   - Need dedicated `build-arm64` directory
   - Increases disk space requirements

4. **MSVC Version Dependency**: Compiler path is version-specific
   - May break when Visual Studio updates
   - Should use vcvars environment to avoid hardcoding

## Next Steps

### Further Research Needed
- ✅ Rust ARM64 toolchain setup (completed)
- ✅ Visual Studio vcvars setup (completed)
- Tray library ARM64 compilation (C library, may need manual Makefile update)
- Windows SDK ARM64 library availability verification

### Requirements Impact
- MUST create Meson cross file for ARM64
- MUST use MSVC cl.exe (not clang-cl) for reliability
- MUST build libui-ng in separate ARM64 build directory
- MUST call vcvarsx86_arm64.bat before Meson setup
- SHOULD use static library linking (`--default-library=static`)
- MUST match existing build flags (`-Db_vscrt=mt` for static CRT)
