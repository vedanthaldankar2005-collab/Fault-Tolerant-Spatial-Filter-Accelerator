module residue_check #(
    parameter WIDTH = 20,
    parameter MODULUS = 31
)(
    input  logic signed [7:0] pixel0,
    input  logic signed [7:0] pixel1,
    input  logic signed [7:0] pixel2,
    input  logic signed [7:0] pixel3,
    input  logic signed [7:0] pixel4,
    input  logic signed [7:0] pixel5,
    input  logic signed [7:0] pixel6,
    input  logic signed [7:0] pixel7,
    input  logic signed [7:0] pixel8,

    input  logic signed [7:0] kernel0,
    input  logic signed [7:0] kernel1,
    input  logic signed [7:0] kernel2,
    input  logic signed [7:0] kernel3,
    input  logic signed [7:0] kernel4,
    input  logic signed [7:0] kernel5,
    input  logic signed [7:0] kernel6,
    input  logic signed [7:0] kernel7,
    input  logic signed [7:0] kernel8,

    input  logic signed [WIDTH-1:0] result,

    output logic residue_error
);

    integer expected_residue;
    integer result_residue;

    integer product_sum;

    always_comb begin

        // ------------------------------------------------
        // Independent reference calculation
        // ------------------------------------------------

        product_sum =
              (pixel0 * kernel0)
            + (pixel1 * kernel1)
            + (pixel2 * kernel2)
            + (pixel3 * kernel3)
            + (pixel4 * kernel4)
            + (pixel5 * kernel5)
            + (pixel6 * kernel6)
            + (pixel7 * kernel7)
            + (pixel8 * kernel8);

        // ------------------------------------------------
        // Convert reference result to modulo-31 residue
        // ------------------------------------------------

        expected_residue = product_sum % MODULUS;

        if (expected_residue < 0)
            expected_residue = expected_residue + MODULUS;

        // ------------------------------------------------
        // Convert actual TMR result to modulo-31 residue
        // ------------------------------------------------

        result_residue = result % MODULUS;

        if (result_residue < 0)
            result_residue = result_residue + MODULUS;

        // ------------------------------------------------
        // Residue comparison
        // ------------------------------------------------

        if (expected_residue != result_residue)
            residue_error = 1'b1;
        else
            residue_error = 1'b0;

    end

endmodule