#!/usr/bin/env python3
"""
  Contributors:
    * Dovydas Liutkus
  Description:
    * Decode compressed binary output from compress_acc testbench to PGM.
    *
    * Two modes:
    *   raw - input is a flat byte array (pass-through / no compression)
    *   rle - input is RLE-encoded as (count, value) byte pairs:
    *           04 00 01 FF  ->  00 00 00 00 FF
    *         Count is 1-255; a run longer than 255 is split into multiple pairs.
    *
    * Auto-detection: if the file size equals TOTAL_PIXELS the mode defaults to
    * raw, otherwise rle.  Override with --mode {raw,rle}.
    *
    * Output is a P2 (ASCII PGM) file matching the format of the source images.
    *
    * Usage:
    *   python3 bin2pgm.py <input.bin> [output.pgm]
    *                      [--mode {raw,rle}]
    *                      [--width W] [--height H]
"""

import argparse
import sys
from pathlib import Path


FRAME_W = 320
FRAME_H = 240
TOTAL_PIXELS = FRAME_W * FRAME_H


def decode_rle(data: bytes) -> bytes:
    if len(data) % 2 != 0:
        print(f"WARNING: RLE stream length {len(data)} is odd; last byte ignored.",
              file=sys.stderr)
    pixels = bytearray()
    for i in range(0, len(data) - 1, 2):
        count = data[i+1]
        value = data[i]
        if count == 0:
            print(f"WARNING: zero count at byte offset {i}; skipping pair.",
                  file=sys.stderr)
            continue
        pixels += bytes([value]) * count
    return bytes(pixels)


def write_pgm(pixels: bytes, width: int, height: int, path: Path, source: Path) -> None:
    expected = width * height
    if len(pixels) != expected:
        print(f"WARNING: decoded {len(pixels)} pixels, expected {expected} "
              f"({width}x{height}).", file=sys.stderr)
    with path.open("w") as f:
        f.write(f"P2\n# PGM converted from {source}\n{width} {height}\n255\n")
        for i, v in enumerate(pixels[:expected]):
            f.write(str(v))
            f.write("\n" if (i + 1) % width == 0 else " ")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert compress_acc binary output to PGM.")
    parser.add_argument("input",  type=Path, help="Input .bin file")
    parser.add_argument("output", type=Path, nargs="?",
                        help="Output .pgm file (default: <input>.pgm)")
    parser.add_argument("--mode", choices=["raw", "rle"],
                        help="Encoding mode (auto-detected if omitted)")
    parser.add_argument("--width",  type=int, default=FRAME_W,
                        help=f"Frame width  (default: {FRAME_W})")
    parser.add_argument("--height", type=int, default=FRAME_H,
                        help=f"Frame height (default: {FRAME_H})")
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"ERROR: file not found: {args.input}")

    data = args.input.read_bytes()
    total = args.width * args.height

    mode = args.mode
    if mode is None:
        mode = "raw" if len(data) == total else "rle"
        print(f"Auto-detected mode: {mode} ({len(data)} bytes)")

    if mode == "raw":
        pixels = data
    else:
        pixels = decode_rle(data)
        print(f"RLE decoded: {len(data)} bytes -> {len(pixels)} pixels "
              f"(ratio {len(data)/max(len(pixels),1):.3f})")

    out_path = args.output or args.input.with_suffix(".pgm")
    write_pgm(pixels, args.width, args.height, out_path, args.input)
    print(f"Written: {out_path}")


if __name__ == "__main__":
    main()