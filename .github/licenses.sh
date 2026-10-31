#!/bin/sh
# Puts a licenses folder into a bundle of the Qt app: each part's license files in a folder named after
# it, and README.txt, which says what each part is, its license, and where its source code is. Run it
# from the repository's root once the bundle is complete (on macOS, before the app is signed):
#
#   sh .github/licenses.sh windows hello_qt                MSYS2's Qt and DLLs, into hello_qt/licenses
#   sh .github/licenses.sh macos hello_qt.app qt/macos     Qt for macOS from that folder, into
#                                                          hello_qt.app/Contents/Resources/licenses
#   sh .github/licenses.sh ios hello_qt.app qt/ios_device  Qt for iOS from that folder, into
#                                                          hello_qt.app/licenses
#   sh .github/licenses.sh android hello_qt.apk build/android-build qt/android_arm64_v8a
#       Qt for Android from that folder, the NDK's libc++, and the libraries that the Gradle project
#       (androiddeployqt's android-build) compiled in with Qt's Java code, into the APK's assets/licenses
#
# Qt's license texts, and the list of code from other projects inside Qt, come from Qt's source code.
set -eu

platform=$1
app=$2
repo=${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-AriaMoKr/iphonehello}
commit=${GITHUB_SHA:-$(git rev-parse HEAD)}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
case $platform in
  windows) lic=$app/licenses what="the folder ${app##*/}" ;;
  macos) lic=$app/Contents/Resources/licenses what=${app##*/} ;;
  ios) lic=$app/licenses what=${app##*/} ;;
  android) lic=$tmp/apk/assets/licenses what="this APK" ;; # zipped into the APK at the end
  *) echo "usage: $0 windows <folder>, $0 macos|ios <app> <its Qt>, or $0 android <APK> <its Gradle project> <its Qt>" >&2
     exit 2 ;;
esac
mkdir -p "$lic/hello_qt" "$lic/Qt"
cp LICENSE "$lic/hello_qt/"
cat > "$lic/README.txt" <<EOF
hello_qt, built from $repo at commit $commit.

The parts of $what, each with its license and where its source code is. The license files of each
part are in the folder here that is named after it.

EOF

