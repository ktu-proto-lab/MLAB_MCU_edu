from PIL import Image
import os


input_path = "./tb/online_images/baboon.pgm"
output_dir = "./tb/src_images/"

new_width = 640
new_height = 480

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Generate output file name
output_filename = "baboon_upscaled.pgm"
output_path = os.path.join(output_dir, output_filename)

with Image.open(input_path) as img:
    # 1. Convert to Grayscale ('L')
    img = img.convert('L')
    
    # 2. Calculate new upscaled dimensions
    orig_width, orig_height = img.size
    
    # 3. Resize using high-quality Lanczos filter
    img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    pixels = list(img_resized.getdata())

# 4. Write manually in ASCII PGM (P2) format
with open(output_path, 'w') as f:
    f.write("P2\n")
    f.write(f"{new_width} {new_height}\n")
    f.write("255\n")

    for i, val in enumerate(pixels):
        f.write(f"{val} ")
        if (i + 1) % new_width == 0:
            f.write("\n")

print(f"Successfully upscaled from {orig_width}x{orig_height} to {new_width}x{new_height} -> {output_path}")