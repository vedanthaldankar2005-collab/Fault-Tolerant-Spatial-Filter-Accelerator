import numpy as np
from PIL import Image

# ============================================================
# Reconstruct Sobel-X output images
# ============================================================

IMAGE_WIDTH = 126
IMAGE_HEIGHT = 126
TOTAL_OUTPUTS = IMAGE_WIDTH * IMAGE_HEIGHT

PYTHON_FILE = "results/python_golden_output.txt"
RTL_FILE = "results/rtl_image_output.txt"

PYTHON_IMAGE = "results/python_sobel_x.png"
RTL_IMAGE = "results/rtl_sobel_x.png"


def create_image(input_file, output_file):
    # --------------------------------------------------------
    # Read numeric Sobel output
    # --------------------------------------------------------

    values = np.loadtxt(
        input_file,
        dtype=np.int32
    )

    # --------------------------------------------------------
    # Check output count
    # --------------------------------------------------------

    if values.size != TOTAL_OUTPUTS:
        raise ValueError(
            f"{input_file}: expected "
            f"{TOTAL_OUTPUTS} values, found {values.size}"
        )

    # --------------------------------------------------------
    # Reshape 15,876 values into 126 x 126 image
    # --------------------------------------------------------

    image = values.reshape(
        IMAGE_HEIGHT,
        IMAGE_WIDTH
    )

    # --------------------------------------------------------
    # Sobel output contains negative and positive values.
    #
    # Convert:
    #
    # -1020 ... +1020
    #
    # into:
    #
    # 0 ... 255
    #
    # for PNG visualization.
    # --------------------------------------------------------

    min_value = image.min()
    max_value = image.max()

    if max_value == min_value:

        normalized = np.zeros_like(
            image,
            dtype=np.uint8
        )

    else:

        normalized = (
            (image - min_value)
            / (max_value - min_value)
            * 255.0
        ).astype(np.uint8)

    # --------------------------------------------------------
    # Save PNG
    # --------------------------------------------------------

    png_image = Image.fromarray(
        normalized,
        mode="L"
    )

    png_image.save(
        output_file
    )

    print(
        f"Created: {output_file}"
    )

    print(
        f"Size: {IMAGE_WIDTH} x {IMAGE_HEIGHT}"
    )

    print(
        f"Minimum: {min_value}"
    )

    print(
        f"Maximum: {max_value}"
    )


# ============================================================
# Main
# ============================================================

print("========================================")
print("     SOBEL-X IMAGE RECONSTRUCTION")
print("========================================")

print("\nCreating Python Sobel-X image...")

create_image(
    PYTHON_FILE,
    PYTHON_IMAGE
)

print("\nCreating RTL Sobel-X image...")

create_image(
    RTL_FILE,
    RTL_IMAGE
)

print("\n========================================")
print("IMAGE RECONSTRUCTION COMPLETE")
print("========================================")

print(
    f"\nPython image: {PYTHON_IMAGE}"
)

print(
    f"RTL image:    {RTL_IMAGE}"
)