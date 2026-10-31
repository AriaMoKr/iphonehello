#!/bin/sh
# Makes hello_qt-linux.AppImage: hello_qt for x86-64 Linux in one file, with Qt and the other libraries it
# needs, except those that every Linux desktop has (AppImage's excludelist: glibc, libstdc++, OpenGL, libX11
# and libxcb, fontconfig, FreeType and the like). It runs in a container of Ubuntu 22.04, which the
# libraries come from, so that the AppImage needs no newer glibc than 2.35; as none of its parts uses more
# than 2.34 (the notice at the end says), it runs on RHEL 9 and its rebuilds too, besides Ubuntu 22.04,
# Debian 12, Fedora and the like. Run it from the repository's root, with Qt for Linux in qt/gcc_64
# (.github/qt.sh):
#
#   docker run --rm -v "$PWD:/w" -w /w ubuntu:22.04 sh .github/appimage.sh
#
# linuxdeploy and its Qt plugin put hello_qt, Qt's libraries and plugins and the other libraries into the
# folder AppDir, licenses.sh adds their licenses, and appimagetool packs the folder behind AppImage's
# runtime, which mounts it with FUSE when the AppImage starts (or extracts it). The tools are AppImages
# too, and run here without FUSE by extracting themselves.
set -eu
runtime=20251108 # the release of AppImage's runtime
cmake=4.4.5 # Kitware's CMake: Qt 6.12 needs 3.25 or later, and Ubuntu 22.04 has 3.22
export DEBIAN_FRONTEND=noninteractive APPIMAGE_EXTRACT_AND_RUN=1

# The compiler, Ninja and git (for the version); OpenGL's and xkbcommon's headers, which Qt's CMake files
# look for; the libraries that Qt's X11 plugin and Qt D-Bus use, for linuxdeploy to copy or leave to the
# system; rsvg-convert, for the icon; file, which appimagetool runs; and what licenses.sh needs.
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  g++ ninja-build git ca-certificates curl xz-utils jq librsvg2-bin file \
  libgl-dev libegl-dev libxkbcommon-dev \
  libxcb-render0 libxcb-render-util0 libxcb-shape0 libxcb-randr0 libxcb-xfixes0 libxcb-xkb1 libxcb-sync1 \
  libxcb-shm0 libxcb-icccm4 libxcb-keysyms1 libxcb-image0 libxcb-util1 libxcb-cursor0 libxcb-glx0 \
  libxkbcommon-x11-0 libfontconfig1 libfreetype6 libx11-6 libxcb1 libx11-xcb1 libsm6 libice6 \
  libglib2.0-0 libdbus-1-3 > /dev/null
git config --global --add safe.directory "$PWD"

# The tools (linuxdeploy and its Qt plugin, appimagetool, AppImage's runtime and CMake), each checked
# against the SHA-256 of its release
mkdir -p tools
while read -r sum url; do
  curl -fsSL --retry 3 -o "tools/${url##*/}" "$url"
  echo "$sum  tools/${url##*/}" | sha256sum -c --quiet
done <<EOF
c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage
15106be885c1c48a021198e7e1e9a48ce9d02a86dd0a1848f00bdbf3c1c92724 https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/1-alpha-20250213-1/linuxdeploy-plugin-qt-x86_64.AppImage
ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0 https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d https://github.com/AppImage/type2-runtime/releases/download/$runtime/runtime-x86_64
ed85135c5a5135b45e50423cb406dea04ca3338da0b8ef3c9ede963559680be0 https://github.com/Kitware/CMake/releases/download/v$cmake/cmake-$cmake-linux-x86_64.tar.gz
EOF
chmod +x tools/*.AppImage
tar -xzf "tools/cmake-$cmake-linux-x86_64.tar.gz" -C tools
PATH=$PWD/tools/cmake-$cmake-linux-x86_64/bin:$PATH

# hello_qt, and its icon as a PNG, which the AppImage shows (and as the SVG, for desktops that take it)
cmake -B build-appimage -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$PWD/qt/gcc_64"
cmake --build build-appimage
rsvg-convert -w 256 -h 256 -o build-appimage/hello_qt.png hello_qt.svg

# AppDir. linuxdeploy's Qt plugin finds Qt through its qmake. The packages' copyright files go into
# licenses (licenses.sh), not also into usr/share/doc.
rm -rf AppDir
QMAKE=$PWD/qt/gcc_64/bin/qmake LD_LIBRARY_PATH=$PWD/qt/gcc_64/lib DISABLE_COPYRIGHT_FILES_DEPLOYMENT=1 \
  tools/linuxdeploy-x86_64.AppImage --appdir AppDir --executable build-appimage/hello_qt \
  --desktop-file hello_qt.desktop --icon-file build-appimage/hello_qt.png --plugin qt
mkdir -p AppDir/usr/share/icons/hicolor/scalable/apps
cp hello_qt.svg AppDir/usr/share/icons/hicolor/scalable/apps/
sh .github/licenses.sh linux AppDir qt/gcc_64 "$runtime"

# The AppImage, whose desktop file gets hello_qt's version (as CMakeLists.txt has it, from git describe)
version=$(git describe --tags --match 'v[0-9]*.[0-9]*.[0-9]*' 2> /dev/null || echo v0.0.0)
VERSION=${version#v} tools/appimagetool-x86_64.AppImage --runtime-file tools/runtime-x86_64 AppDir \
  hello_qt-linux.AppImage

# What the AppImage needs from the system: the newest glibc and libstdc++ that its programs and libraries
# use, and the libraries it leaves out
elfs=$(find AppDir -type f \( -name '*.so*' -o -path AppDir/usr/bin/hello_qt \))
glibc=$(objdump -T $elfs 2> /dev/null | grep -o 'GLIBC_2\.[0-9]*' | sort -uV | tail -n 1)
glibcxx=$(objdump -T $elfs 2> /dev/null | grep -o 'GLIBCXX_3\.4\.[0-9]*' | sort -uV | tail -n 1)
objdump -p $elfs 2> /dev/null | awk '$1 == "NEEDED" { print $2 }' | LC_ALL=C sort -u > build-appimage/needed
ls AppDir/usr/lib | LC_ALL=C sort > build-appimage/inside
system=$(LC_ALL=C comm -23 build-appimage/needed build-appimage/inside | tr '\n' ' ')
echo "::notice title=hello_qt-linux.AppImage::$(du -h hello_qt-linux.AppImage | cut -f 1), with" \
  "$(wc -l < build-appimage/inside) libraries inside. From the system it needs $glibc, $glibcxx and $system"

# What the container made belongs to whoever has the repository, not to the container's root
chown -R "$(stat -c %u:%g .)" tools build-appimage AppDir hello_qt-linux.AppImage
