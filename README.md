# Hello World GUI (C++)

Two minimal C++ GUI apps that open a window saying "Hello, World!":

- `hello.cpp` uses only the Win32 API. It runs on Windows only, and `hello.exe` needs no extra DLLs.
- `hello_qt.cpp` uses Qt Widgets, so it also builds on Linux, macOS and iOS.

Close the window to quit.

## Download

GitHub Actions builds both apps whenever their code changes on `main` and attaches them to the
[`latest`](https://github.com/AriaMoKr/iphonehello/releases/tag/latest) prerelease, so these links
always get the newest build. A tag like `v1.0.0` gets a release of its own.

- Windows: [hello.exe](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello.exe) runs as it is.
  For [hello_qt-windows.zip](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-windows.zip),
  unzip it and run `hello_qt\hello_qt.exe`.
- Linux (x86-64): [hello_qt-linux.tar.gz](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-linux.tar.gz)
  holds `hello_qt`, which needs Qt 6 (Ubuntu 24.04: `sudo apt install libqt6widgets6t64`).
- macOS 15 or later (Apple silicon): [hello_qt-macos.zip](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-macos.zip)
  holds `hello_qt.app`. It isn't notarized, so after unzipping it run
  `xattr -dr com.apple.quarantine hello_qt.app` once, or allow it in System Settings → Privacy & Security.
- iPhone and iPad (iOS 18 or later): [hello_qt-ios.ipa](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-ios.ipa)
  holds `hello_qt.app`, unsigned. An iPhone installs only apps signed for it, so a sideloading tool such as
  AltStore or Sideloadly has to sign it with your Apple Account first; with a free account it then runs for
  7 days. Or build it yourself with Xcode (below). So far it has only run in the iPhone Simulator
  ([screenshot](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-ios-simulator.png)).

The Windows, macOS and iPhone downloads of the Qt app have Qt and other libraries inside. Their licenses are in
a folder `licenses`, whose `README.txt` says what each part is and where its source code is: `hello_qt\licenses`,
`hello_qt.app/Contents/Resources/licenses` and `hello_qt.app/licenses`.

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

- MSYS2 UCRT64: `pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt6-base`
- Debian/Ubuntu: `sudo apt install build-essential cmake qt6-base-dev`
- macOS (Homebrew): `brew install cmake qtbase`

```bash
cmake -B build
cmake --build build
```

Then run `./build/hello_qt.exe` on Windows, `./build/hello_qt` on Linux, or `open build/hello_qt.app` on macOS.
On Windows, start it from the UCRT64 shell: it needs the Qt and GCC runtime DLLs in `/ucrt64/bin`.

For iPhone you need a Mac with Xcode, and Qt for iOS from Qt's installer, which needs a Qt account
([build.yml](.github/workflows/build.yml) shows how GitHub Actions gets Qt without one). Qt for iOS comes
twice, for the Simulator (`ios_simulator_arm64`) and for iPhones (`ios_device`): configure with the one for
where the app will run, then run it from Xcode.

```bash
~/Qt/6.12.0/ios_simulator_arm64/bin/qt-cmake -G Xcode -B build-ios
open build-ios/hello_qt.xcodeproj
```

On an iPhone, Xcode signs the app with your Apple Account (Signing & Capabilities → Team), and the iPhone needs
Developer Mode on (Settings → Privacy & Security).

Tested with Qt 6.12 on Windows 11 (MSYS2 UCRT64; Qt 5.15 works too) and Qt 6.4 on Ubuntu 24.04. On macOS and
iOS it has only been built and started by GitHub Actions (Qt 6.12; on iOS in the iPhone Simulator), not yet
tried on a Mac or an iPhone.

## License

[MIT](LICENSE). The Qt app's downloads for Windows, macOS and iPhone also contain Qt, under the GNU LGPL
version 3, and other libraries, each under its own license: see their `licenses` folder ([Download](#download)).
