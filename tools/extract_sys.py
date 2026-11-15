"""Write sys/ (boot, bi2, apploader, fst, main.dol) from a GameCube ISO.

Companion to gcdisc.py, which writes the files/ tree. Together they produce the
same layout the launcher extracts, so a disc built by hand matches a disc built
by the launcher byte for byte.

Usage: python tools/extract_sys.py <game.iso> <out-sys-dir>
"""
import hashlib
import json
import os
import struct
import sys


def read(path, offset, size):
    with open(path, "rb") as f:
        f.seek(offset)
        return f.read(size)


def main():
    if len(sys.argv) != 3:
        print(__doc__.strip())
        return 2
    iso, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)

    header = read(iso, 0x0, 0x440)
    boot = header
    bi2 = read(iso, 0x440, 0x2000)

    # Apploader header. Some discs put an ASCII date (e.g. "2003/04/17") in the
    # first 16 bytes and entry/size/trailer at +0x10; others use the standard
    # layout with the date as a 4-byte value.
    app = read(iso, 0x2440, 0x20)
    date_is_ascii = all(0x30 <= b <= 0x39 for b in app[:4])
    if date_is_ascii:
        entry, size, trailer = struct.unpack(">3I", app[0x10:0x1C])
    else:
        entry, size, trailer = struct.unpack(">3I", app[4:0x10])
    apploader = read(iso, 0x2440, 0x20 + size + trailer)

    dol_offset, fst_offset, fst_size = struct.unpack(">3I", header[0x420:0x42C])
    fst = read(iso, fst_offset, fst_size)

    dol_header = read(iso, dol_offset, 0x100)
    text_off = struct.unpack(">7I", dol_header[0x00:0x1C])
    data_off = struct.unpack(">11I", dol_header[0x1C:0x48])
    text_size = struct.unpack(">7I", dol_header[0x90:0xAC])
    data_size = struct.unpack(">11I", dol_header[0xAC:0xD8])
    end = max([text_off[i] + text_size[i] for i in range(7)]
              + [data_off[i] + data_size[i] for i in range(11)])
    main_dol = read(iso, dol_offset, end)

    files = {
        "boot.bin": boot,
        "bi2.bin": bi2,
        "apploader.img": apploader,
        "fst.bin": fst,
        "main.dol": main_dol,
    }
    manifest = {}
    for name, data in files.items():
        path = os.path.join(out_dir, name)
        with open(path, "wb") as f:
            f.write(data)
        manifest[name] = {
            "size": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
        }
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
    print("wrote sys/ to " + out_dir)
    for name, info in manifest.items():
        print("  %-14s %9d  %s" % (name, info["size"], info["sha256"][:16]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
