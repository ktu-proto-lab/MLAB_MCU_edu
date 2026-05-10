#!/usr/bin/env python3
"""
Prepare simulation image data for tb_sobel_acc.

Outputs (in the current directory):
    src.pgm  - 320x240 grayscale P5 binary PGM  (open to preview input)
    src.hex  - one 32-bit word per line for $readmemh
               four pixels packed LSB-first: pixel N in [7:0], N+3 in [31:24]

Usage:
    python pgm_to_hex.py [image_file]

If no file is given, a built-in test pattern is generated.
Pillow (pip install Pillow) is needed to open non-PGM formats.
Without Pillow, the test pattern is always used.
"""

import sys
import numpy as np


# ---------------------------------------------------------------------------
def test_pattern(w=320, h=240):
    """Gradient + checkerboard: sharp edges everywhere, good for Sobel."""
    x, y = np.meshgrid(np.arange(w, dtype=np.float32),
                       np.arange(h, dtype=np.float32))
    gradient  = ((x + y) / (w + h - 2) * 255).astype(np.float32)
    checker   = (((x // 16).astype(int) + (y // 16).astype(int)) % 2) * 96
    return np.clip(gradient + checker, 0, 255).astype(np.uint8)


def load(path, w=320, h=240):
    try:
        from PIL import Image
        return np.array(Image.open(path).convert('L').resize((w, h), Image.LANCZOS),
                        dtype=np.uint8)
    except ImportError:
        print("Pillow not installed - using test pattern instead.")
        print("Install with:  pip install Pillow")
        return test_pattern(w, h)


# ---------------------------------------------------------------------------
def write_pgm(pixels, path):
    h, w = pixels.shape
    with open(path, 'wb') as f:
        f.write(f"P5\n{w} {h}\n255\n".encode())
        f.write(pixels.tobytes())
    print(f"  {path}  ({w}×{h} grayscale PGM)")


def write_hex(pixels, path):
    """Four 8-bit pixels packed into each 32-bit word, little-endian."""
    flat = pixels.flatten()
    with open(path, 'w') as f:
        for i in range(0, len(flat), 4):
            word = (int(flat[i])
                    | int(flat[i + 1]) << 8
                    | int(flat[i + 2]) << 16
                    | int(flat[i + 3]) << 24)
            f.write(f"{word:08x}\n")
    print(f"  {path}  ({len(flat) // 4} words)")


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) > 1:
        pixels = load(sys.argv[1])
        print(f"Loaded: {sys.argv[1]}  →  resized to 320×240 grayscale")
    else:
        pixels = test_pattern()
        print("No input image - generating built-in test pattern")

    print("Writing:")
    write_pgm(pixels, "src.pgm")
    write_hex(pixels, "src.hex")

    print()
    print("Open src.pgm to preview the source image.")
    print("After simulation, open dst.pgm for the processed result.")
