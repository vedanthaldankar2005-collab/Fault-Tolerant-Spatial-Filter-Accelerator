import numpy as np

# ============================================================
# RTL vs Python Golden Model Comparison
# ============================================================

PYTHON_FILE = "results/python_golden_output.txt"
RTL_FILE = "results/rtl_tree_sobel_x_output.txt"
REPORT_FILE = "results/rtl_vs_python_report.txt"


print("==============================================")
print("       RTL vs PYTHON GOLDEN MODEL")
print("==============================================")

# ============================================================
# Load Python golden-model results
# ============================================================

python_output = np.loadtxt(
    PYTHON_FILE,
    dtype=np.int32
)

print("\nPython output file:")
print(PYTHON_FILE)

print("Python output count:", len(python_output))


# ============================================================
# Load RTL results
# ============================================================

rtl_output = np.loadtxt(
    RTL_FILE,
    dtype=np.int32
)

print("\nRTL output file:")
print(RTL_FILE)

print("RTL output count:", len(rtl_output))


# ============================================================
# Compare output counts
# ============================================================

print("\n----------------------------------------------")
print("OUTPUT COUNT CHECK")
print("----------------------------------------------")

if len(python_output) == len(rtl_output):

    print("Python outputs:", len(python_output))
    print("RTL outputs   :", len(rtl_output))
    print("OUTPUT COUNT: PASS")

else:

    print("Python outputs:", len(python_output))
    print("RTL outputs   :", len(rtl_output))
    print("OUTPUT COUNT: FAIL")


# ============================================================
# Compare values
# ============================================================

minimum_count = min(
    len(python_output),
    len(rtl_output)
)

python_compare = python_output[:minimum_count]
rtl_compare = rtl_output[:minimum_count]

difference = python_compare - rtl_compare

mismatch_indices = np.where(
    difference != 0
)[0]

mismatch_count = len(
    mismatch_indices
)


# ============================================================
# Display comparison result
# ============================================================

print("\n----------------------------------------------")
print("VALUE COMPARISON")
print("----------------------------------------------")

print(
    "Values compared:",
    minimum_count
)

print(
    "Mismatches:",
    mismatch_count
)

if mismatch_count == 0 and len(python_output) == len(rtl_output):

    print("\nALL OUTPUTS MATCH")
    print("RTL vs Python: PASS")

else:

    print("\nOUTPUT MISMATCH DETECTED")
    print("RTL vs Python: FAIL")


# ============================================================
# Display mismatch information
# ============================================================

if mismatch_count > 0:

    print("\nFirst 10 mismatches:")

    for index in mismatch_indices[:10]:

        print(
            "Index:",
            index,
            "Python:",
            python_output[index],
            "RTL:",
            rtl_output[index],
            "Difference:",
            difference[index]
        )


# ============================================================
# Output ranges
# ============================================================

print("\n----------------------------------------------")
print("OUTPUT RANGES")
print("----------------------------------------------")

print(
    "Python minimum:",
    python_output.min()
)

print(
    "Python maximum:",
    python_output.max()
)

print(
    "RTL minimum:",
    rtl_output.min()
)

print(
    "RTL maximum:",
    rtl_output.max()
)


# ============================================================
# Save comparison report
# ============================================================

with open(REPORT_FILE, "w") as report:

    report.write("RTL vs Python Golden Model Report\n")
    report.write("=================================\n\n")

    report.write(
        f"Python output count: {len(python_output)}\n"
    )

    report.write(
        f"RTL output count: {len(rtl_output)}\n"
    )

    report.write(
        f"Values compared: {minimum_count}\n"
    )

    report.write(
        f"Mismatches: {mismatch_count}\n"
    )

    report.write(
        f"Python range: {python_output.min()} to "
        f"{python_output.max()}\n"
    )

    report.write(
        f"RTL range: {rtl_output.min()} to "
        f"{rtl_output.max()}\n"
    )

    if mismatch_count == 0 and len(python_output) == len(rtl_output):

        report.write("\nALL OUTPUTS MATCH\n")
        report.write("RTL vs Python: PASS\n")

    else:

        report.write("\nOUTPUT MISMATCH DETECTED\n")
        report.write("RTL vs Python: FAIL\n")

        if mismatch_count > 0:

            report.write("\nFirst 10 mismatches:\n")

            for index in mismatch_indices[:10]:

                report.write(
                    f"Index {index}: "
                    f"Python={python_output[index]}, "
                    f"RTL={rtl_output[index]}, "
                    f"Difference={difference[index]}\n"
                )


print("\n----------------------------------------------")
print("REPORT")
print("----------------------------------------------")

print(
    "Comparison report saved to:"
)

print(REPORT_FILE)

print("\n==============================================")
print("       COMPARISON COMPLETE")
print("==============================================")