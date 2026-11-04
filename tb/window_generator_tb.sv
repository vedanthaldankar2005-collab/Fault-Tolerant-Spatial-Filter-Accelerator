`timescale 1ns/1ps

module window_generator_tb;

    logic       clk;
    logic       rst;
    logic [7:0] pixel_in;
    logic       pixel_valid;

    logic [7:0] window0;
    logic [7:0] window1;
    logic [7:0] window2;
    logic [7:0] window3;
    logic [7:0] window4;
    logic [7:0] window5;
    logic [7:0] window6;
    logic [7:0] window7;
    logic [7:0] window8;
    logic       window_valid;

    integer i;
    integer output_count;

    window_generator #(
        .IMAGE_WIDTH(8)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .pixel_in     (pixel_in),
        .pixel_valid  (pixel_valid),
        .window0      (window0),
        .window1      (window1),
        .window2      (window2),
        .window3      (window3),
        .window4      (window4),
        .window5      (window5),
        .window6      (window6),
        .window7      (window7),
        .window8      (window8),
        .window_valid (window_valid)
    );

    always #5 clk = ~clk;

    initial begin

        clk          = 0;
        rst          = 1;
        pixel_in     = 0;
        pixel_valid  = 0;
        output_count = 0;

        // Reset
        #10;

        rst         = 0;
        pixel_valid = 1;

        // Send 64 pixels for an 8x8 image
        for (i = 0; i < 64; i = i + 1) begin

            pixel_in = i;

            #10;

            if (window_valid) begin

                output_count = output_count + 1;

                $display(
                    "WINDOW %0d: %0d %0d %0d | %0d %0d %0d | %0d %0d %0d",
                    output_count,
                    window0, window1, window2,
                    window3, window4, window5,
                    window6, window7, window8
                );

            end

        end

        pixel_valid = 0;

        #10;

        $display("");
        $display("========================================");
        $display("TOTAL VALID WINDOWS = %0d", output_count);
        $display("EXPECTED WINDOWS    = 36");

        if (output_count == 36) begin
            $display("WINDOW GENERATOR TEST: PASS");
        end
        else begin
            $display("WINDOW GENERATOR TEST: FAIL");
        end

        $display("========================================");

        $finish;

    end

endmodule