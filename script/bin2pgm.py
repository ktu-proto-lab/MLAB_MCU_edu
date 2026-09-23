#!/usr/bin/env python3
"""
  Contributors:
    * Dovydas Liutkus
  Description:
    * Decode multi-frame compressed binary output from compress_acc testbench to PGM.
    *
    * Supports decoding single or multiple concatenated frames from a single .bin file.
    *
    * Two modes:
    *   raw - input is flat byte array(s) (FRAME_SIZE bytes per image)
    *   rle - input is RLE-encoded as (value, count) byte pairs:
    *           04 00 01 FF  ->  00 00 00 00 FF
    *         Each frame ends when TOTAL_PIXELS (width * height) are unpacked.
    *
    * Output:
    *   Generates <output_prefix>_000.pgm, <output_prefix>_001.pgm, etc.
    *
    * Usage:
    *   python3 bin2pgm.py <input.bin> [output_prefix]
    *                      [--mode {raw,rle}]
    *                      [--width W] [--height H]
"""

import argparse
import sys
from pathlib import Path


FRAME_W = 320
FRAME_H = 240


def decode_rle_frames(data: bytes, target_pixels: int) -> list[bytes]:
    """
    Decodes concatenated RLE byte-pairs [Value, Count] into separate frame byte arrays.
    Stops a frame once target_pixels count is accumulated.
    """
    if len(data) % 2 != 0:
        print(f"WARNING: RLE stream length {len(data)} is odd; last byte will be ignored.",
              file=sys.stderr)

    frames = []
    current_frame = bytearray()
    i = 0
    data_len = len(data) - 1  # Process complete 2-byte pairs

    while i < data_len:
        value = data[i]
        count = data[i + 1]
        i += 2

        if count == 0:
            print(f"WARNING: zero count at byte offset {i-2}; skipping pair.",
                  file=sys.stderr)
            continue

        needed = target_pixels - len(current_frame)

        if count <= needed:
            current_frame += bytes([value]) * count
        else:
            # Pair overflows current frame boundary (useful if RLE spans across frames)
            current_frame += bytes([value]) * needed
            frames.append(bytes(current_frame))
            
            # Start next frame with remaining count
            remaining = count - needed
            current_frame = bytearray(bytes([value]) * remaining)

        if len(current_frame) == target_pixels:
            frames.append(bytes(current_frame))
            current_frame = bytearray()

    # Handle incomplete last frame if stream ended early
    if current_frame:
        print(f"WARNING: Trailing incomplete frame with {len(current_frame)}/{target_pixels} pixels.",
              file=sys.stderr)
        frames.append(bytes(current_frame))

    return frames


def decode_raw_frames(data: bytes, target_pixels: int) -> list[bytes]:
    """Slices uncompressed continuous byte data into frame-sized chunks."""
    frames = []
    for offset in range(0, len(data), target_pixels):
        chunk = data[offset:offset + target_pixels]
        frames.append(chunk)
    return frames


def write_pgm(pixels: bytes, width: int, height: int, path: Path, source: Path) -> None:
    expected = width * height
    if len(pixels) != expected:
        print(f"WARNING: frame {path.name} has {len(pixels)} pixels, expected {expected}.", 
              file=sys.stderr)

    with path.open("w") as f:
        f.write(f"P2\n# PGM converted from {source}\n{width} {height}\n255\n")
        for i, v in enumerate(pixels[:expected]):
            f.write(str(v))
            f.write("\n" if (i + 1) % width == 0 else " ")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert multi-frame compress_acc binary output to PGM files.")
    parser.add_argument("input", type=Path, help="Input .bin file")
    parser.add_argument("output_prefix", type=Path, nargs="?",
                        help="Output filename prefix or output file (default: <input_stem>)")
    parser.add_argument("--mode", choices=["raw", "rle"],
                        help="Encoding mode (auto-detected if omitted)")
    parser.add_argument("--width", type=int, default=FRAME_W,
                        help=f"Frame width  (default: {FRAME_W})")
    parser.add_argument("--height", type=int, default=FRAME_H,
                        help=f"Frame height (default: {FRAME_H})")
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"ERROR: file not found: {args.input}")

    data = args.input.read_bytes()
    total_pixels = args.width * args.height

    # Auto-detection logic
    mode = args.mode
    if mode is None:
        if len(data) > 0 and len(data) % total_pixels == 0:
            mode = "raw"
        else:
            mode = "rle"
        print(f"Auto-detected mode: {mode} ({len(data)} bytes total)")

    # Decode frames
    if mode == "raw":
        frames = decode_raw_frames(data, total_pixels)
    else:
        frames = decode_rle_frames(data, total_pixels)
        total_decoded = sum(len(f) for f in frames)
        print(f"RLE decoded: {len(data)} bytes -> {len(frames)} frame(s) "
              f"({total_decoded} pixels, ratio {len(data)/max(total_decoded, 1):.3f})")

    # Determine base name for outputs
    if args.output_prefix:
        base_path = args.output_prefix.parent / args.output_prefix.stem
    else:
        base_path = args.input.parent / args.input.stem

    # Write each frame
    single_frame = len(frames) == 1
    for idx, frame_pixels in enumerate(frames):
        # Format output file name (e.g. image.pgm if 1 frame, or image_000.pgm if multiple)
        out_path = base_path.with_suffix(".pgm") if single_frame else base_path.parent / f"{base_path.name}_{idx:03d}.pgm"
        write_pgm(frame_pixels, args.width, args.height, out_path, args.input)
        print(f"Written frame {idx}: {out_path}")


if __name__ == "__main__":
    main()