# qt <version>: Qt's license texts into Qt/, and into Qt/THIRD-PARTY.txt the code from other projects
# that Qt Core, Qt GUI and Qt Widgets can contain, as the qt_attribution.json files in Qt's source code
# list it. Sets qtsrc, where that source code is.
qt() {
  src=qtbase-everywhere-src-$1
  qtsrc=https://download.qt.io/archive/qt/${1%.*}/$1/submodules/$src.tar.xz
  curl -fsSL --retry 3 -o "$tmp/$src.tar.xz" "$qtsrc"
  tar -tJf "$tmp/$src.tar.xz" | grep -E '/LICENSES/[^/]+$|/qt_attribution\.json$|/COPYRIGHT[^/]*$' > "$tmp/files"
  tar -xJf "$tmp/$src.tar.xz" -C "$tmp" -T "$tmp/files"
  cp "$tmp/$src"/LICENSES/* "$lic/Qt/"
  # A few of the files break strings over lines, which jq doesn't read: those line breaks become \n (a line
  # with an odd number of quotes, not counting escaped ones, starts or ends a string).
  for f in $(grep 'qt_attribution\.json$' "$tmp/files"); do
    awk '{ sub(/\r$/, ""); t = $0; gsub(/\\./, "", t); q = gsub(/"/, "", t)
           buf = open ? buf "\\n" $0 : $0
           if (q % 2) open = !open
           if (!open) print buf }' "$tmp/$f" |
      jq -c --arg dir "$tmp/${f%/*}" 'if type == "array" then .[] else . end
      | select((.QDocModule | IN("qtcore", "qtgui", "qtwidgets", "qtdbus", "qtsvg"))
        and ((.QtParts // ["libs"]) | index("libs")))
      | .dir = $dir'
  done > "$tmp/attributions"
  jq -rs 'sort_by(.Name | ascii_downcase)[]
    | "\(.Name)\(if .Version then " \(.Version)" else "" end) (\(.LicenseId // .License))",
      (.Homepage // empty), (.QtUsage // empty),
      if .Copyright then .Copyright | if type == "array" then .[] else . end
      elif .CopyrightFile then "@include \(.dir)/\(.CopyrightFile)"
      else empty end,
      ""' "$tmp/attributions" > "$tmp/third-party"
  {
    echo "Code from other projects that Qt $1's Qt Core, Qt GUI and Qt Widgets can contain, as Qt's"
    echo "source code lists it, with the license of each (the texts are in this folder). Each says where"
    echo "Qt uses it: some of it only on other platforms, or only when there is no separate library for it."
    echo
    while IFS= read -r line; do
      case $line in
        '@include '*) cat "${line#@include }" ;;
        *) printf '%s\n' "$line" ;;
      esac
    done < "$tmp/third-party"
  } > "$lic/Qt/THIRD-PARTY.txt"
}

case $platform in
windows)
  # Each DLL's MSYS2 package: the DLLs next to hello_qt.exe are copies from bin, the others Qt's plugins.
  for f in $(cd "$app" && find . -name '*.dll' | sed 's,^\./,,' | LC_ALL=C sort); do
    case $f in
      */*) p=$(pacman -Qqo "$MINGW_PREFIX/share/qt6/plugins/$f") ;;
      *) p=$(pacman -Qqo "$MINGW_PREFIX/bin/$f") ;;
    esac
    echo "$p $f"
  done > "$tmp/dlls"
  qtpkg=$(pacman -Qqo "$MINGW_PREFIX/bin/Qt6Core.dll")
  qtv=$(pacman -Q "$qtpkg" | cut -d' ' -f2)
  qt "${qtv%-*}"

  # The other packages, and MinGW-w64's runtime (crt), parts of which every .exe and .dll here contain
  crt=$(pacman -Qqo "$MINGW_PREFIX/lib/crt2.o")
  for p in $( { cut -d' ' -f1 "$tmp/dlls"; echo "$crt"; } | LC_ALL=C sort -u); do
    if [ "$p" = "$qtpkg" ]; then
      continue
    fi
    name=${p#"$MINGW_PACKAGE_PREFIX"-}
    v=$(pacman -Q "$p" | cut -d' ' -f2)
    base=$(pacman -Sddp --print-format %e "$p")
    # pacman puts two spaces between licenses
    license=$(LC_ALL=C pacman -Qi "$p" | sed -n 's/^Licenses *: //p' | sed 's/spdx://g; s/  /; /g')
    # Its license files: the ones in share/licenses, or else (ICU) the ones named like license files
    files=$(pacman -Qlq "$p" | grep "^$MINGW_PREFIX/share/licenses/.*[^/]\$" ||
      pacman -Qlq "$p" | grep -E '/(LICEN[CS]E|COPYING)[^/]*$') || {
      echo "::error::$p has no license files"
      exit 1
    }
    for f in $files; do
      case $f in
        "$MINGW_PREFIX"/share/licenses/*) to=$lic/$name/${f#"$MINGW_PREFIX"/share/licenses/*/} ;;
        *) to=$lic/$name/${f##*/} ;;
      esac
      mkdir -p "${to%/*}"
      cp "$f" "$to"
    done
    dlls=$(awk -v p="$p" '$1 == p { printf "%s%s", s, $2; s = ", " }' "$tmp/dlls")
    echo "  $name $v, $license${dlls:+: $dlls}"
    echo "    https://repo.msys2.org/mingw/sources/$base-$v.src.tar.zst"
  done > "$tmp/packages"

  qtname=${qtpkg#"$MINGW_PACKAGE_PREFIX"-}
  qtbase=$(pacman -Sddp --print-format %e "$qtpkg")
  qtfiles=$(awk -v p="$qtpkg" '$1 == p { printf "%s%s", s, $2; s = ", " }' "$tmp/dlls")
  cat >> "$lic/README.txt" <<EOF
hello_qt.exe: hello_qt, under the MIT License. Source code: $repo

$qtfiles:
Qt ${qtv%-*} from MSYS2's package $qtname $qtv, under the GNU Lesser General Public License version 3
(Qt/LGPL-3.0-only.txt, which adds to Qt/GPL-3.0-only.txt). Qt contains code from other projects, listed in
Qt/THIRD-PARTY.txt. You may replace these files with your own build of Qt ${qtv%.*}. Source code, and
MSYS2's build of it:
  $qtsrc
  https://repo.msys2.org/mingw/sources/$qtbase-$qtv.src.tar.zst

The other DLLs come from these MSYS2 packages, whose source code is at the address below each. Every .exe
and .dll here also contains parts of MinGW-w64's runtime, the package crt, whose notices are in
crt/COPYING.MinGW-w64-runtime.txt.
EOF
  cat "$tmp/packages" >> "$lic/README.txt"
  ;;

macos)
  # Qt for macOS comes with no other libraries: everything in Contents/Frameworks is part of Qt
  qtfiles=
  for f in "$app"/Contents/Frameworks/*; do
    case ${f##*/} in
      Qt*.framework) qtfiles=${qtfiles:+$qtfiles, }${f##*/} ;;
      *) echo "::error::${f##*/} in Contents/Frameworks isn't part of Qt"; exit 1 ;;
    esac
  done
  qtv=$(sed -n 's/^QT_VERSION = //p' "$3/mkspecs/qconfig.pri")
  qt "$qtv"
  cat >> "$lic/README.txt" <<EOF
