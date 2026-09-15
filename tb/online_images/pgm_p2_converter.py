from PIL import Image
import os

width = 320
height = 240

input_path = "pepper.pgm"
output_path = "../src_images/"

output = os.path.join(output_path, input_path)
img = Image.open(input_path).convert('L').resize((width,height))
pixels= list(img.getdata())

with open(output, 'w') as f:
    f.write("P2\n")
    f.write(f"{width} {height}\n")
    f.write("255\n")

    for i, val in enumerate(pixels):
        f.write(f"{val} ")
        if(i+1)%width == 0:
            f.write("\n")
