# Project Structure

## Root Directory Organization

```
DesktopUI/
├── src/                    # Rust source code
├── tray/                   # System tray library (forked)
├── libui-ng/              # UI toolkit library (forked)
├── mac-app-template/      # macOS .app bundle template
├── Cargo.toml             # Rust package manifest
├── Makefile               # Build orchestration
├── build.rs               # Cargo build script
├── icon.ico               # Windows icon
├── icon.png               # Linux icon
├── LICENSE.txt            # MPL 2.0 license
└── README.md              # Documentation
```

## Source Code Structure (`src/`)

### Core Modules

**`main.rs`** (1191 lines)
- Application entry point and main event loop
- System tray menu construction and refresh logic
- Platform-specific initialization (APPLICATION_PATH, APPLICATION_HOME)
- Network menu generation and interaction handlers
- Child process management (About dialog, Join dialog)
- Platform constants for service home directories

**`serviceclient.rs`** (624 lines)
- `ServiceClient` struct - HTTP client for ZeroTier service API
- Authentication token and port discovery
- JSON state caching with CRC64-based change detection
- Network list management and saved networks persistence
- Background sync thread coordination via `Arc<AtomicBool>` dirty flag

**`tray.rs`**
- FFI bindings to C tray library
- Platform-specific tray icon and menu management
- Event loop integration

**`libui.rs`**
- Auto-generated FFI bindings to libui-ng
- Created via `bindgen` (rarely regenerated)

**`about.rs`**
- About dialog implementation
- Version display

**`join.rs`**
- Join network dialog
- Network ID input and validation

## Code Organization Patterns

### Multi-Process Architecture
```
Main Process (tray_main)
├── Background Thread → ServiceClient sync loop
├── Child Process → About dialog (spawned on demand)
└── Child Process → Join dialog (spawned on demand)
```

### State Management
- **Global Static Variables**: `APPLICATION_PATH`, `APPLICATION_HOME`, `NETWORK_CACHE_PATH`, `START_ON_LOGIN`
- **Shared State**: `Arc<Mutex<ServiceClient>>` for thread-safe service state access
- **Dirty Flag**: `Arc<AtomicBool>` for efficient change notification
- **Change Detection**: CRC64 hashing of JSON responses to minimize UI updates

### Platform Abstraction
```rust
#[cfg(target_os = "macos")]
fn platform_specific() { /* macOS implementation */ }

#[cfg(windows)]
fn platform_specific() { /* Windows implementation */ }

#[cfg(target_os = "linux")]
fn platform_specific() { /* Linux implementation */ }
```

## File Naming Conventions

### Rust Source Files
- Module names: lowercase snake_case (e.g., `serviceclient.rs`)
- Match module declarations in `main.rs`

### Build Artifacts
- **macOS**: `ZeroTier.app/` (application bundle)
- **Windows**: `target/x86_64-pc-windows-msvc/release/zerotier_desktop_ui.exe`
- **Linux**: `target/release/zerotier_desktop_ui`

### Resource Files
- Icon files at project root: `icon.ico`, `icon.png`
- macOS template icon: `trayIconTemplate.pdf` (in app bundle)
- Temporary icon (Linux/Windows): `%TEMP%/zerotier-tray-icon.ico`

## Import Organization

### Standard Library Imports
```rust
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, atomic::*};
use std::time::{Duration, SystemTime};
```

### External Crate Imports
```rust
use parking_lot::Mutex;
use serde_json::Value;
```

### Internal Module Imports
```rust
use crate::serviceclient::*;
use crate::tray::*;
```

### Platform-Specific Imports
```rust
#[cfg(target_os = "macos")]
use plist;

#[cfg(windows)]
use winreg;
```

## Key Architectural Principles

### 1. Minimal Resource Usage
- Background thread priority for tray process (efficiency cores on Apple Silicon)
- Foreground priority only for user-facing operations
- Polling with change detection (CRC64) to avoid unnecessary rendering

### 2. Platform-Native Integration
- Use platform-specific APIs for clipboard, notifications, auto-start
- Native UI widgets via libui-ng
- Platform-appropriate file paths and registry/preferences storage

### 3. Backward Compatibility
- Import old network lists from previous UI versions
- Support both v1 and v2 service directory structures
- Fallback mechanisms for missing configuration files

### 4. Security-First Design
- Auth tokens never hardcoded or transmitted over network
- Privilege escalation only when necessary and user-approved
- Localhost-only API communication
- Platform-specific file permissions enforcement

### 5. Fault Tolerance
- Graceful handling of missing/inaccessible service
- Retry logic for authentication
- IPv4/IPv6 localhost fallback
- Child process lifecycle management

### 6. Separation of Concerns
- **serviceclient.rs**: Pure API client logic
- **main.rs**: UI event handling and tray menu logic
- **about.rs, join.rs**: Isolated dialog implementations
- **tray.rs, libui.rs**: FFI boundary layer

### 7. Stateless UI, Stateful Backend
- Menu rebuilt from scratch on each refresh
- ServiceClient maintains cached state with change detection
- UI always reflects current service state

## Third-Party Code Integration

### Forked Dependencies (Directly Incorporated)
- **tray/** - Modified C implementation of system tray functionality
- **libui-ng/** - Modified cross-platform UI toolkit

### Build Process Integration
1. Build native libraries (tray, libui-ng) via Make
2. Link static libraries via build.rs
3. Compile Rust code with Cargo
4. Platform-specific assembly (lipo for macOS universal, codesigning)

## Configuration Files

**Cargo.toml**:
- Package metadata and dependencies
- Release profile optimization settings (opt-level='z', LTO, single codegen-unit)
- Platform-specific dependency activation

**Makefile**:
- Multi-stage build orchestration
- Platform detection and toolchain selection
- Library building and linking coordination

**build.rs**:
- Cargo build script for linking native libraries
- Platform-specific library search paths
- Dynamic library linking for Linux GTK dependencies
