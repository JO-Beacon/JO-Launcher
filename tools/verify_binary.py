#!/usr/bin/env python3
"""Sanity checks for a built JO-Launcher.exe.

Parses the PE import table and looks for leftover build paths.

Usage:
    python tools/verify_binary.py build/Release/JO-Launcher.exe
"""

import argparse
import struct
import sys
from pathlib import Path


EXPECTED_IMPORTS = {
    "advapi32.dll",
    "crypt32.dll",
    "d2d1.dll",
    "dwrite.dll",
    "dwmapi.dll",
    "kernel32.dll",
    "ole32.dll",
    "shell32.dll",
    "user32.dll",
    "winhttp.dll",
}


def fail(message: str) -> None:
    print(f"FAIL  {message}")
    sys.exit(1)


def parse_pe(data: bytes):
    if data[:2] != b"MZ":
        fail("not a PE file")
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe : pe + 4] != b"PE\x00\x00":
        fail("missing PE signature")
    coff = pe + 4
    section_count = struct.unpack_from("<H", data, coff + 2)[0]
    optional_size = struct.unpack_from("<H", data, coff + 16)[0]
    optional = coff + 20
    magic = struct.unpack_from("<H", data, optional)[0]
    if magic == 0x20B:
        directories = optional + 112
    elif magic == 0x10B:
        directories = optional + 96
    else:
        fail(f"unknown optional header magic {magic:#x}")
    sections = optional + optional_size
    return directories, sections, section_count


def rva_reader(data: bytes, directories: int, sections: int, count: int):
    entries = []
    for index in range(count):
        base = sections + index * 40
        virtual_size, virtual_address, raw_size, raw_pointer = struct.unpack_from(
            "<IIII", data, base + 8
        )
        entries.append((virtual_address, virtual_size, raw_size, raw_pointer))

    def to_offset(rva: int) -> int:
        for start, virtual_size, raw_size, raw_pointer in entries:
            span = max(virtual_size, raw_size)
            if start <= rva < start + span:
                return raw_pointer + (rva - start)
        fail(f"RVA {rva:#x} is outside every section")

    import_rva, import_size = struct.unpack_from("<II", data, directories + 8)
    if import_rva == 0:
        return []

    names = []
    offset = to_offset(import_rva)
    while True:
        descriptor = data[offset : offset + 20]
        if len(descriptor) < 20 or descriptor == b"\x00" * 20:
            break
        name_rva = struct.unpack_from("<I", descriptor, 12)[0]
        name_offset = to_offset(name_rva)
        end = data.index(b"\x00", name_offset)
        names.append(data[name_offset:end].decode("ascii", "replace"))
        offset += 20
    return names


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    arguments = parser.parse_args()

    data = arguments.binary.read_bytes()
    print(f"binary {arguments.binary} ({len(data)} bytes)")

    directories, sections, count = parse_pe(data)
    imports = rva_reader(data, directories, sections, count)
    print("imports: " + ", ".join(sorted(imports)))

    present = {name.lower() for name in imports}
    unexpected = sorted(present - EXPECTED_IMPORTS)
    if unexpected:
        fail("unexpected imports: " + ", ".join(unexpected))
    missing = sorted(EXPECTED_IMPORTS - present)
    if missing:
        fail("missing imports: " + ", ".join(missing))

    if b".pdb" in data:
        fail("the binary leaks a .pdb path")

    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
