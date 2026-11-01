# TODO

## Builds

- [ ] **A fixed signing key for Android:** Android installs only signed apps, and each build is signed with a key made for it, so an update installs only after the old app is uninstalled. A keystore in a repository secret fixes that (yours to create); the android job would then sign with it.
  - Google's developer verification: since 2026-09-30, certified Android devices in some regions install apps from participating stores only from verified developers, and Google means to roll it out everywhere in 2027. For an APK shared from GitHub, a free limited distribution account (up to 20 devices, no ID or fee) or Android's "advanced flow" for unverified apps may then be needed. Checked on 2026-10-30.
- [ ] **On real devices:** the Android app on a phone, hello_qt-linux-arm64 on a Raspberry Pi, whose desktop uses Wayland (nothing here tests Wayland), the AppImage on a Linux desktop, the Windows apps for ARM64 on an ARM64 PC, and the web page in Firefox and Safari and on phones. So far they have only run in the emulator, in containers and on GitHub's runners, and the web page in Chrome.
- [ ] **An ARM64 AppImage:** like hello_qt-linux.AppImage, with Qt 6.12's own ARM64 build (`qt.qt6.6120.linux_gcc_arm64`). That is built on Ubuntu 24.04 and so needs glibc 2.39 or later: built in a container of Ubuntu 24.04 on the ubuntu-24.04-arm runner, the AppImage would run on Ubuntu 24.04, Debian 13 and Raspberry Pi OS 13, but not on Debian 12 or Raspberry Pi OS 12.
- [ ] **Wayland in the AppImage:** it has only Qt's X11 plugin, so on a Wayland desktop it runs through XWayland. Qt's Wayland plugin comes in qtwayland's archive, which .github/qt.sh doesn't take yet, and linuxdeploy's Qt plugin adds it with `EXTRA_PLATFORM_PLUGINS`; a test would need a Wayland compositor, such as Weston's headless backend.
- [ ] **The icon on the other platforms:** hello_qt.svg is the AppImage's and the web page's icon. The Windows .exe (an .ico in the .rc), the macOS app (an .icns), the iPhone app (an asset catalog) and the Android app (its launcher icons) could have it too, and the window itself (`setWindowIcon`).
- [ ] **Updates for the AppImage:** update information in it (appimagetool's `-u`, with `gh-releases-zsync`) and its .zsync file in the release, so that AppImageUpdate, or AppImageLauncher, can bring it up to date from the latest release.

## More builds GitHub Actions could make (not started)

Looked into on 2026-10-30. The runners named here are free for public repositories.

- [ ] **The Windows Qt app on Qt's own build** instead of MSYS2's: a smaller hello_qt-windows.zip, as MSYS2's Qt brings ICU (15 MB of the zip's 32 MB) and Qt's doesn't. It needs Qt's MinGW 13.1 (`tools_mingw1310`) or MSVC.
- [ ] **Installers and packages:**
  - Windows: a setup program with Inno Setup (6.7) or an .msi with WiX (3.14), both on the Windows runner. An MSIX installs only when signed with a certificate the PC trusts.
  - macOS: a .dmg, made with macOS's own hdiutil. As with the zip, Gatekeeper blocks the first start until the app is notarized.
  - Linux: a .deb and an .rpm with CPack (dpkg-dev and rpm are on ubuntu-24.04), using the distribution's Qt; a Flatpak with flatpak-builder and the KDE runtime, which brings Qt (Flathub reviews what it takes); a Snap with snapcraft.
- [ ] **Signed apps and the stores:** macOS notarization, and TestFlight and the App Store for iPhones (Apple Developer Program, $99 a year); Google Play (a developer account, $25 once); the Microsoft Store (a Partner Center account). Each needs your account, and its keys or certificates in repository secrets.
- [ ] **FreeBSD, OpenBSD and NetBSD:** in a VM on a Linux runner (cross-platform-actions/action or vmactions), with each system's Qt 6 package. Few would download the result.
- [ ] **More Linux architectures** (RISC-V, POWER, IBM Z): Debian with its Qt in containers that QEMU emulates. Slow, and few would download the result.
- [ ] **HarmonyOS:** Qt 6.12 for HarmonyOS (arm64-v8a) is in Qt's online repository; the build would also need Huawei's HarmonyOS SDK. Huawei's phones run it, mostly in China.
- [ ] **Native versions, as hello.exe is for Windows:** SwiftUI for iPhone and Mac (Xcode on the macOS runner), Kotlin for Android (Gradle on the Linux runner), GTK 4 for Linux.

Not possible with Qt's packages: visionOS, tvOS and watchOS, for which Qt's online repository has nothing.

## Done

- [x] **WebAssembly, on GitHub Pages:** hello_qt as a web page, at https://ariamokr.github.io/iphonehello/, with nothing to install, and as hello_qt-wasm.zip in the releases. It is built with Qt 6.12 for WebAssembly, the single-threaded one (the multithreaded one needs response headers, COOP and COEP, that GitHub Pages doesn't send), and Emscripten 5.0.5, then started in Google Chrome (headless, with Playwright) with OCR of a screenshot; the pages job publishes it from main with actions/deploy-pages. The page itself, hello_qt.html, is our own, as Qt's page for the app is under the GPL. Its folder licenses covers Qt, Qt's qtloader.js (GPL-3.0) and Emscripten's runtime.
- [x] **A Linux AppImage:** hello_qt-linux.AppImage, hello_qt for x86-64 Linux in one file with Qt 6.12 inside (Qt's own Linux build), made with linuxdeploy and appimagetool in a container of Ubuntu 22.04, so that it runs with glibc 2.34 or later: on Ubuntu 22.04, Debian 12, RHEL 9 and its rebuilds, Fedora, and their newer versions. It is started on the ubuntu-24.04 runner with FUSE, and without it in containers of Ubuntu 22.04, Debian 12, the newest Fedora and AlmaLinux 9, each time with OCR of the screen. Its folder licenses covers Qt, ICU, Ubuntu's libraries and AppImage's runtime. It brought the Qt app's first `.desktop` file and icon (hello_qt.svg).
- [x] **An Android build:** hello_qt-android.apk, one APK for 64-bit and 32-bit ARM and for x86-64, built by GitHub Actions with Qt 6.12 for Android and started in the Android emulator (Android 16), with a screenshot as for the iPhone app.
- [x] **An Intel Mac test:** the macos-intel job starts the macOS app on an Intel Mac (the macos-15-intel runner, with macOS 15). The macos job still starts its Intel half through Rosetta on Apple silicon, with macOS 26.
- [x] **Linux on ARM64:** hello_qt-linux-arm64.tar.gz, for 64-bit Raspberry Pi OS and other ARM64 Linux, built and started (offscreen) on the ubuntu-24.04-arm runner with Ubuntu's Qt. Like the x86-64 one it needs Qt 6 from the distribution (`libqt6widgets6` on Raspberry Pi OS and Debian).
- [x] **Windows on ARM64:** hello-arm64.exe and hello_qt-windows-arm64.zip, built with MSYS2's CLANGARM64 environment (Clang, Qt 6.12) and started natively on the windows-11-arm runner, as the windows job's second leg.
- [x] **Around the releases:** SHA256SUMS and an attestation of each file in every release (actions/attest; `gh attestation verify` checks a download), and CodeQL for the C++ code (codeql.yml).
