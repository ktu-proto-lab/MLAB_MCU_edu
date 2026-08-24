from PIL import Image
import numpy as np

decoded_data = []

data = np.loadtxt( "pattern_edge_compressed.txt", dtype=int)

eil = np.size(data,0)
stulp = np.size(data,1)

multiplier = data[:, 1]
value = data[:, 0]


decoded_data = []

for i in range(eil):
    for k in range(multiplier[i]):
        decoded_data.append(value[i])


img = Image.new("L", (320,240))
img.putdata(decoded_data)
np.savetxt(
    "output.pgm",
    img,
    fmt="%d",
    header="P2\n320 240\n255",
    comments=""
)


