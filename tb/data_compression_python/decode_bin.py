import numpy as np

WIDTH, HEIGHT = 320, 240

raw = np.fromfile(
    "pattern_edge_compressed.bin",
    dtype=np.uint8
)

pixels = []
for i in range(0, len(raw), 2):
    value = raw[i]
    count = raw[i + 1]
    pixels.extend([value] * count)

image = np.array(pixels, dtype=np.uint8).reshape(HEIGHT, WIDTH)

with open("output_bin.pgm", "w") as f:
    f.write(f"P2\n{WIDTH} {HEIGHT}\n255\n")
    for row in image:
        f.write(" ".join(map(str, row)) + "\n")

print("saved output_bin.pgm")