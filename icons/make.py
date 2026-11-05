#!/usr/bin/env python3
# Makes the apps' icon for each platform from hello_qt.svg, with librsvg's rsvg-convert (MSYS2:
# mingw-w64-ucrt-x86_64-librsvg; Debian/Ubuntu: librsvg2-bin; macOS: brew install librsvg), into this folder:
#
#   hello_qt.ico      Windows: the icon of hello.exe and hello_qt.exe (version.rc), and of their windows
#   hello_qt.icns     macOS: the app's icon, on Apple's grid, where the icon is 824 pixels of 1024
#   hello_qt.png      the window's icon (hello_qt.qrc), which Linux and the web page show, and the AppImage's
#   Assets.xcassets   iPhone: the app's icon, from which Xcode makes every size; square and opaque, as iOS
#                     rounds the corners itself
#   android/res       Android: the launcher icon, an adaptive one: a background and a foreground layer of
#                     108 dp each, of which Android shows the middle 72 dp in the shape of the device's icons
#   sources.sha256    the SHA-256 of hello_qt.svg and of this script: GitHub Actions checks that the icons
#                     were made from them
#
# Run it after changing either, from anywhere: python3 icons/make.py
import hashlib
import json
import os
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zlib

here = os.path.dirname(os.path.abspath(__file__))
top = os.path.dirname(here)
SVG = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG)


def svg(margin=0, square=False, layer=None):
    """hello_qt.svg, whose icon is 256 units wide, with margin units of room around it; square, without
    its rounded corners; and as one layer: 'background', just its rect with the id background, or
    'foreground', all but that"""
    root = ET.parse(os.path.join(top, 'hello_qt.svg')).getroot()
    size = 256 + 2 * margin
    root.set('viewBox', f'{-margin:g} {-margin:g} {size:g} {size:g}')
    background = root.find(f"{{{SVG}}}rect[@id='background']")
    if square:
        background.attrib.pop('rx', None)
        for name, value in ('x', -margin), ('y', -margin), ('width', size), ('height', size):
            background.set(name, f'{value:g}')
    for child in list(root):
        if (layer == 'foreground' and child is background or
                layer == 'background' and child is not background and child.tag != f'{{{SVG}}}defs'):
            root.remove(child)
    return ET.tostring(root)


def png(image, size):
    """The SVG image as a PNG, size pixels square"""
    with tempfile.TemporaryDirectory() as tmp:
        source, target = os.path.join(tmp, 'icon.svg'), os.path.join(tmp, 'icon.png')
        with open(source, 'wb') as f:
            f.write(image)
        subprocess.run(['rsvg-convert', '-w', str(size), '-h', str(size), '-o', target, source], check=True)
        with open(target, 'rb') as f:
            return f.read()


def ico(sizes):
    """A Windows icon file with a PNG of each size (Windows Vista and later read PNG in icons)"""
    images = [png(svg(), size) for size in sizes]
    header = struct.pack('<3H', 0, 1, len(images))  # reserved, 1 for an icon, the number of images
    offset = len(header) + 16 * len(images)
    entries = b''
    for size, image in zip(sizes, images):
        # width and height (0 for 256), colors in a palette, reserved, planes, bits per pixel, bytes, offset
        entries += struct.pack('<4B2H2I', size % 256, size % 256, 0, 0, 1, 32, len(image), offset)
        offset += len(image)
    return header + entries + b''.join(images)


def icns():
    """A macOS icon file, with a PNG for each of its types: 16, 32, 128, 256 and 512 points, each also
    twice as big for Retina screens"""
    image = svg(margin=(256 * 1024 / 824 - 256) / 2)
    pngs, data = {}, b''
    for kind, size in [('icp4', 16), ('ic11', 32), ('icp5', 32), ('ic12', 64), ('ic07', 128),
                       ('ic13', 256), ('ic08', 256), ('ic14', 512), ('ic09', 512), ('ic10', 1024)]:
        if size not in pngs:
            pngs[size] = png(image, size)
        data += kind.encode() + struct.pack('>I', 8 + len(pngs[size])) + pngs[size]
    return b'icns' + struct.pack('>I', 8 + len(data)) + data


