#!/bin/sh
# Puts the qtbase (Qt Core, Gui, Widgets and the like) of one of Qt's packages for Macs into a folder, as
# a whole Qt (bin, lib and so on) where Qt's installer would put it. Qt's installer needs a Qt account and
# aqtinstall doesn't know Qt 6.12's iOS packages yet, so the archive comes straight from Qt's online
# repository, whose Updates.xml lists each package's version and archives. Needs xmllint and 7-Zip's 7zz
# (brew install sevenzip):
#
#   sh .github/qt.sh <folder in the repository> <package> <folder here>
#   sh .github/qt.sh desktop/qt6_6120/qt6_6120 qt.qt6.6120.clang_64 qt/macos
set -eu
repo=https://download.qt.io/online/qtsdkrepository/mac_x64
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 -o "$tmp/Updates.xml" "$repo/$1/Updates.xml"
version=$(xmllint --xpath "string(//PackageUpdate[Name='$2']/Version)" "$tmp/Updates.xml")
archive=$(xmllint --xpath "string(//PackageUpdate[Name='$2']/DownloadableArchives)" "$tmp/Updates.xml" |
  tr , '\n' | sed 's/^ *//' | grep '^qtbase-')
url=$repo/$1/$2/$version$archive
curl -fsSL --retry 3 -o "$tmp/qtbase.7z" "$url"
echo "$(curl -fsSL --retry 3 "$url.sha1")  $tmp/qtbase.7z" | shasum -c
7zz x -bd -o"$3" "$tmp/qtbase.7z" > /dev/null
