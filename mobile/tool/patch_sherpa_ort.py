#!/usr/bin/env python3
"""Point sherpa-onnx Android at the ONNX Runtime 1.29 library this app ships.

sherpa-onnx 1.13.8 was linked against ONNX Runtime 1.28.2. The phone also
ships ONNX Runtime 1.29 for IndicTrans2, and Android keeps only one
libonnxruntime.so. The two version names are the same length, so this rewrites
the needed version string and its ELF hash. Safe to run more than once.
"""

import pathlib
import struct
import sys

OLD = b"VERS_1.28.2"
NEW = b"VERS_1.29.0"


def elf_hash(name: bytes) -> int:
    value = 0
    for byte in name:
        value = ((value << 4) + byte) & 0xFFFFFFFF
        high = value & 0xF0000000
        if high:
            value ^= high >> 24
        value &= ~high & 0xFFFFFFFF
    return value


def cstr(data: bytearray, offset: int) -> bytes:
    end = data.index(b"\0", offset)
    return bytes(data[offset:end])


def patch(path: pathlib.Path) -> str:
    data = bytearray(path.read_bytes())
    if data[:4] != b"\x7fELF":
        return "skipped, not an ELF file"
    count = data.count(OLD)
    if count:
        data = bytearray(bytes(data).replace(OLD, NEW))
    elf_class = data[4]
    endian = "<" if data[5] == 1 else ">"
    if elf_class == 2:
        e_shoff = struct.unpack_from(endian + "Q", data, 40)[0]
        e_shentsize = struct.unpack_from(endian + "H", data, 58)[0]
        e_shnum = struct.unpack_from(endian + "H", data, 60)[0]
        e_shstrndx = struct.unpack_from(endian + "H", data, 62)[0]

        def section(index: int):
            offset = e_shoff + index * e_shentsize
            name, kind, _, _, file_offset, size = struct.unpack_from(
                endian + "IIQQQQ", data, offset
            )
            return name, kind, file_offset, size
    else:
        e_shoff = struct.unpack_from(endian + "I", data, 32)[0]
        e_shentsize = struct.unpack_from(endian + "H", data, 46)[0]
        e_shnum = struct.unpack_from(endian + "H", data, 48)[0]
        e_shstrndx = struct.unpack_from(endian + "H", data, 50)[0]

        def section(index: int):
            offset = e_shoff + index * e_shentsize
            name, kind, _, _, file_offset, size = struct.unpack_from(
                endian + "IIIIII", data, offset
            )
            return name, kind, file_offset, size

    _, _, names_offset, _ = section(e_shstrndx)
    verneed = None
    dynstr = None
    for index in range(e_shnum):
        name_offset, _, file_offset, size = section(index)
        name = cstr(data, names_offset + name_offset)
        if name == b".gnu.version_r":
            verneed = (file_offset, size)
        elif name == b".dynstr":
            dynstr = file_offset
    if verneed is None or dynstr is None:
        return "skipped, no version section"
    new_hash = elf_hash(NEW)
    offset, size = verneed
    end = offset + size
    updated = 0
    while offset < end:
        _, count_aux, _, aux_delta, next_delta = struct.unpack_from(
            endian + "HHIII", data, offset
        )
        aux = offset + aux_delta
        for _ in range(count_aux):
            stored_hash, _, _, name_offset, aux_next = struct.unpack_from(
                endian + "IHHII", data, aux
            )
            if cstr(data, dynstr + name_offset) == NEW and stored_hash != new_hash:
                struct.pack_into(endian + "I", data, aux, new_hash)
                updated += 1
            if aux_next == 0:
                break
            aux += aux_next
        if next_delta == 0:
            break
        offset += next_delta
    if count or updated:
        path.write_bytes(data)
    return f"string replacements {count}, hash updates {updated}"


def main() -> int:
    root = pathlib.Path.home() / ".pub-cache/hosted/pub.dev"
    files = sorted(
        root.glob(
            "sherpa_onnx_android_*/android/src/main/jniLibs/*/libsherpa-onnx-c-api.so"
        )
    )
    if not files:
        print("No sherpa-onnx Android libraries found in the pub cache.", file=sys.stderr)
        return 1
    for path in files:
        print(f"{path}: {patch(path)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