Contents/MacOS/hello_qt: hello_qt, under the MIT License. Source code: $repo

$qtfiles in Contents/Frameworks, and the plugins in Contents/PlugIns:
Qt $qtv for macOS, from Qt's online repository (built by The Qt Company), under the GNU Lesser General
Public License version 3 (Qt/LGPL-3.0-only.txt, which adds to Qt/GPL-3.0-only.txt). Qt contains code from
other projects, listed in Qt/THIRD-PARTY.txt. You may replace these files with your own build of Qt
${qtv%.*}, then sign the app again (codesign --force --deep --sign - hello_qt.app). Qt's source code:
  $qtsrc
EOF
  ;;

ios)
  qtv=$(sed -n 's/^QT_VERSION = //p' "$3/mkspecs/qconfig.pri")
  qt "$qtv"
  cat >> "$lic/README.txt" <<EOF
hello_qt, the app's program: hello_qt, under the MIT License. Source code: $repo

It contains Qt $qtv for iOS, from Qt's online repository (built by The Qt Company) and linked in
statically, under the GNU Lesser General Public License version 3 (Qt/LGPL-3.0-only.txt, which adds to
Qt/GPL-3.0-only.txt). Qt contains code from other projects, listed in Qt/THIRD-PARTY.txt. To use your own
build of Qt instead, build the app from its source code with it (its README says how). Qt's source code:
  $qtsrc
EOF
  ;;

