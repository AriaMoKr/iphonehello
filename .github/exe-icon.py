# Checks that each Windows .exe has the apps' icon (version.rc): in its resources, the icon group IDI_ICON1,
# by whose name hello.cpp and Qt load it, with an image of each size, as icons/make.py makes them (PNG).
# It prints the sizes, as an annotation.
#
#   python .github/exe-icon.py hello.exe build/hello_qt.exe
import struct
import sys


def resources(data):
    """A PE file's resources, as {type: {name: bytes}}, where types and names are numbers or strings"""
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    assert data[pe:pe + 4] == b'PE\0\0', 'not a PE file'
    count, optional_size = struct.unpack_from('<H12xH', data, pe + 6)
    optional = pe + 24
    magic = struct.unpack_from('<H', data, optional)[0]  # 0x10b: 32-bit, 0x20b: 64-bit
    directories = optional + (96 if magic == 0x10b else 112)
    root = struct.unpack_from('<I', data, directories + 2 * 8)[0]  # the resource table's address in memory
    sections = [struct.unpack_from('<4I', data, optional + optional_size + 40 * i + 8) for i in range(count)]

    def offset(address):  # in the file, of an address in memory
        for size, start, raw_size, raw_start in sections:
            if start <= address < start + max(size, raw_size):
                return address - start + raw_start
        raise ValueError(f'{address:#x} is in no section')
    base = offset(root)

    def entries(table):  # a table's names (numbers or strings) and what they point to
        named, numbered = struct.unpack_from('<12x2H', data, base + table)
        for i in range(named + numbered):
            name, target = struct.unpack_from('<2I', data, base + table + 16 + 8 * i)
            if name & 0x80000000:
                at = base + (name & 0x7fffffff)
                name = data[at + 2:at + 2 + 2 * struct.unpack_from('<H', data, at)[0]].decode('utf-16-le')
            yield name, target & 0x7fffffff
    found = {}
    for kind, names in entries(0):
        for name, languages in entries(names):
            for _, leaf in entries(languages):
                address, size = struct.unpack_from('<2I', data, base + leaf)
                found.setdefault(kind, {})[name] = data[offset(address):offset(address) + size]
    return found


RT_ICON, RT_GROUP_ICON = 3, 14
failed = False
for exe in sys.argv[1:]:
    with open(exe, 'rb') as f:
        found = resources(f.read())
    group = found.get(RT_GROUP_ICON, {}).get('IDI_ICON1')
    if group is None:
        print(f"::error::{exe} has no icon IDI_ICON1, but these icon groups: {list(found.get(RT_GROUP_ICON, {}))}")
        failed = True
        continue
    sizes = []
    for i in range(struct.unpack_from('<4xH', group)[0]):
        # width and height (0 for 256), colors, reserved, planes, bits per pixel, bytes, the image's id
        width, height, _, _, _, bits, size, image = struct.unpack_from('<4B2HIH', group, 6 + 14 * i)
        width, height, data = width or 256, height or 256, found.get(RT_ICON, {}).get(image, b'')
        if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack_from('>2I', data, 16) != (width, height):
            print(f'::error::{exe}: the icon\'s image {image} is no PNG of {width}x{height}')
            failed = True
        sizes.append(str(width))
    print(f"::notice::{exe} has the icon IDI_ICON1, in {len(sizes)} sizes: {', '.join(sizes)}")
sys.exit(1 if failed else 0)
