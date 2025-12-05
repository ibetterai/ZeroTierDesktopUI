@echo off
REM Build script for ARM64 Windows
REM This script sets up the environment and builds the ZeroTier Desktop UI for ARM64

echo Setting up ARM64 build environment...

REM Add tools to PATH
set "PATH=C:\Users\huilinzhu\.cargo\bin;%PATH%"
set "PATH=C:\Users\huilinzhu\AppData\Roaming\Python\Python314\Scripts;%PATH%"
set "PATH=C:\Users\huilinzhu\AppData\Local\Microsoft\WinGet\Links;%PATH%"
set "PATH=C:\Program Files (x86)\GnuWin32\bin;%PATH%"
set "PATH=C:\llvm-mingw-20251118-ucrt-aarch64\bin;%PATH%"

REM Set up Visual Studio environment for ARM64
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsarm64.bat"

echo.
echo Checking tool versions...
cargo --version
meson --version
ninja --version
make --version | findstr /C:"GNU Make"
aarch64-w64-mingw32-gcc --version 2>nul || echo GCC wrapper not found, will use MSVC

echo.
echo Building libui-ng for ARM64...
cd libui-ng
if exist build-arm64 rmdir /S /Q build-arm64
meson setup build-arm64 --cross-file=..\arm64-windows.txt --buildtype=release -Db_vscrt=mt --default-library=static --backend=ninja
if errorlevel 1 (
    echo ERROR: Meson setup failed
    cd ..
    exit /b 1
)

ninja -C build-arm64 -j 12
if errorlevel 1 (
    echo ERROR: Ninja build failed
    cd ..
    exit /b 1
)

cd build-arm64\meson-out
if exist ui.lib del ui.lib
ren libui.a ui.lib
cd ..\..\..\

echo.
echo Building tray library for ARM64...
cd tray
del /Q *.o *.obj *.a *.lib 2>nul

REM Compile tray with MSVC directly (since vcvarsarm64 is active)
echo Compiling zt_desktop_tray.c with MSVC...
cl /c /O2 /DTRAY_WINAPI=1 /TC /MT zt_desktop_tray.c
if errorlevel 1 (
    echo ERROR: Tray compilation failed
    cd ..
    exit /b 1
)

REM Create static library
echo Creating zt_desktop_tray.lib...
lib /OUT:zt_desktop_tray.lib zt_desktop_tray.obj
if errorlevel 1 (
    echo ERROR: Tray library creation failed
    cd ..
    exit /b 1
)
cd ..

echo.
echo Building Rust ARM64 binary...
set "RUSTFLAGS=-C target-feature=+crt-static"
REM Add LLVM to PATH for clang (required by ring crate for ARM64)
set "PATH=C:\Program Files\LLVM\bin;%PATH%"
REM Set CC to clang for ring crate compilation
set "CC=clang.exe"
cargo build --release --target=aarch64-pc-windows-msvc
if errorlevel 1 (
    echo ERROR: Cargo build failed
    exit /b 1
)

echo.
echo Build complete!
echo Binary location: target\aarch64-pc-windows-msvc\release\zerotier_desktop_ui.exe
