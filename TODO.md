# TODO

## Builds

- [ ] **An Android build:** hello_qt as an APK for Android phones, tablets and Chromebooks, built and tested by GitHub Actions like the iPhone app.
  - Qt 6.12 for Android is in Qt's online repository (`all_os/android/qt6_6120/`, a package for each ABI: arm64-v8a, armeabi-v7a, x86_64 and x86). The build also needs Qt for Linux, whose tools it runs, the Android SDK, the NDK r27 and JDK 21, which the ubuntu-24.04 runner has (NDK 27.3). `.github/qt.sh` only knows Qt's `mac_x64` folder so far.
  - Smoke test: the x86_64 APK in the Android emulator, which runs with KVM on the Linux runners, with a screenshot as for the iPhone app.
  - Android installs only signed apps, and without a fixed key each build is signed with a new debug key, so an update installs only after the old app is uninstalled. A keystore in a repository secret fixes that (yours to create).
  - Google's developer verification: since 2026-09-30, certified Android devices in some regions install apps from participating stores only from verified developers, and Google means to roll it out everywhere in 2027. For an APK shared from GitHub, a free limited distribution account (up to 20 devices, no ID or fee) or Android's "advanced flow" for unverified apps may then be needed. Checked on 2026-10-30.
- [ ] **A Linux AppImage:** hello_qt for Linux with Qt inside, like the Windows and macOS apps: one file that runs on most distributions (hello_qt-linux.tar.gz needs the distribution's Qt 6).
  - linuxdeploy with its Qt plugin makes it, or appimagetool. They are AppImages themselves, which want FUSE; `APPIMAGE_EXTRACT_AND_RUN=1` runs them without it.
  - It needs a `.desktop` file and an icon, which the apps don't have yet.
  - An AppImage runs only where glibc is at least as new as where it was built. Built on the ubuntu-22.04 runner (glibc 2.35), with Qt 6.12's own Linux build (built on RHEL 9.6 with glibc 2.34), it would run on Ubuntu 22.04, Debian 12, Fedora 36 and later.

## More builds GitHub Actions could make (not started)

Looked into on 2026-10-30. The runners named here are free for public repositories.

- [ ] **WebAssembly, on GitHub Pages:** hello_qt in a web page, at ariamokr.github.io/iphonehello, with nothing to install. Qt 6.12 for WebAssembly (`qt.qt6.6120.wasm_singlethread`) with Emscripten 5.0.5 and Qt for Linux, published with actions/deploy-pages; Pages has to be turned on in the repository's settings (Source: GitHub Actions). The single-threaded Qt, as the multithreaded one needs response headers (COOP and COEP) that GitHub Pages doesn't send.
- [ ] **Linux on ARM64** (64-bit Raspberry Pi OS on a Raspberry Pi 4 or 5, ARM laptops and servers): the ubuntu-24.04-arm runner, with the distribution's Qt, or Qt 6.12's own ARM64 build (`qt.qt6.6120.linux_gcc_arm64`, built on Ubuntu 24.04, so it needs glibc 2.39 or later). A tarball like the x86-64 one, or an ARM64 AppImage.
- [ ] **Windows on ARM64:** the windows-11-arm runner. hello.exe with MSYS2's CLANGARM64 environment (setup-msys2 has it), hello_qt with MSYS2's Qt there (6.11.2 for now) or Qt 6.12's own MSVC build for ARM64. The x64 apps already run on ARM64 Windows through its emulation; these would run natively.
- [ ] **The Windows Qt app on Qt's own build** instead of MSYS2's: a smaller hello_qt-windows.zip, as MSYS2's Qt brings ICU (15 MB of the zip's 32 MB) and Qt's doesn't. It needs Qt's MinGW 13.1 (`tools_mingw1310`) or MSVC.
- [ ] **Installers and packages:**
  - Windows: a setup program with Inno Setup (6.7) or an .msi with WiX (3.14), both on the Windows runner. An MSIX installs only when signed with a certificate the PC trusts.
  - macOS: a .dmg, made with macOS's own hdiutil. As with the zip, Gatekeeper blocks the first start until the app is notarized.
  - Linux: a .deb and an .rpm with CPack (dpkg-dev and rpm are on ubuntu-24.04), using the distribution's Qt; a Flatpak with flatpak-builder and the KDE runtime, which brings Qt (Flathub reviews what it takes); a Snap with snapcraft.
- [ ] **An Intel Mac test:** the macOS app's Intel half is tested through Rosetta on Apple silicon; the macos-15-intel or macos-26-intel runner would start it on a real Intel Mac.
- [ ] **Signed apps and the stores:** macOS notarization, and TestFlight and the App Store for iPhones (Apple Developer Program, $99 a year); Google Play (a developer account, $25 once); the Microsoft Store (a Partner Center account). Each needs your account, and its keys or certificates in repository secrets.
- [ ] **FreeBSD, OpenBSD and NetBSD:** in a VM on a Linux runner (cross-platform-actions/action or vmactions), with each system's Qt 6 package. Few would download the result.
- [ ] **More Linux architectures** (RISC-V, POWER, IBM Z): Debian with its Qt in containers that QEMU emulates. Slow, and few would download the result.
- [ ] **HarmonyOS:** Qt 6.12 for HarmonyOS (arm64-v8a) is in Qt's online repository; the build would also need Huawei's HarmonyOS SDK. Huawei's phones run it, mostly in China.
- [ ] **Native versions, as hello.exe is for Windows:** SwiftUI for iPhone and Mac (Xcode on the macOS runner), Kotlin for Android (Gradle on the Linux runner), GTK 4 for Linux.
- [ ] **Around the releases:** SHA-256 checksums and artifact attestations (actions/attest-build-provenance; `gh attestation verify` checks a download), and CodeQL for the C++ code.

Not possible with Qt's packages: visionOS, tvOS and watchOS, for which Qt's online repository has nothing.
