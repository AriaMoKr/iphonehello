# TODO

## Builds

- [ ] **A fixed signing key for Android:** Android installs only signed apps, and each build is signed with a key made for it, so an update installs only after the old app is uninstalled. A keystore in a repository secret fixes that (yours to create); the android job would then sign with it.
  - Google's developer verification: since 2026-09-30, certified Android devices in some regions install apps from participating stores only from verified developers, and Google means to roll it out everywhere in 2027. For an APK shared from GitHub, a free limited distribution account (up to 20 devices, no ID or fee) or Android's "advanced flow" for unverified apps may then be needed. Checked on 2026-10-30.
- [ ] **On real devices:** the Android app on a phone, hello_qt-linux-arm64 on a Raspberry Pi, whose desktop uses Wayland (nothing here tests Wayland), and the Windows apps for ARM64 on an ARM64 PC. So far they have only run in the emulator and on GitHub's runners.
- [ ] **A Linux AppImage:** hello_qt for Linux with Qt inside, like the Windows and macOS apps: one file that runs on most distributions (hello_qt-linux.tar.gz needs the distribution's Qt 6).
  - linuxdeploy with its Qt plugin makes it, or appimagetool. They are AppImages themselves, which want FUSE; `APPIMAGE_EXTRACT_AND_RUN=1` runs them without it.
  - It needs a `.desktop` file and an icon, which the apps don't have yet.
  - An AppImage runs only where glibc is at least as new as where it was built. Built on the ubuntu-22.04 runner (glibc 2.35), with Qt 6.12's own Linux build (built on RHEL 9.6 with glibc 2.34), it would run on Ubuntu 22.04, Debian 12, Fedora 36 and later.
  - An ARM64 one would need Qt 6.12's own ARM64 build (`qt.qt6.6120.linux_gcc_arm64`), which is built on Ubuntu 24.04 and so needs glibc 2.39 or later.

## More builds GitHub Actions could make (not started)

Looked into on 2026-10-30. The runners named here are free for public repositories.

- [ ] **WebAssembly, on GitHub Pages:** hello_qt in a web page, at ariamokr.github.io/iphonehello, with nothing to install. Qt 6.12 for WebAssembly (`qt.qt6.6120.wasm_singlethread`) with Emscripten 5.0.5 and Qt for Linux, published with actions/deploy-pages; Pages has to be turned on in the repository's settings (Source: GitHub Actions). The single-threaded Qt, as the multithreaded one needs response headers (COOP and COEP) that GitHub Pages doesn't send.
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

- [x] **An Android build:** hello_qt-android.apk, one APK for 64-bit and 32-bit ARM and for x86-64, built by GitHub Actions with Qt 6.12 for Android and started in the Android emulator (Android 16), with a screenshot as for the iPhone app.
- [x] **An Intel Mac test:** the macos-intel job starts the macOS app on an Intel Mac (the macos-15-intel runner, with macOS 15). The macos job still starts its Intel half through Rosetta on Apple silicon, with macOS 26.
- [x] **Linux on ARM64:** hello_qt-linux-arm64.tar.gz, for 64-bit Raspberry Pi OS and other ARM64 Linux, built and started (offscreen) on the ubuntu-24.04-arm runner with Ubuntu's Qt. Like the x86-64 one it needs Qt 6 from the distribution (`libqt6widgets6` on Raspberry Pi OS and Debian).
- [x] **Windows on ARM64:** hello-arm64.exe and hello_qt-windows-arm64.zip, built with MSYS2's CLANGARM64 environment (Clang, Qt 6.12) and started natively on the windows-11-arm runner, as the windows job's second leg.
- [x] **Around the releases:** SHA256SUMS and an attestation of each file in every release (actions/attest; `gh attestation verify` checks a download), and CodeQL for the C++ code (codeql.yml).
