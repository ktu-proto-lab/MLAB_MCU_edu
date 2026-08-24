from PIL import Image
import numpy as np
import sys

WIDTH, HEIGHT = 320, 240
INPUT_PATH = "../out2_images/baboon_edge_compressed.bin"
OUTPUT_PATH = "output_new.pgm"

# Each byte pair is (count, value)
raw_data = np.fromfile(INPUT_PATH, dtype=np.uint8)

# An odd total length means there's one trailing byte that isn't part of a
# complete (count, value) pair — drop it rather than letting reshape fail.
if raw_data.size % 2 != 0:
    print(f"Warning: odd file length, dropping trailing byte {raw_data[-1]}", file=sys.stderr)
    raw_data = raw_data[:-1]

data = raw_data.reshape(-1, 2)
counts = data[:, 0].astype(np.int64)   # widen before repeat to avoid overflow
values = data[:, 1].astype(np.uint8)

# Vectorized run-length expansion
pixels = np.repeat(values, counts)

target = WIDTH * HEIGHT
if pixels.size != target:
    print(f"Warning: decoded {pixels.size} pixels, expected {target} "
          f"({target - pixels.size:+d}); padding/truncating to fit.", file=sys.stderr)
    if pixels.size < target:
        pixels = np.pad(pixels, (0, target - pixels.size), constant_values=0)
    else:
        pixels = pixels[:target]

img = Image.fromarray(pixels.reshape(HEIGHT, WIDTH), mode="L")
img.save(OUTPUT_PATH)
print(f"Saved {OUTPUT_PATH}")
