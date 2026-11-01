# Hello World GUI (C++)

Two minimal C++ GUI apps that open a window saying "Hello, World!":

- `hello.cpp` uses only the Win32 API. It runs on Windows only, and `hello.exe` needs no extra DLLs.
- `hello_qt.cpp` uses Qt Widgets, so it also builds on Linux, macOS, iOS and Android, and as a web page
  (WebAssembly).

Close the window to quit.

## Download

GitHub Actions builds both apps whenever their code changes on `main` and attaches them to the
[`latest`](https://github.com/AriaMoKr/iphonehello/releases/tag/latest) prerelease, so these links
always get the newest build. A tag like `v1.0.0` gets a release of its own.

- Windows: [hello.exe](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello.exe) runs as it is.
  For [hello_qt-windows.zip](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-windows.zip),
  unzip it and run `hello_qt\hello_qt.exe`.
- Windows on ARM64: [hello-arm64.exe](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello-arm64.exe)
  and [hello_qt-windows-arm64.zip](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-windows-arm64.zip)
  are the same apps built for ARM64, so they run natively (the x64 ones run there too, emulated).
- Linux (x86-64): [hello_qt-linux.AppImage](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-linux.AppImage)
  has Qt inside and runs on most distributions with glibc 2.34 or later, such as Ubuntu 22.04, Debian 12,
  RHEL 9 (and AlmaLinux and Rocky Linux 9), Fedora, and their newer versions, on X11 or, through XWayland, on
  Wayland. Make it executable, then start it:
  `chmod +x hello_qt-linux.AppImage && ./hello_qt-linux.AppImage`. It mounts itself with FUSE, which desktops
  have; without FUSE, as in a container, add `--appimage-extract-and-run`.
  [hello_qt-linux.tar.gz](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-linux.tar.gz)
  holds just `hello_qt`, which needs Qt 6 (Ubuntu 24.04: `sudo apt install libqt6widgets6t64`).
- Linux (ARM64, such as 64-bit Raspberry Pi OS on a Raspberry Pi 4 or 5): [hello_qt-linux-arm64.tar.gz](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-linux-arm64.tar.gz)
  holds `hello_qt`, which needs Qt 6 (Raspberry Pi OS and Debian 12 or 13: `sudo apt install libqt6widgets6`;
  Ubuntu 24.04: `sudo apt install libqt6widgets6t64`). So far it has only run on GitHub's ARM64 runner, not yet
  on a Raspberry Pi.
- macOS 14.4 or later (Apple silicon or Intel): [hello_qt-macos.zip](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-macos.zip)
  holds `hello_qt.app`. It isn't notarized, so after unzipping it run
  `xattr -dr com.apple.quarantine hello_qt.app` once, or allow it in System Settings → Privacy & Security.
- iPhone and iPad (iOS 18 or later): [hello_qt-ios.ipa](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-ios.ipa)
  holds `hello_qt.app`, unsigned. An iPhone installs only apps signed for it, so a sideloading tool such as
  AltStore or Sideloadly has to sign it with your Apple Account first; with a free account it then runs for
  7 days. Or build it yourself with Xcode (below). So far it has only run in the iPhone Simulator
  ([screenshot](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-ios-simulator.png)).
- Android 9 or later (phones and tablets with ARM, and x86-64 ones such as some Chromebooks):
  [hello_qt-android.apk](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-android.apk).
  Open it on the phone, and when Android asks, allow the browser or file manager to install apps. Each build is
  signed with a key made for it, so before installing a newer build, uninstall the old one. So far it has only
  run in the Android emulator
  ([screenshot](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-android-emulator.png)).
- In a web browser, with nothing to install: [ariamokr.github.io/iphonehello](https://ariamokr.github.io/iphonehello/)
  runs the Qt app, built for WebAssembly, and a push to `main` puts the newest build there. Qt for WebAssembly is
  made for Chrome, Edge, Firefox and Safari, on phones too. [hello_qt-wasm.zip](https://github.com/AriaMoKr/iphonehello/releases/download/latest/hello_qt-wasm.zip)
  holds the same page, for a web server of your own. A browser runs it only from a web server, not from a file
  on disk; to try it on your computer, unzip it and start a local one in its folder, such as
  `python3 -m http.server`, then open http://localhost:8000/. So far it has only run in Chromium-based
  browsers, on Linux and Windows.

The Windows, Linux AppImage, macOS, iPhone, Android and web downloads of the Qt app have Qt inside, and the
Windows, AppImage, Android and web ones other libraries too. Their licenses are in a folder `licenses`, whose
`README.txt` says what each part is and where its source code is: `hello_qt\licenses`, `licenses` in the
AppImage (`./hello_qt-linux.AppImage --appimage-extract 'licenses/*'` copies it into the folder
`squashfs-root`), `hello_qt.app/Contents/Resources/licenses`, `hello_qt.app/licenses`, `assets/licenses` in the
APK (an APK is a zip), and `licenses` beside the web page
([README.txt](https://ariamokr.github.io/iphonehello/licenses/README.txt) on GitHub Pages).

### Checking a download

Each release also has [SHA256SUMS](https://github.com/AriaMoKr/iphonehello/releases/download/latest/SHA256SUMS),
the SHA-256 checksums of its files. In a folder with SHA256SUMS and your downloads, this checks them (on macOS:
`shasum -a 256 -c --ignore-missing SHA256SUMS`):

```bash
sha256sum -c --ignore-missing SHA256SUMS
```

GitHub also keeps an attestation of each file, signed with [Sigstore](https://www.sigstore.dev/), which says
that this repository's workflow built it and from which commit. The [GitHub CLI](https://cli.github.com/)
checks a download against it (once signed in with `gh auth login`):

```bash
gh attestation verify hello.exe --repo AriaMoKr/iphonehello
```

## Win32 version

In an MSYS2 UCRT64 shell (packages `mingw-w64-ucrt-x86_64-gcc`, `make`, and `mingw-w64-ucrt-x86_64-git` for
the [version](#version)):

```bash
make
./hello.exe
```

Or without make, and without a version:

```bash
g++ -O2 -Wall -Wextra -o hello.exe hello.cpp -mwindows
```

On Windows on ARM64, MSYS2's CLANGARM64 environment has Clang instead of GCC. In its shell (packages
`mingw-w64-clang-aarch64-clang`, `make`, and `mingw-w64-clang-aarch64-git`), run `make CXX=clang++`, or
`clang++` instead of `g++` above.

## Qt version

Needs a C++ compiler, CMake, and Qt 6 or Qt 5 (Qt 6 is used if both are installed):

- MSYS2 UCRT64: `pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-git mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt6-base`
- MSYS2 CLANGARM64 (Windows on ARM64): `pacman -S --needed mingw-w64-clang-aarch64-clang mingw-w64-clang-aarch64-git mingw-w64-clang-aarch64-cmake mingw-w64-clang-aarch64-ninja mingw-w64-clang-aarch64-qt6-base`
- Debian/Ubuntu: `sudo apt install build-essential cmake qt6-base-dev`
- macOS (Homebrew): `brew install cmake qtbase`

```bash
cmake -B build
cmake --build build
```

Then run `./build/hello_qt.exe` on Windows, `./build/hello_qt` on Linux, or `open build/hello_qt.app` on macOS.
On Windows, start it from the UCRT64 shell (CLANGARM64 on ARM64): it needs the Qt and C++ runtime DLLs in
`/ucrt64/bin` (`/clangarm64/bin`).

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

For Android you need Qt for Android and Qt for your computer from Qt's installer, the Android SDK with the
platform for Android 16 (API level 36) and the NDK r27 (Android Studio's SDK Manager installs them), and JDK 21.
Configure with the Qt for Android of your phone's processor (`android_arm64_v8a` for most phones) and the
SDK's folder, then build the APK and install it with adb (the phone needs USB debugging on):

```bash
~/Qt/6.12.0/android_arm64_v8a/bin/qt-cmake -G Ninja -B build-android -DANDROID_SDK_ROOT=$HOME/Android/Sdk \
  -DANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/27.2.12479018
cmake --build build-android --target apk
adb install build-android/android-build/hello_qt.apk
```

That makes a debug build, which Gradle signs with your own debug key. GitHub Actions makes a release build, for
three processors in one APK ([build.yml](.github/workflows/build.yml)).

The AppImage is made in a container of Ubuntu 22.04, so that it runs with an older glibc too, with Qt from
Qt's online repository, [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) and its Qt plugin, and
[appimagetool](https://github.com/AppImage/appimagetool) ([appimage.sh](.github/appimage.sh)). On Linux with
Docker, xmllint and 7-Zip (Ubuntu 24.04: `sudo apt install docker.io libxml2-utils 7zip`), from the
repository's root:

```bash
sh .github/qt.sh linux_x64/desktop/qt6_6120/qt6_6120 qt.qt6.6120.linux_gcc_64 qt/gcc_64
docker run --rm -v "$PWD:/w" -w /w ubuntu:22.04 sh .github/appimage.sh
```

For the web page you need CMake and Ninja, Qt for WebAssembly (the single-threaded one, `wasm_singlethread`)
and Qt for your computer from Qt's installer, and Emscripten 5.0.5, the version that Qt 6.12 is made for, from
Emscripten's SDK manager [emsdk](https://emscripten.org/docs/getting_started/downloads.html). On Linux or macOS
(on Windows, in WSL), with emsdk's environment set up, Qt's toolchain file finds Emscripten; `QT_HOST_PATH` is
the Qt for your computer (on macOS `~/Qt/6.12.0/macos`):

```bash
git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
~/emsdk/emsdk install 5.0.5 && ~/emsdk/emsdk activate 5.0.5
. ~/emsdk/emsdk_env.sh
cmake -G Ninja -B build-wasm -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=$HOME/Qt/6.12.0/wasm_singlethread/lib/cmake/Qt6/qt.toolchain.cmake \
  -DQT_HOST_PATH=$HOME/Qt/6.12.0/gcc_64
cmake --build build-wasm
python3 -m http.server -d build-wasm
```

Then open http://localhost:8000/hello_qt.html, the page that Qt makes for the app. GitHub Pages has
[hello_qt.html](hello_qt.html) from here instead, as `index.html`, with the app's icon and links to its source
code and licenses ([build.yml](.github/workflows/build.yml)).

Tested with Qt 6.12 on Windows 11 (MSYS2 UCRT64; Qt 5.15 works too) and Qt 6.4 on Ubuntu 24.04. On macOS, iOS
and Android it has only been built and started by GitHub Actions (Qt 6.12; for macOS on Apple silicon with
macOS 26 and on an Intel Mac with macOS 15, for iOS in the iPhone Simulator, for Android in the Android
emulator), not yet tried by hand on a Mac, an iPhone or an Android phone. The ARM64 builds for Windows (MSYS2
CLANGARM64, Qt 6.12) and Linux have likewise only run on GitHub's ARM64 runners, not yet on an ARM64 PC or a
Raspberry Pi, and the AppImage only on GitHub's Ubuntu 24.04 runner (with FUSE) and in containers of Ubuntu
22.04, Debian 12, the newest Fedora and AlmaLinux 9, each with an X server but no desktop. The web page has only
run in Chromium-based browsers so far, on GitHub's Ubuntu 24.04 runner (Google Chrome, headless) and on Windows
11, not yet in Firefox or Safari, or on a phone.

## Version

The apps carry the version of the newest tag `v<version>` at or before their commit, as `git describe` gives
it: `0.5.0` on the commit tagged `v0.5.0`, and `0.5.0-3-g<commit>` three commits later. make reads it each time
it runs, CMake when it configures the build. Without git or the tags, as in a source code zip, it is `0.0.0`.
Windows shows it in the file's Properties → Details, macOS in Get Info, the iPhone in Settings → General →
iPhone Storage, and Android at the bottom of the app's page in Settings → Apps. Apple's versions are only
numbers, so there a build after `0.5.0` still says `0.5.0`.

## License

[MIT](LICENSE). The Qt app's downloads for Windows, Linux (the AppImage), macOS, iPhone and Android, and its
web page, also contain Qt, under the GNU LGPL version 3, and code from other projects, each under its own
license: see their `licenses` folder ([Download](#download)). The web page's `qtloader.js`, which starts the
app, comes from Qt under the GNU GPL version 3.
