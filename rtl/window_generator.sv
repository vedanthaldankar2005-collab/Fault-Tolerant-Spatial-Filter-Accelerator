module window_generator #(
    parameter IMAGE_WIDTH = 8
)(
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] pixel_in,
    input  logic       pixel_valid,

    output logic [7:0] window0,
    output logic [7:0] window1,
    output logic [7:0] window2,
    output logic [7:0] window3,
    output logic [7:0] window4,
    output logic [7:0] window5,
    output logic [7:0] window6,
    output logic [7:0] window7,
    output logic [7:0] window8,
    output logic       window_valid
);

    logic [7:0] line1 [0:IMAGE_WIDTH-1];
    logic [7:0] line2 [0:IMAGE_WIDTH-1];

    logic [7:0] shift1_0, shift1_1;
    logic [7:0] shift2_0, shift2_1;
    logic [7:0] shift3_0, shift3_1;

    integer col;
    integer row;

    always_ff @(posedge clk) begin

        if (rst) begin

            col <= 0;
            row <= 0;

            shift1_0 <= 0;
            shift1_1 <= 0;

            shift2_0 <= 0;
            shift2_1 <= 0;

            shift3_0 <= 0;
            shift3_1 <= 0;

            window0 <= 0;
            window1 <= 0;
            window2 <= 0;

            window3 <= 0;
            window4 <= 0;
            window5 <= 0;

            window6 <= 0;
            window7 <= 0;
            window8 <= 0;

            window_valid <= 0;

        end

        else if (pixel_valid) begin

            // Shift the pixels from the three rows
            shift1_0 <= shift1_1;
            shift1_1 <= line2[col];

            shift2_0 <= shift2_1;
            shift2_1 <= line1[col];

            shift3_0 <= shift3_1;
            shift3_1 <= pixel_in;

            // Update line buffers
            line2[col] <= line1[col];
            line1[col] <= pixel_in;

            // A complete 3x3 window exists only after
            // two complete rows and at column 2 or later.
            if ((row >= 2) && (col >= 2)) begin

                // Top row
                window0 <= shift1_0;
                window1 <= shift1_1;
                window2 <= line2[col];

                // Middle row
                window3 <= shift2_0;
                window4 <= shift2_1;
                window5 <= line1[col];

                // Bottom row
                window6 <= shift3_0;
                window7 <= shift3_1;
                window8 <= pixel_in;

                window_valid <= 1'b1;

            end
            else begin

                window_valid <= 1'b0;

            end

            // Move to the next pixel.
            // At the end of each row, reset column
            // and move to the next row.
            if (col == IMAGE_WIDTH-1) begin

                col <= 0;
                row <= row + 1;

            end
            else begin

                col <= col + 1;

            end

        end

        else begin

            window_valid <= 1'b0;

        end

    end

endmodule