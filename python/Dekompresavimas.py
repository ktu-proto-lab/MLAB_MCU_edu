from PIL import Image
import numpy as np


image_path = "pattern_edge.pgm"

image = Image.open(image_path)
image_array = np.array(image)

eil = np.size(image_array, 0)
stulp = np.size(image_array, 1)

print(eil,stulp)

encoded_data = []
i = 1

flat = image_array.flatten()


for nr in range( np.size(flat)-1):

    if flat[nr] == flat[nr + 1]:
        i += 1

    elif flat[nr] != flat[nr + 1]:
        encoded = [int(flat[nr]), i]
        encoded_data.append(encoded)
        i = 1
encoded_data.append([int(flat[-1]), i])

np.savetxt("compression.txt", encoded_data, fmt="%d")
print(np.size(image_array))
print(np.size(encoded_data))