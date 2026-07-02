#!/usr/bin/env python3
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path


def paeth(left: int, above: int, upper_left: int) -> int:
    estimate = left + above - upper_left
    left_distance = abs(estimate - left)
    above_distance = abs(estimate - above)
    upper_left_distance = abs(estimate - upper_left)
    if left_distance <= above_distance and left_distance <= upper_left_distance:
        return left
    if above_distance <= upper_left_distance:
        return above
    return upper_left


def alpha_values(path: Path) -> tuple[int, int, list[int]]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("not a PNG file")

    position = 8
    width = 0
    height = 0
    bit_depth = 0
    color_type = 0
    interlace = 0
    idat_chunks: list[bytes] = []

    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        chunk_type = data[position + 4:position + 8]
        chunk = data[position + 8:position + 8 + length]
        position += 12 + length

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _compression, _filter, interlace = struct.unpack(
                ">IIBBBBB",
                chunk,
            )
        elif chunk_type == b"IDAT":
            idat_chunks.append(chunk)
        elif chunk_type == b"IEND":
            break

    if bit_depth != 8 or color_type != 6 or interlace != 0:
        raise ValueError("expected a non-interlaced 8-bit RGBA PNG")

    channels = 4
    stride = width * channels
    raw = zlib.decompress(b"".join(idat_chunks))
    previous = [0] * stride
    alphas: list[int] = []
    offset = 0

    for _row_index in range(height):
        filter_type = raw[offset]
        offset += 1
        encoded = list(raw[offset:offset + stride])
        offset += stride
        row = [0] * stride

        for index, encoded_value in enumerate(encoded):
            left = row[index - channels] if index >= channels else 0
            above = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                value = encoded_value
            elif filter_type == 1:
                value = encoded_value + left
            elif filter_type == 2:
                value = encoded_value + above
            elif filter_type == 3:
                value = encoded_value + ((left + above) // 2)
            elif filter_type == 4:
                value = encoded_value + paeth(left, above, upper_left)
            else:
                raise ValueError(f"unsupported PNG filter type {filter_type}")
            row[index] = value & 0xFF

        previous = row
        alphas.extend(row[3::4])

    return width, height, alphas


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: assert-png-template-alpha.py <png> [...]", file=sys.stderr)
        return 2

    for raw_path in sys.argv[1:]:
        path = Path(raw_path)
        width, height, alphas = alpha_values(path)
        corners = [alphas[0], alphas[width - 1], alphas[-width], alphas[-1]]
        opaque_pixels = sum(alpha == 255 for alpha in alphas)
        transparent_pixels = sum(alpha == 0 for alpha in alphas)
        if any(alpha != 0 for alpha in corners):
            raise SystemExit(f"{path}: template PNG corners must be transparent; got {corners}")
        if opaque_pixels == 0:
            raise SystemExit(f"{path}: template PNG has no opaque icon pixels")
        if transparent_pixels == 0:
            raise SystemExit(f"{path}: template PNG has no transparent pixels")
        print(f"template alpha ok {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
