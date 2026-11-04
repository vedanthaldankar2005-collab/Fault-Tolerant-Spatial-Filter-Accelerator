module mac (
    // ============================================================
    // 8-bit UNSIGNED pixels
    // ============================================================

    input  logic [7:0] pixel0,
    input  logic [7:0] pixel1,
    input  logic [7:0] pixel2,
    input  logic [7:0] pixel3,
    input  logic [7:0] pixel4,
    input  logic [7:0] pixel5,
    input  logic [7:0] pixel6,
    input  logic [7:0] pixel7,
    input  logic [7:0] pixel8,

    // ============================================================
    // 8-bit SIGNED kernel coefficients
    // ============================================================

    input logic signed [7:0] kernel0,
    input logic signed [7:0] kernel1,
    input logic signed [7:0] kernel2,
    input logic signed [7:0] kernel3,
    input logic signed [7:0] kernel4,
    input logic signed [7:0] kernel5,
    input logic signed [7:0] kernel6,
    input logic signed [7:0] kernel7,
    input logic signed [7:0] kernel8,

    // ============================================================
    // 20-bit signed accumulated result
    // ============================================================

    output logic signed [19:0] result
);

    // ============================================================
    // Convert unsigned 8-bit pixels to signed 9-bit values
    //
    // 8'hFF = 255
    //
    // After adding a leading zero:
    //
    // 9'b0_11111111 = +255
    //
    // This prevents 255 from becoming -1.
    // ============================================================

    logic signed [8:0] pixel0_signed;
    logic signed [8:0] pixel1_signed;
    logic signed [8:0] pixel2_signed;
    logic signed [8:0] pixel3_signed;
    logic signed [8:0] pixel4_signed;
    logic signed [8:0] pixel5_signed;
    logic signed [8:0] pixel6_signed;
    logic signed [8:0] pixel7_signed;
    logic signed [8:0] pixel8_signed;

    // ============================================================
    // 17-bit signed multiplication results
    //
    // 9-bit pixel × 8-bit signed kernel = 17-bit signed product
    // ============================================================

    logic signed [16:0] product0;
    logic signed [16:0] product1;
    logic signed [16:0] product2;
    logic signed [16:0] product3;
    logic signed [16:0] product4;
    logic signed [16:0] product5;
    logic signed [16:0] product6;
    logic signed [16:0] product7;
    logic signed [16:0] product8;

    // ============================================================
    // Combinational MAC
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // Explicitly convert pixels from unsigned 8-bit
        // to positive signed 9-bit values.
        // --------------------------------------------------------

        pixel0_signed = {1'b0, pixel0};
        pixel1_signed = {1'b0, pixel1};
        pixel2_signed = {1'b0, pixel2};

        pixel3_signed = {1'b0, pixel3};
        pixel4_signed = {1'b0, pixel4};
        pixel5_signed = {1'b0, pixel5};

        pixel6_signed = {1'b0, pixel6};
        pixel7_signed = {1'b0, pixel7};
        pixel8_signed = {1'b0, pixel8};

        // --------------------------------------------------------
        // Nine parallel multiplications
        // --------------------------------------------------------

        product0 = pixel0_signed * kernel0;
        product1 = pixel1_signed * kernel1;
        product2 = pixel2_signed * kernel2;

        product3 = pixel3_signed * kernel3;
        product4 = pixel4_signed * kernel4;
        product5 = pixel5_signed * kernel5;

        product6 = pixel6_signed * kernel6;
        product7 = pixel7_signed * kernel7;
        product8 = pixel8_signed * kernel8;

        // --------------------------------------------------------
        // Accumulate all nine products.
        //
        // Each 17-bit product is sign-extended to 20 bits
        // before addition.
        // --------------------------------------------------------

        result =
              {{3{product0[16]}}, product0}
            + {{3{product1[16]}}, product1}
            + {{3{product2[16]}}, product2}
            + {{3{product3[16]}}, product3}
            + {{3{product4[16]}}, product4}
            + {{3{product5[16]}}, product5}
            + {{3{product6[16]}}, product6}
            + {{3{product7[16]}}, product7}
            + {{3{product8[16]}}, product8};

    end

endmodule