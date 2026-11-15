
from PIL import Image

img = Image.open("kitchen.png").convert("RGB")
img = img.resize((320, 240), Image.Resampling.NEAREST)

with open("kitchen_background.mif", "w") as f:
    f.write("WIDTH=6;\n")
    f.write("DEPTH=76800;\n")
    f.write("ADDRESS_RADIX=UNS;\n")
    f.write("DATA_RADIX=HEX;\n")
    f.write("CONTENT BEGIN\n")

    for y in range(240):
        for x in range(320):
            r, g, b = img.getpixel((x, y))

            r = r >> 6
            g = g >> 6
            b = b >> 6

            colour = (r << 4) | (g << 2) | b
            address = y * 320 + x

            f.write(f"{address} : {colour:02X};\n")

    f.write("END;\n")
preview = Image.new("RGB", (320, 240))

for y in range(240):
    for x in range(320):
        r, g, b = img.getpixel((x, y))

        r = (r >> 6) * 85
        g = (g >> 6) * 85
        b = (b >> 6) * 85

        preview.putpixel((x, y), (r, g, b))

preview.save("kitchen_preview.png")