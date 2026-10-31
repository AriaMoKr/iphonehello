# Hello World GUI (C++)

Two minimal C++ GUI apps that open a window saying "Hello, World!":

- `hello.cpp` uses only the Win32 API. It runs on Windows only, and `hello.exe` needs no extra DLLs.
- `hello_qt.cpp` uses Qt Widgets, so it also builds on Linux, macOS, iOS and Android.

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

The Windows, macOS, iPhone and Android downloads of the Qt app have Qt inside, and the Windows and Android ones
other libraries too. Their licenses are in a folder `licenses`, whose `README.txt` says what each part is and
where its source code is: `hello_qt\licenses`, `hello_qt.app/Contents/Resources/licenses`,
`hello_qt.app/licenses`, and `assets/licenses` in the APK (an APK is a zip).

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

## Qt version

Needs a C++ compiler, CMake, and Qt 6 or Qt 5 (Qt 6 is used if both are installed):

- MSYS2 UCRT64: `pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-git mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt6-base`
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

Tested with Qt 6.12 on Windows 11 (MSYS2 UCRT64; Qt 5.15 works too) and Qt 6.4 on Ubuntu 24.04. On macOS, iOS
and Android it has only been built and started by GitHub Actions (Qt 6.12; for Intel Macs through Rosetta, for
iOS in the iPhone Simulator, for Android in the Android emulator), not yet tried on a Mac, an iPhone or an
Android phone.

## Version

The apps carry the version of the newest tag `v<version>` at or before their commit, as `git describe` gives
it: `0.5.0` on the commit tagged `v0.5.0`, and `0.5.0-3-g<commit>` three commits later. make reads it each time
it runs, CMake when it configures the build. Without git or the tags, as in a source code zip, it is `0.0.0`.
Windows shows it in the file's Properties → Details, macOS in Get Info, the iPhone in Settings → General →
iPhone Storage, and Android at the bottom of the app's page in Settings → Apps. Apple's versions are only
numbers, so there a build after `0.5.0` still says `0.5.0`.

## License

[MIT](LICENSE). The Qt app's downloads for Windows, macOS, iPhone and Android also contain Qt, under the
GNU LGPL version 3, and code from other projects, each under its own license: see their `licenses` folder
([Download](#download)).
