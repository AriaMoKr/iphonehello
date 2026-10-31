#!/bin/sh
# Starts hello_qt-linux.AppImage as a desktop without Qt would, with an X server (Xvfb): still running after
# 8 seconds, and then the screen in screen.xwd, where Qt draws at twice the size, for OCR. As root, as in a
# container of a Linux distribution, it first installs what such a desktop has that the AppImage needs:
# Xvfb, OpenGL, X11's libraries, fontconfig and a font. Without FUSE (/dev/fuse), as in a container, the
# AppImage extracts itself instead of mounting itself. Run it from the repository's root, where the
# AppImage is:
#
#   docker run --rm -v "$PWD:/w" -w /w debian:12 sh .github/appimage-test.sh
set -eu
. /etc/os-release
if [ "$(id -u)" = 0 ]; then
  case " $ID ${ID_LIKE:-} " in
    *' debian '*)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y -qq --no-install-recommends xvfb libgl1 libegl1 libx11-6 libx11-xcb1 libxcb1 \
        libfontconfig1 libfreetype6 fonts-dejavu-core > /dev/null ;;
    *' fedora '*) # Fedora, and RHEL and its rebuilds
      dnf install -y -q xorg-x11-server-Xvfb mesa-libGL mesa-libEGL libX11 libX11-xcb libxcb fontconfig \
        freetype dejavu-sans-fonts > /dev/null ;;
    *) echo "What $PRETTY_NAME needs isn't known here"
       exit 1 ;;
  esac
fi
if [ -e /dev/fuse ]; then
  how='mounted with FUSE'
else
  how=extracted
  export APPIMAGE_EXTRACT_AND_RUN=1
fi
echo "system: $PRETTY_NAME (glibc $(ldd --version | sed -n '1s/.* //p')), $how"
mkdir -p /tmp/screen
Xvfb :99 -screen 0 1024x768x24 -fbdir /tmp/screen > /tmp/xvfb.txt 2>&1 &
xvfb=$!
sleep 2
DISPLAY=:99 QT_SCALE_FACTOR=2 QT_FORCE_STDERR_LOGGING=1 ./hello_qt-linux.AppImage > /tmp/app.txt 2>&1 &
app=$!
sleep 8
if ! kill -0 $app 2> /dev/null; then
  echo "hello_qt-linux.AppImage quit within 8 seconds:"
  cat /tmp/app.txt
  exit 1
fi
if [ -n "${APPIMAGE_EXTRACT_AND_RUN:-}" ] || grep -q '/\.mount_' /proc/mounts; then
  cp /tmp/screen/Xvfb_screen0 screen.xwd
else
  echo "hello_qt-linux.AppImage runs, but isn't mounted with FUSE"
  exit 1
fi
kill $app $xvfb
