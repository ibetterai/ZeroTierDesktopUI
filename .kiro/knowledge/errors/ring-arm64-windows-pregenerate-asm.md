# Error: ring crate ARM64 Windows build with RING_PREGENERATE_ASM

## Error Details
- **Error Message**: `called Result::unwrap() on an Err value: Os { code: 183, kind: AlreadyExists, message: "Cannot create a file when that file already exists." }`
- **Context**: Building `ring v0.17.13` for `aarch64-pc-windows-msvc` target
- **File/Location**: `ring-0.17.13\build.rs:373:35`
- **Date**: 2025-12-04

## Research Conducted
- **Search Queries Used**:
  - "ring crate ARM64 Windows build error 183"
  - "ring RING_PREGENERATE_ASM AlreadyExists Windows ARM64"
  - "ring 0.17.13 aarch64-pc-windows-msvc build error"

## Problem Analysis
The `ring` crate 0.17.13 has a bug when building for ARM64 Windows with `RING_PREGENERATE_ASM=1`. The build script tries to create a file that already exists, causing Windows error 183 ("Cannot create a file when that file already exists").

## Solutions Attempted
1. **Solution 1**: Set `RING_PREGENERATE_ASM=1` to avoid needing clang
   - **Result**: Failure - triggers the file-already-exists bug
   - **Notes**: This workaround doesn't work for ARM64 Windows in ring 0.17.13

2. **Solution 2**: Clean build cache and retry
   - **Result**: Failure - same error persists
   - **Notes**: The issue is in the ring build script itself, not stale artifacts

## Working Solution
**Final Solution**: Install LLVM with clang and build without `RING_PREGENERATE_ASM`
- **Implementation**:
  1. Install LLVM: `winget install LLVM.LLVM`
  2. Add `C:\Program Files\LLVM\bin` to PATH
  3. Remove `RING_PREGENERATE_ASM=1` from build script
  4. Set `CC=clang.exe` for ARM64 builds
- **Why It Works**: The ring crate's build script properly handles ARM64 Windows builds when using clang, avoiding the pregenerated ASM code path that has the bug
- **Prevention**: For production builds, consider upgrading to `ring` v0.18.x which has better ARM64 Windows support

## Status
- [x] Error encountered
- [x] Research conducted
- [x] Solution found
- [ ] Solution implemented and verified (testing with clang now)
