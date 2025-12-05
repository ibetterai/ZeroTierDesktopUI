# Technology Stack

## Architecture

**Multi-Process Desktop Application**
- Main tray application runs as low-priority background process
- Spawns child processes for UI dialogs (About, Join Network)
- Communicates with ZeroTier system service via HTTP REST API
- Platform-specific system tray integration via C bindings

## Language & Runtime

**Primary Language**: Rust (Edition 2021)
- Version: 1.10.0
- Optimized release builds with LTO and minimal binary size

## Core Dependencies

### Rust Crates
- `serde` & `serde_json` ^1 - JSON serialization/deserialization for API communication
- `ureq` 2.6.2 - Lightweight HTTP client for service API calls
- `chrono` ^0 - Date/time handling for authentication expiry
- `parking_lot` ^0 - Efficient mutex implementation
- `crc64` ^1 - Hashing for change detection in service state
- `runas` ^1 - Privilege escalation for auth token access
- `url` ^2.5.4 - URL parsing and validation
- `webbrowser` ^0 - Opening SSO URLs in default browser

### Platform-Specific Dependencies

**macOS**:
- `plist` ^1 - Reading old UI network cache files
- `mac-notification-sys` - Native macOS notifications

**Windows**:
- `winreg` ^0 - Registry access for auto-start configuration
- `winapi` ^0 - Windows API bindings for clipboard and UI

**Linux/Unix**:
- `notify-rust` ^4 - Desktop notifications
- `libc` ^0 - POSIX system calls

## Native Libraries

### UI Framework
**LibUI-ng** (statically linked)
- Cross-platform native UI toolkit (forked version)
- Built with Meson/Ninja build system
- Platform-specific rendering (Win32, Cocoa, GTK)

### System Tray
**Tray** by Serge Zaitsev (forked version)
- Custom fork with modified loop timeout behavior
- ARM64 macOS support patches applied
- Platform-specific implementations (Win32, Cocoa, AppIndicator)

### Linux-Specific
- `gtk-3` - GTK+ 3 widget toolkit
- `gdk-3` - GDK graphics library
- `gobject-2.0` - GObject type system
- `glib-2.0` - Core application library
- `libayatana-appindicator3` - System tray indicator support

## Build System

**Make + Cargo**
- GNU Make for orchestrating multi-stage builds
- Cargo for Rust compilation and dependency management
- Platform detection via Makefile conditionals

### Build Targets
- **macOS**: Universal binaries (x86_64 + ARM64) via `lipo`
- **Windows**: Both 32-bit and 64-bit executables
- **Linux**: 64-bit with GTK integration

### Build Tools Required
- **All Platforms**: Rust toolchain with platform-specific targets, Meson/Ninja
- **macOS**: Xcode command line tools, macOS SDKs
- **Windows**: Visual Studio 2022 (32/64-bit), GCC/G++ (MinGW), GNU Make
- **Linux**: GCC, GTK/GDK development libraries

## Development Environment

### Environment Variables
- `HOME` / `USERPROFILE` - User home directory for auth token storage
- `CARGO_MANIFEST_DIR` - Build script directory reference
- `MACOSX_DEPLOYMENT_TARGET=10.13` - macOS minimum version
- `RUSTFLAGS` - Platform-specific compiler flags (static linking, safe SEH)
- `ZT_OFFICIAL_RELEASE=1` - Enables code signing and release optimizations
- `LIBUI_CFLAGS` - Architecture-specific C compiler flags

### File Paths
**Application Home**:
- macOS: `~/Library/Application Support/ZeroTier`
- Windows: `%USERPROFILE%\AppData\Local\ZeroTier`
- Linux: `~/.zerotier_ui`

**Service Directories**:
- macOS: `/Library/Application Support/ZeroTier`
- Windows: `\ProgramData\ZeroTier`
- Linux: `/var/lib/zerotier`
- BSD: `/var/db/zerotier`

**Key Files**:
- `authtoken.secret` - ZeroTier service authentication token
- `zerotier.port` - Service HTTP API port (default 9993)
- `saved_networks.json` - Cached network list

## Common Commands

### Building
```bash
make                    # Build for current platform
make windows            # Build both 32-bit and 64-bit Windows
make windows_64         # Build 64-bit Windows only
make mac                # Build universal macOS binary
make linux              # Build Linux binary
make official           # Official release build (with code signing)
```

### Cleaning
```bash
make clean              # Remove build artifacts
make distclean          # Full clean
```

### Development
```bash
cargo build             # Debug build
cargo build --release   # Optimized build
make bindgen            # Regenerate libui.rs bindings (rarely needed)
```

## Port Configuration

**Default Port**: 9993 (ZeroTier service HTTP API)
- Read from `zerotier.port` file in service home directory
- Falls back to 9993 if not found

## API Communication

**HTTP REST API**:
- Base URL: `http://localhost:<port>/`
- Authentication: `X-ZT1-Auth` header with token
- Timeout: 2000ms per request
- Endpoints: `/status`, `/network`, `/network/<id>`
- Methods: GET (query), POST (join/configure), DELETE (leave)

## Security Considerations

- Auth tokens stored in user-specific directories with platform-appropriate permissions
- macOS uses `c_lock_down_file` to set restrictive permissions
- Privilege escalation only attempted for initial auth token access
- No credentials embedded in binary
- Service communication restricted to localhost
