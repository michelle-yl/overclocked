
from PIL import Image

# Size of the chef sprite on the VGA screen
SIZE = 32

# Open the chef image and keep its transparency
img = Image.open("chef.png").convert("RGBA")

# Crop away extra transparent space around the chef
bbox = img.getbbox()

if bbox is None:
    raise ValueError("The chef image is completely transparent!")

img = img.crop(bbox)

# Resize the chef without stretching it
# Nearest neighbor keeps the pixel-art appearance
img.thumbnail((SIZE, SIZE), Image.Resampling.NEAREST)

# Create a transparent 32x32 image
sprite = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# Place the chef in the center
x_offset = (SIZE - img.width) // 2
y_offset = (SIZE - img.height) // 2

sprite.paste(img, (x_offset, y_offset))

# Save a preview so we can check the result
sprite.save("chef_preview.png")

# Store the colour and transparency value of each pixel
colors = []
mask = []

for y in range(SIZE):
    for x in range(SIZE):

        r, g, b, a = sprite.getpixel((x, y))

        # 1 means visible, 0 means transparent
        if a >= 128:
            mask.append(1)
        else:
            mask.append(0)

        # Convert 8-bit RGB channels to 2 bits each
        r2 = r >> 6
        g2 = g >> 6
        b2 = b >> 6

        # Combine the channels into one 6-bit value
        color = (r2 << 4) | (g2 << 2) | b2

        colors.append(color)

# Write a Quartus-compatible MIF file
def write_mif(filename, data, width):

    with open(filename, "w") as f:

        f.write(f"WIDTH={width};\n")
        f.write(f"DEPTH={SIZE * SIZE};\n")
        f.write("ADDRESS_RADIX=UNS;\n")
        f.write("DATA_RADIX=HEX;\n")
        f.write("CONTENT BEGIN\n")

        for address, value in enumerate(data):
            f.write(f"{address} : {value:X};\n")

        f.write("END;\n")

# Create separate files for colours and transparency
write_mif("chef_sprite.mif", colors, 6)
write_mif("chef_mask.mif", mask, 1)

print("Chef sprite conversion complete!")
print("Created chef_sprite.mif")
print("Created chef_mask.mif")
print("Created chef_preview.png")
