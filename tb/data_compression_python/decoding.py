from PIL import Image
import numpy as np
import sys

recreated_file = []

data = np.loadtxt( "compression.txt", dtype=int)

x = np.size(data,0)
y = np.size(data,1)

repeat = data[:, 1]
value = data[:, 0]

#pixels = np.repeat(values, counts)

for i in range(x):
        for k in range(repeat[i]):

            new = value[i]
            recreated_file.append(new)


print(recreated_file)


img = Image.new("L", (320, 240))
img.putdata(recreated_file)

img.save("output.pgm")






