#!/bin/sh
# Puts the qtbase (Qt Core, Gui, Widgets and the like) of one of Qt's packages into a folder, as a whole Qt
# (bin, lib and so on) where Qt's installer would put it, and for Linux also the ICU that Qt Core uses. Qt's
# installer needs a Qt account and aqtinstall doesn't know Qt 6.12's iOS packages yet, so the archives come
# straight from Qt's online repository, whose Updates.xml lists each package's version and archives. Needs
# xmllint, and a 7-Zip that knows Qt's archives: 7zz on macOS (brew install sevenzip), 7z on Ubuntu 24.04.
#
#   sh .github/qt.sh <folder in the repository> <package> <folder here>
#   sh .github/qt.sh mac_x64/desktop/qt6_6120/qt6_6120 qt.qt6.6120.clang_64 qt/macos
#   sh .github/qt.sh all_os/android/qt6_6120/qt6_6120_x86_64 qt.qt6.6120.android_x86_64 qt/android_x86_64
set -eu
repo=https://download.qt.io/online/qtsdkrepository
sevenzip=$(command -v 7zz || command -v 7z)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 -o "$tmp/Updates.xml" "$repo/$1/Updates.xml"
version=$(xmllint --xpath "string(//PackageUpdate[Name='$2']/Version)" "$tmp/Updates.xml")
for archive in $(xmllint --xpath "string(//PackageUpdate[Name='$2']/DownloadableArchives)" "$tmp/Updates.xml" |
    tr , '\n' | sed 's/^ *//' | grep -E '^(qtbase|icu)-'); do
  url=$repo/$1/$2/$version$archive
  curl -fsSL --retry 3 -o "$tmp/archive.7z" "$url"
  echo "$(curl -fsSL --retry 3 "$url.sha1")  $tmp/archive.7z" | shasum -c
  # The ICU archive holds just the libraries, which belong in lib, where Qt Core finds them
  case $archive in
    icu-*) to=$3/lib ;;
    *) to=$3 ;;
  esac
  "$sevenzip" x -bd -o"$to" "$tmp/archive.7z" > /dev/null
done
