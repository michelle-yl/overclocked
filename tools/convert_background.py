
import os
from PIL import Image

# Assets live in ../assets relative to this script
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

img = Image.open(os.path.join(ASSETS, "kitchen.png")).convert("RGB")
img = img.resize((320, 240), Image.Resampling.NEAREST)

# ---------------- Station rectangles ----------------
# Placeholder art: one solid 16x16 rectangle per station, drawn on the
# counter tile the chef faces. Tile (tx, ty) covers pixels
# x = 16*tx .. 16*tx+15, y = 16*ty .. 16*ty+15.
# Must match the chef tiles in src/stations.v (chef stands one tile below
# the top-row stations, beside the island, above the trash).
#
# Colours use only the 4 levels a 6-bit colour can show (0, 85, 170, 255
# per channel), so the MIF shows exactly these. Ingredient colours match
# order_display.v.

TILE = 16

def tile_rect(tx, ty, colour, outline=True):
    x0, y0 = tx * TILE, ty * TILE
    for y in range(y0, y0 + TILE):
        for x in range(x0, x0 + TILE):
            edge = x in (x0, x0 + TILE - 1) or y in (y0, y0 + TILE - 1)
            # 1 px black border so stations stand out from the art behind them
            img.putpixel((x, y), (0, 0, 0) if (outline and edge) else colour)

COUNTER = (170, 85, 0)     # 100100 brown: plain island counter (not a station)
BUN     = (255, 170, 0)    # 111000 same as order_display bun
LETTUCE = (0, 255, 0)      # 001100 same as order_display lettuce
RAW     = (255, 85, 85)    # 110101 pink: raw patty crate
STOVE   = (85, 85, 85)     # 010101 dark grey
PLATE   = (255, 255, 255)  # 111111 white
TRASH   = (0, 0, 0)        # 000000 black

# Island counter, row 8, x 6..13 (chef can't walk here, see chef_mvmt.v floor)
for tx in range(6, 14):
    tile_rect(tx, 8, COUNTER, outline=False)

tile_rect(2, 3, BUN)        # chef stands at (2,4)
tile_rect(4, 3, LETTUCE)    # chef stands at (4,4)
tile_rect(6, 3, RAW)        # chef stands at (6,4)
tile_rect(14, 3, STOVE)     # chef stands at (14,4)
tile_rect(10, 8, PLATE)     # chef stands at (10,7) or (10,9)
tile_rect(3, 11, TRASH)     # chef stands at (3,10)

with open(os.path.join(ASSETS, "kitchen_background.mif"), "w") as f:
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

preview.save(os.path.join(ASSETS, "kitchen_preview.png"))