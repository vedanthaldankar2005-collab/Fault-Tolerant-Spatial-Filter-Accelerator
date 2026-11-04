from pathlib import Path
from PIL import Image
import numpy as np


# ============================================================
# Convert 128x128 grayscale PNG to hexadecimal pixel file
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_IMAGE = PROJECT_ROOT / "python" / "tree_input_128x128.png"
OUTPUT_HEX = PROJECT_ROOT / "results" / "tree_input_128x128.hex"


print("========================================")
print("      IMAGE TO HEX CONVERTER")
print("========================================")


# ------------------------------------------------------------
# Load grayscale image
# ------------------------------------------------------------

image = Image.open(INPUT_IMAGE).convert("L")

print("\nInput image:")
print(INPUT_IMAGE)

print("Image size:", image.size)
print("Image mode:", image.mode)


# ------------------------------------------------------------
# Convert to NumPy array
# ------------------------------------------------------------

pixels = np.array(
    image,
    dtype=np.uint8
)

height, width = pixels.shape

print("\nDimensions:")
print(height, "x", width)

print("Total pixels:", pixels.size)


# ------------------------------------------------------------
# Verify image size
# ------------------------------------------------------------

if height != 128 or width != 128:

    print("\nERROR: Image is not 128x128")
    raise SystemExit(1)


# ------------------------------------------------------------
# Write one 8-bit pixel per line
#
# Example:
#
# 00
# 7F
# FF
# ...
# ------------------------------------------------------------

with open(OUTPUT_HEX, "w") as file:

    for pixel in pixels.flatten():

        file.write(f"{int(pixel):02X}\n")


# ------------------------------------------------------------
# Verify output
# ------------------------------------------------------------

with open(OUTPUT_HEX, "r") as file:

    values = file.readlines()


print("\nHEX file created:")
print(OUTPUT_HEX)

print("HEX values:", len(values))

print("\nFirst 10 pixel values:")

for value in values[:10]:

    print(value.strip())


if len(values) == 128 * 128:

    print("\nIMAGE TO HEX: PASS")

else:

    print("\nIMAGE TO HEX: FAIL")


print("\n========================================")
print("      CONVERSION COMPLETE")
print("========================================")