from PIL import Image
import numpy as np
import sys


#np.set_printoptions(threshold=sys.maxsize)


image_path = 'pattern_edge.pgm'

image = Image.open(image_path)

image_array = np.array(image)

a = image_array

xasis = np.size(image_array,0)
countY =0
countX =0


iteration = 0

new_encode = np.zeros((320, 240))

encode_vector = [ ]


yasis = np.size(image_array,1)


flat = image_array.flatten()



i=1

#print(flat)
for iteration in range(np.size(flat)-1):

        

    if flat[iteration] == flat[iteration+1]:
            #vienodi
            i += 1
            #print(flat[iteration], flat[iteration+1] )

    elif flat[iteration] != flat[iteration+1]:
            #baigiasi seka
            new = [int(flat[iteration]), i]
            #np.append(encode_vector, new)
            encode_vector.append(new)
            i=1

    else:
            i=1



np.savetxt("compression.txt", encode_vector)

#print(a)

print(len(image_array))