android)
  # The APK's native libraries are hello_qt, Qt's libraries and plugins, and the NDK's C++ library
  for f in $(unzip -Z1 "$app" 'lib/*'); do
    case ${f##*/} in
      libhello_qt_*.so | libQt6*.so | libplugins_*.so | libc++_shared.so) ;;
      *) echo "::error::$f in the APK is neither hello_qt, Qt nor libc++"; exit 1 ;;
    esac
  done
  qtv=$(sed -n 's/^QT_VERSION = //p' "$4/mkspecs/qconfig.pri")
  qt "$qtv"

  # libc++ comes from the NDK that built the app, with Android's build of LLVM (AndroidVersion.txt: its
  # version, then the LLVM revision it is based on). Its license is LLVM's, as in LLVM's source code.
  ndk=$ANDROID_NDK_ROOT
  ndkv=$(sed -n 's/^Pkg\.Revision *= *//p' "$ndk/source.properties")
  llvm=$(sed -n 1p "$ndk/toolchains/llvm/prebuilt/linux-x86_64/AndroidVersion.txt")
  mkdir -p "$lic/libc++"
  curl -fsSL --retry 3 -o "$lic/libc++/LICENSE.TXT" \
    "https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-${llvm%%.*}.1.0/libcxx/LICENSE.TXT"

  # The libraries that Gradle compiled into the APK along with Qt's Java code: the release build's runtime
  # classpath, with the versions Gradle settled on (after ->), but without BOMs (lists of versions, no
  # code), and the license and source code address that each one's Maven POM names, or else the nearest
  # parent POM that does. They are all under the Apache License 2.0 so far.
  if ! (cd "$3" && ./gradlew -q dependencies --configuration releaseRuntimeClasspath) > "$tmp/gradle" 2>&1; then
    echo "::error::Gradle didn't list the libraries:"
    tail -n 5 "$tmp/gradle" | sed 's/^/::error::/'
    exit 1
  fi
  awk '/--- / && !/\((c|n)\)$/ && !/[{]/ {
         sub(/^[|+\\ ]*--- /, ""); n = split($1, c, ":"); v = c[3]; if ($2 == "->") v = $3
         if (n >= 2 && v != "" && c[2] !~ /-bom$/) print c[1] ":" c[2] ":" v }' "$tmp/gradle" |
    LC_ALL=C sort -u > "$tmp/maven"
  [ -s "$tmp/maven" ] || { echo "::error::Gradle listed no libraries"; exit 1; }
  cache=${GRADLE_USER_HOME:-$HOME/.gradle}/caches/modules-2/files-2.1
  # pom <group> <artifact> <version>: that POM from Gradle's cache into $tmp/pom.xml, without its namespace
  pom() {
    f=$(find "$cache/$1/$2/$3" -name "$2-$3.pom" 2>/dev/null | head -n 1)
    [ -n "$f" ] && sed 's/ xmlns="[^"]*"//' "$f" > "$tmp/pom.xml"
  }
  value() { xmllint --xpath "string($1)" "$tmp/pom.xml"; }
  : > "$tmp/libraries"
  while IFS=: read -r g a v; do
    pom "$g" "$a" "$v" || { echo "::error::Gradle's cache has no POM for $g:$a:$v"; exit 1; }
    license= url=
    while
      [ -n "$license" ] || license=$(value '/project/licenses/license[1]/name')
      [ -n "$url" ] || url=$(value /project/scm/url)
      [ -n "$url" ] || url=$(value /project/url)
      [ -z "$license" ] || [ -z "$url" ]
    do
      pom "$(value /project/parent/groupId)" "$(value /project/parent/artifactId)" \
        "$(value /project/parent/version)" || break
    done
    [ -n "$license" ] || { echo "::error::No license for $g:$a:$v"; exit 1; }
    [ -n "$url" ] || { echo "::error::No source code address for $g:$a:$v"; exit 1; }
    case $license in
      *Apache*2.0*) ;;
      *) echo "::error::$g:$a:$v is under $license, whose text isn't added here yet"; exit 1 ;;
    esac
    printf '  %s %s, %s\n    %s\n' "$g:$a" "$v" "$license" "$url" >> "$tmp/libraries"
  done < "$tmp/maven"
  mkdir -p "$lic/java-libraries"
  curl -fsSL --retry 3 -o "$lic/java-libraries/LICENSE-2.0.txt" https://www.apache.org/licenses/LICENSE-2.0.txt

  cat >> "$lic/README.txt" <<EOF
lib/*/libhello_qt_*.so: hello_qt, under the MIT License. Source code: $repo

lib/*/libQt6*.so and lib/*/libplugins_*.so (Qt's libraries and plugins), and Qt's Java code in classes.dex:
Qt $qtv for Android, from Qt's online repository (built by The Qt Company), under the GNU Lesser General
Public License version 3 (Qt/LGPL-3.0-only.txt, which adds to Qt/GPL-3.0-only.txt). Qt contains code from
other projects, listed in Qt/THIRD-PARTY.txt. You may replace these files with your own build of Qt
${qtv%.*}, then align and sign the APK again (zipalign and apksigner, from the Android SDK). Qt's source
code:
  $qtsrc

lib/*/libc++_shared.so: libc++, LLVM's C++ standard library, from the Android NDK $ndkv (Android's LLVM
$llvm), under the Apache License 2.0 with LLVM Exceptions (libc++/LICENSE.TXT). Source code:
  https://android.googlesource.com/toolchain/llvm-project

The rest of classes.dex: these libraries, which Qt's Java code uses, each with its license (the Apache
License 2.0 is in java-libraries/LICENSE-2.0.txt) and where its source code is:
EOF
  cat "$tmp/libraries" >> "$lic/README.txt"
  case $app in
    /*) apk=$app ;;
    *) apk=$PWD/$app ;;
  esac
  (cd "$tmp/apk" && zip -qr "$apk" assets)
  ;;
esac
