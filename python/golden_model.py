from pathlib import Path

import numpy as np
from PIL import Image


# ============================================================
# PYTHON GOLDEN MODEL
# 128x128 Grayscale Tree Image
# 3x3 Sobel-X Edge Detection
# ============================================================

print("========================================")
print("       PYTHON GOLDEN MODEL")
print("========================================")


# ============================================================
# Project paths
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_IMAGE = PROJECT_ROOT / "python" / "tree_input_128x128.png"
OUTPUT_TEXT = PROJECT_ROOT / "results" / "python_golden_output.txt"
OUTPUT_PNG = PROJECT_ROOT / "results" / "python_tree_sobel_x.png"


# ============================================================
# Sobel-X kernel
#
# Detects vertical edges
# ============================================================

KERNEL = np.array([
    [-1,  0,  1],
    [-2,  0,  2],
    [-1,  0,  1]
], dtype=np.int32)


print("\nSobel-X Kernel:")
print(KERNEL)


# ============================================================
# Load input image
# ============================================================

print("\nLoading input image...")
print("File:", INPUT_IMAGE)

image_pil = Image.open(INPUT_IMAGE)

print("Original image size:", image_pil.size)
print("Original image mode:", image_pil.mode)


# ============================================================
# Ensure grayscale
# ============================================================

image_pil = image_pil.convert("L")

print("Grayscale image size:", image_pil.size)
print("Grayscale image mode:", image_pil.mode)


# ============================================================
# Convert image to NumPy array
# ============================================================

image = np.array(
    image_pil,
    dtype=np.uint8
)

IMAGE_HEIGHT, IMAGE_WIDTH = image.shape

print("\nInput image dimensions:")
print(IMAGE_HEIGHT, "x", IMAGE_WIDTH)

print("Minimum pixel value:", image.min())
print("Maximum pixel value:", image.max())


# ============================================================
# Sobel-X filtering
# ============================================================

def sobel_x_filter(image, kernel):

    output_height = image.shape[0] - 3 + 1
    output_width = image.shape[1] - 3 + 1

    output = np.zeros(
        (output_height, output_width),
        dtype=np.int32
    )

    # --------------------------------------------------------
    # Slide 3x3 window over the image
    # --------------------------------------------------------

    for row in range(output_height):

        for col in range(output_width):

            window = image[
                row:row + 3,
                col:col + 3
            ]

            # ------------------------------------------------
            # 3x3 MAC operation
            # ------------------------------------------------

            result = np.sum(
                window.astype(np.int32) * kernel
            )

            output[row, col] = result

    return output


# ============================================================
# Run Golden Model
# ============================================================

print("\nProcessing image with Sobel-X...")

output = sobel_x_filter(
    image,
    KERNEL
)


# ============================================================
# Output information
# ============================================================

OUTPUT_HEIGHT, OUTPUT_WIDTH = output.shape

print("\nGolden model completed")

print("Output dimensions:")
print(OUTPUT_HEIGHT, "x", OUTPUT_WIDTH)

print("Number of output pixels:")
print(output.size)

print("Minimum output:", output.min())
print("Maximum output:", output.max())


# ============================================================
# Expected output size
#
# 128x128 input
# 3x3 kernel
#
# Output = (128-3+1) x (128-3+1)
#        = 126 x 126
# ============================================================

expected_height = IMAGE_HEIGHT - 3 + 1
expected_width = IMAGE_WIDTH - 3 + 1

expected_outputs = (
    expected_height * expected_width
)

print("\nExpected output dimensions:")
print(
    expected_height,
    "x",
    expected_width
)

print("Expected number of outputs:")
print(expected_outputs)


# ============================================================
# Verify dimensions
# ============================================================

if output.shape == (
    expected_height,
    expected_width
):

    print("\nGOLDEN MODEL: PASS")

else:

    print("\nGOLDEN MODEL: FAIL")


# ============================================================
# Save numerical golden output
# ============================================================

np.savetxt(
    OUTPUT_TEXT,
    output.flatten(),
    fmt="%d"
)

print("\nGolden output saved to:")
print(OUTPUT_TEXT)


# ============================================================
# Verify saved output count
# ============================================================

saved_values = np.loadtxt(
    OUTPUT_TEXT,
    dtype=np.int32
)

saved_values = np.atleast_1d(saved_values)

if len(saved_values) == expected_outputs:

    print("Saved output count:", len(saved_values))
    print("OUTPUT FILE: PASS")

else:

    print("Saved output count:", len(saved_values))
    print("OUTPUT FILE: FAIL")


# ============================================================
# Create visual Sobel-X PNG
#
# Convert signed result into visible 8-bit image.
# Absolute value shows edge strength.
# ============================================================

visual_output = np.abs(output)

max_value = visual_output.max()

if max_value > 0:

    visual_output = (
        visual_output.astype(np.float32)
        / max_value
        * 255.0
    )

visual_output = np.clip(
    visual_output,
    0,
    255
).astype(np.uint8)


# ============================================================
# Save PNG
# ============================================================

Image.fromarray(
    visual_output,
    mode="L"
).save(OUTPUT_PNG)

print("\nVisual Sobel-X image saved to:")
print(OUTPUT_PNG)


# ============================================================
# Final information
# ============================================================

print("\n========================================")
print("       PYTHON GOLDEN MODEL DONE")
print("========================================")

print("\nInput:")
print("tree_input_128x128.png")

print("\nInput size:")
print(
    IMAGE_WIDTH,
    "x",
    IMAGE_HEIGHT
)

print("\nKernel:")
print("3x3 Sobel-X")

print("\nOutput:")
print(
    OUTPUT_WIDTH,
    "x",
    OUTPUT_HEIGHT
)

print("\nTotal outputs:")
print(output.size)

print("\nGolden numerical output:")
print("results/python_golden_output.txt")

print("\nGolden visual output:")
print("results/python_tree_sobel_x.png")

print("\n========================================")