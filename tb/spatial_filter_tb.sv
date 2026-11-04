`timescale 1ns/1ps

module spatial_filter_tb;

    logic       clk;
    logic       rst;
    logic [7:0] pixel_in;
    logic       pixel_valid;

    logic signed [7:0] kernel0;
    logic signed [7:0] kernel1;
    logic signed [7:0] kernel2;

    logic signed [7:0] kernel3;
    logic signed [7:0] kernel4;
    logic signed [7:0] kernel5;

    logic signed [7:0] kernel6;
    logic signed [7:0] kernel7;
    logic signed [7:0] kernel8;

    logic signed [19:0] result;
    logic               result_valid;

    integer i;
    integer output_count;
    integer error_count;

    spatial_filter #(
        .IMAGE_WIDTH(8)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .pixel_in     (pixel_in),
        .pixel_valid  (pixel_valid),

        .kernel0      (kernel0),
        .kernel1      (kernel1),
        .kernel2      (kernel2),

        .kernel3      (kernel3),
        .kernel4      (kernel4),
        .kernel5      (kernel5),

        .kernel6      (kernel6),
        .kernel7      (kernel7),
        .kernel8      (kernel8),

        .result       (result),
        .result_valid (result_valid)
    );

    always #5 clk = ~clk;

    initial begin

        clk          = 0;
        rst          = 1;
        pixel_in     = 0;
        pixel_valid  = 0;
        output_count = 0;
        error_count  = 0;

        // Sobel-X kernel
        kernel0 = -1;
        kernel1 =  0;
        kernel2 =  1;

        kernel3 = -2;
        kernel4 =  0;
        kernel5 =  2;

        kernel6 = -1;
        kernel7 =  0;
        kernel8 =  1;

        // Reset
        #10;

        rst         = 0;
        pixel_valid = 1;

        // Send 8x8 image
        for (i = 0; i < 64; i = i + 1) begin

            pixel_in = i;

            #10;

            if (result_valid) begin

                output_count = output_count + 1;

                $display(
                    "OUTPUT %0d = %0d",
                    output_count,
                    result
                );

                if (result !== 20'sd8) begin

                    error_count = error_count + 1;

                    $display(
                        "ERROR: Expected 8, got %0d",
                        result
                    );

                end

            end

        end

        // Stop input
        pixel_valid = 0;

        // Capture final pipelined result
        #10;

        if (result_valid) begin

            output_count = output_count + 1;

            $display(
                "OUTPUT %0d = %0d",
                output_count,
                result
            );

            if (result !== 20'sd8) begin

                error_count = error_count + 1;

                $display(
                    "ERROR: Expected 8, got %0d",
                    result
                );

            end

        end

        #10;

        // Final verification
        $display("");
        $display("========================================");
        $display("SPATIAL FILTER TEST");
        $display("========================================");

        $display(
            "TOTAL OUTPUTS    = %0d",
            output_count
        );

        $display(
            "EXPECTED OUTPUTS = 36"
        );

        $display(
            "NUMERICAL ERRORS = %0d",
            error_count
        );

        if ((output_count == 36) && (error_count == 0)) begin

            $display("SPATIAL FILTER TEST: PASS");

        end
        else begin

            $display("SPATIAL FILTER TEST: FAIL");

        end

        $display("========================================");

        $finish;

    end

endmodule