module tmr #(
    parameter WIDTH = 20
)(
    input  logic signed [WIDTH-1:0] replica0,
    input  logic signed [WIDTH-1:0] replica1,
    input  logic signed [WIDTH-1:0] replica2,

    output logic signed [WIDTH-1:0] voted_output,
    output logic                    error_detected
);

    // ------------------------------------------------
    // Majority voter
    //
    // For each bit:
    //
    // majority = (A & B) | (A & C) | (B & C)
    // ------------------------------------------------

    always_comb begin

        voted_output =
            (replica0 & replica1) |
            (replica0 & replica2) |
            (replica1 & replica2);

    end

    // ------------------------------------------------
    // Error detection
    //
    // If all three replicas agree:
    //     no error
    //
    // If any replica disagrees:
    //     error detected
    // ------------------------------------------------

    always_comb begin

        if ((replica0 == replica1) &&
            (replica1 == replica2)) begin

            error_detected = 1'b0;

        end
        else begin

            error_detected = 1'b1;

        end

    end

endmodule