def opaque(image):
    """The PNG of an opaque image without an alpha channel, which the App Store doesn't allow in an app's
    icon. Newer versions of rsvg-convert leave it out themselves; older ones write 8-bit RGBA."""
    chunks, pos = {}, 8
    while pos < len(image):
        length, kind = struct.unpack('>I4s', image[pos:pos + 8])
        chunks[kind] = chunks.get(kind, b'') + image[pos + 8:pos + 8 + length]
        pos += 12 + length
    width, height, depth, color, _, _, interlace = struct.unpack('>2I5B', chunks[b'IHDR'])
    if (depth, color) == (8, 2):  # 8-bit RGB already
        return image
    assert (depth, color, interlace) == (8, 6, 0), 'not 8-bit RGBA'
    data, stride = zlib.decompress(chunks[b'IDAT']), width * 4
    above, rows = bytearray(stride), bytearray()
    for y in range(height):
        start = y * (stride + 1)
        kind, row = data[start], bytearray(data[start + 1:start + 1 + stride])
        for i in range(stride):  # undo the row's filter
            a, b, c = row[i - 4] if i >= 4 else 0, above[i], above[i - 4] if i >= 4 else 0
            if kind == 1:
                row[i] = (row[i] + a) & 255
            elif kind == 2:
                row[i] = (row[i] + b) & 255
            elif kind == 3:
                row[i] = (row[i] + (a + b) // 2) & 255
            elif kind == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                row[i] = (row[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        assert row[3::4] == bytes([255]) * width, 'not opaque'
        rgb = bytearray(row)
        del rgb[3::4]
        rows.append(1)  # filter Sub: each byte less the one of the pixel before it
        rows += bytes((rgb[i] - (rgb[i - 3] if i >= 3 else 0)) & 255 for i in range(len(rgb)))
        above = row

    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', width, height, 8, 2, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(bytes(rows), 9)) + chunk(b'IEND', b''))


def catalog(contents):
    """An asset catalog's Contents.json, laid out as Xcode writes it"""
    return json.dumps({**contents, 'info': {'author': 'xcode', 'version': 1}}, indent=2,
                      separators=(',', ' : ')) + '\n'


def sha256(name):
    """The SHA-256 of the file, with LF line ends, as in a checkout on Linux"""
    with open(os.path.join(top, name), 'rb') as f:
        return hashlib.sha256(f.read().replace(b'\r\n', b'\n')).hexdigest()


def write(name, data):
    path = os.path.join(here, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data.encode() if isinstance(data, str) else data)
    print(f'{len(data):8} icons/{name}')


print(subprocess.run(['rsvg-convert', '--version'], capture_output=True, text=True, check=True)
      .stdout.splitlines()[0])
write('hello_qt.ico', ico([16, 20, 24, 32, 40, 48, 64, 256]))
write('hello_qt.icns', icns())
write('hello_qt.png', png(svg(), 256))
write('Assets.xcassets/Contents.json', catalog({}))
write('Assets.xcassets/AppIcon.appiconset/Contents.json', catalog({'images': [
    {'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}]}))
write('Assets.xcassets/AppIcon.appiconset/AppIcon.png', opaque(png(svg(square=True), 1024)))
# Android's layers: 108 dp, where the icon's 256 units are the middle 72 dp; for the screens with the most
# pixels (xxxhdpi, 4 pixels a dp), as Android scales them down for the others
write('android/res/mipmap-xxxhdpi/ic_launcher_background.png',
      png(svg(margin=64, square=True, layer='background'), 432))
write('android/res/mipmap-xxxhdpi/ic_launcher_foreground.png', png(svg(margin=64, layer='foreground'), 432))
write('android/res/mipmap-anydpi-v26/ic_launcher.xml', '''\
<?xml version="1.0" encoding="utf-8"?>
<!-- The launcher icon, made by icons/make.py from hello_qt.svg -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
write('sources.sha256', ''.join(f'{sha256(name)}  {name}\n' for name in ['hello_qt.svg', 'icons/make.py']))
