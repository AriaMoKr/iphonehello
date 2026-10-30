# Hello World GUI (C++)

Two minimal C++ desktop apps that open a window saying "Hello, World!":

- `hello.cpp` uses only the Win32 API. It runs on Windows only, and `hello.exe` needs no extra DLLs.
- `hello_qt.cpp` uses Qt Widgets, so it also builds on Linux and macOS.

Close the window to quit.

## Win32 version

In an MSYS2 UCRT64 shell (packages `mingw-w64-ucrt-x86_64-gcc` and `make`):

```bash
make
./hello.exe
```

Or without make:

```bash
g++ -O2 -Wall -Wextra -o hello.exe hello.cpp -mwindows
```

## Qt version

Needs a C++ compiler, CMake, and Qt 6 or Qt 5 (Qt 6 is used if both are installed):

- MSYS2 UCRT64: `pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt5-base`
- Debian/Ubuntu: `sudo apt install build-essential cmake qt6-base-dev`
- macOS (Homebrew): `brew install cmake qt`

```bash
cmake -B build
cmake --build build
```

Then run `./build/hello_qt.exe` on Windows, `./build/hello_qt` on Linux, or `open build/hello_qt.app` on macOS.
On Windows, start it from the UCRT64 shell: it needs the Qt and GCC runtime DLLs in `/ucrt64/bin`.

Tested with Qt 5.15 on Windows (MSYS2 UCRT64) and Qt 6.4 on Ubuntu 24.04; not yet on macOS.
