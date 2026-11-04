`timescale 1ns/1ps

module tb_residue;

    // ============================================================
    // CLOCK / RESET
    // ============================================================
    logic clk;
    logic rst;

    // ============================================================
    // AXI4-LITE WRITE CHANNEL
    // ============================================================
    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;

    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    logic        s_axi_wready;

    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;

    // ============================================================
    // AXI4-LITE READ CHANNEL
    // ============================================================
    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    // ============================================================
    // PIXEL / RESULT INTERFACE
    // ============================================================
    logic [7:0] pixel_in;
    logic       pixel_valid;

    logic signed [19:0] result;
    logic               result_valid;

    logic busy;
    logic done;
    logic error;

    // ============================================================
    // TEST VARIABLES
    // ============================================================
    logic [31:0] read_data;

    integer error_count;
    integer output_count;
    integer expected_result;

    // ============================================================
    // DUT
    // ============================================================
    accelerator_top #(
        .IMAGE_WIDTH(8)
    ) dut (
        .clk              (clk),
        .rst              (rst),

        // AXI WRITE
        .s_axi_awaddr     (s_axi_awaddr),
        .s_axi_awvalid    (s_axi_awvalid),
        .s_axi_awready    (s_axi_awready),

        .s_axi_wdata      (s_axi_wdata),
        .s_axi_wstrb      (s_axi_wstrb),
        .s_axi_wvalid     (s_axi_wvalid),
        .s_axi_wready     (s_axi_wready),

        .s_axi_bresp      (s_axi_bresp),
        .s_axi_bvalid     (s_axi_bvalid),
        .s_axi_bready     (s_axi_bready),

        // AXI READ
        .s_axi_araddr     (s_axi_araddr),
        .s_axi_arvalid    (s_axi_arvalid),
        .s_axi_arready    (s_axi_arready),

        .s_axi_rdata      (s_axi_rdata),
        .s_axi_rresp      (s_axi_rresp),
        .s_axi_rvalid     (s_axi_rvalid),
        .s_axi_rready     (s_axi_rready),

        // PIXEL STREAM
        .pixel_in         (pixel_in),
        .pixel_valid      (pixel_valid),

        // RESULT
        .result           (result),
        .result_valid     (result_valid),

        // STATUS
        .busy             (busy),
        .done             (done),
        .error            (error)
    );

    // ============================================================
    // CLOCK
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // AXI WRITE TASK
    // ============================================================
    task automatic axi_write(
        input [31:0] address,
        input [31:0] data
    );
        begin
            @(negedge clk);

            s_axi_awaddr  = address;
            s_axi_awvalid = 1'b1;

            s_axi_wdata   = data;
            s_axi_wstrb   = 4'b0001;
            s_axi_wvalid  = 1'b1;

            @(posedge clk);
            #1;

            s_axi_awvalid = 1'b0;
            s_axi_wvalid  = 1'b0;

            wait (s_axi_bvalid == 1'b1);

            @(negedge clk);
            s_axi_bready = 1'b1;

            @(posedge clk);
            #1;

            s_axi_bready = 1'b0;
        end
    endtask

    // ============================================================
    // AXI READ TASK
    // ============================================================
    task automatic axi_read(
        input  [31:0] address,
        output [31:0] data
    );
        begin
            @(negedge clk);

            s_axi_araddr  = address;
            s_axi_arvalid = 1'b1;

            @(posedge clk);
            #1;

            s_axi_arvalid = 1'b0;

            wait (s_axi_rvalid == 1'b1);

            #1;
            data = s_axi_rdata;

            @(negedge clk);
            s_axi_rready = 1'b1;

            @(posedge clk);
            #1;

            s_axi_rready = 1'b0;
        end
    endtask

    // ============================================================
    // CHECK RESULT TASK
    // ============================================================
    task automatic check_result;
        begin
            if (result_valid == 1'b1) begin

                // Count this valid result exactly once.
                output_count = output_count + 1;

                // ------------------------------------------------
                // Identity-kernel expected result
                //
                // Image:
                //   0   1   2   3   ...   7
                //   8   9  10  11   ...  15
                //   ...
                //
                // For a 3x3 valid window, the center pixels are:
                //
                //   9  10  11  12  13  14
                //  17  18  19  20  21  22
                //  25  26  27  28  29  30
                //  33  34  35  36  37  38
                //  41  42  43  44  45  46
                //  49  50  51  52  53  54
                //
                // Therefore each new row increases by 8.
                // ------------------------------------------------
                expected_result =
                    9
                    + (((output_count - 1) / 6) * 8)
                    + ((output_count - 1) % 6);

                $display(
                    "Output %0d = %0d, expected = %0d",
                    output_count,
                    result,
                    expected_result
                );

                if (result !== expected_result) begin
                    $display(
                        "ERROR: Result mismatch at output %0d",
                        output_count
                    );

                    error_count = error_count + 1;
                end

                // ------------------------------------------------
                // Residue checker must remain clear during
                // fault-free operation.
                // ------------------------------------------------
                if ((dut.residue_error0 !== 1'b0) ||
                    (dut.residue_error1 !== 1'b0) ||
                    (dut.residue_error2 !== 1'b0)) begin

                    $display(
                        "ERROR: Unexpected residue error at output %0d",
                        output_count
                    );

                    error_count = error_count + 1;
                end

                // ------------------------------------------------
                // Unified top-level error must remain clear.
                // ------------------------------------------------
                if (error !== 1'b0) begin

                    $display(
                        "ERROR: Top-level error unexpectedly asserted at output %0d",
                        output_count
                    );

                    error_count = error_count + 1;
                end

            end
        end
    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin

        // --------------------------------------------------------
        // INITIALIZATION
        // --------------------------------------------------------
        clk = 1'b0;
        rst = 1'b1;

        s_axi_awaddr  = 32'd0;
        s_axi_awvalid = 1'b0;
        s_axi_wdata   = 32'd0;
        s_axi_wstrb   = 4'd0;
        s_axi_wvalid  = 1'b0;
        s_axi_bready  = 1'b0;

        s_axi_araddr  = 32'd0;
        s_axi_arvalid = 1'b0;
        s_axi_rready  = 1'b0;

        pixel_in      = 8'd0;
        pixel_valid   = 1'b0;

        read_data     = 32'd0;

        error_count   = 0;
        output_count  = 0;
        expected_result = 0;

        // ========================================================
        // TEST HEADER
        // ========================================================
        $display("");
        $display("============================================================");
        $display("             PHASE 2 - RESIDUE CHECK TEST");
        $display("============================================================");
        $display("");

        // ========================================================
        // RESET
        // ========================================================
        $display("Applying reset...");

        repeat (5) @(posedge clk);

        rst = 1'b0;

        repeat (2) @(posedge clk);

        if (busy == 1'b0) begin
            $display("Reset check: PASS");
        end
        else begin
            $display("ERROR: Reset check failed");
            error_count = error_count + 1;
        end

        // ========================================================
        // PROGRAM IDENTITY KERNEL
        // ========================================================
        $display("");
        $display("Programming identity kernel...");

        // Kernel:
        //
        // 0 0 0
        // 0 1 0
        // 0 0 0
        //
        // AXI addresses:
        // 0x08 -> kernel0
        // 0x0C -> kernel1
        // 0x10 -> kernel2
        // 0x14 -> kernel3
        // 0x18 -> kernel4
        // 0x1C -> kernel5
        // 0x20 -> kernel6
        // 0x24 -> kernel7
        // 0x28 -> kernel8

        axi_write(32'h00000008, 32'h00000000);
        axi_write(32'h0000000C, 32'h00000000);
        axi_write(32'h00000010, 32'h00000000);

        axi_write(32'h00000014, 32'h00000000);
        axi_write(32'h00000018, 32'h00000001);
        axi_write(32'h0000001C, 32'h00000000);

        axi_write(32'h00000020, 32'h00000000);
        axi_write(32'h00000024, 32'h00000000);
        axi_write(32'h00000028, 32'h00000000);

        #2;

        if (dut.regs.kernel_parity_err == 1'b0) begin
            $display("Kernel programming: PASS");
        end
        else begin
            $display("ERROR: Kernel parity error after programming");
            error_count = error_count + 1;
        end

        // ========================================================
        // START ACCELERATOR
        // ========================================================
        $display("");
        $display("Starting accelerator...");

        axi_write(32'h00000000, 32'h00000001);

        repeat (2) @(posedge clk);

        // ========================================================
        // SEND 8x8 IMAGE
        //
        // Pixels:
        // 0 through 63
        // ========================================================
        $display("");
        $display("Sending image data...");

        for (integer i = 0; i < 64; i = i + 1) begin

            @(negedge clk);

            pixel_in    = i[7:0];
            pixel_valid = 1'b1;

            @(posedge clk);
            #1;

            check_result();

        end

        // Stop input stream.
        @(negedge clk);

        pixel_valid = 1'b0;
        pixel_in    = 8'd0;

        // ========================================================
        // DRAIN PIPELINE
        //
        // Give the accelerator enough cycles to produce the
        // remaining valid windows.
        //
        // The check_result task counts only actual result_valid
        // events, and we require exactly 36 total results.
        // ========================================================
        for (integer j = 0; j < 20; j = j + 1) begin

            @(posedge clk);
            #1;

            if (output_count < 36) begin
                check_result();
            end

        end

        // ========================================================
        // CHECK OUTPUT COUNT
        // ========================================================
        $display("");
        $display(
            "Normal output count = %0d",
            output_count
        );

        if (output_count == 36) begin
            $display("Output count check: PASS");
        end
        else begin
            $display(
                "ERROR: Expected 36 outputs, received %0d",
                output_count
            );

            error_count = error_count + 1;
        end

        // ========================================================
        // CHECK RESIDUE FLAGS
        // ========================================================
        if ((dut.residue_error0 == 1'b0) &&
            (dut.residue_error1 == 1'b0) &&
            (dut.residue_error2 == 1'b0)) begin

            $display("Normal residue operation: PASS");

        end
        else begin

            $display(
                "ERROR: Residue error asserted during normal operation"
            );

            error_count = error_count + 1;
        end

        // ========================================================
        // CHECK TOP-LEVEL ERROR
        // ========================================================
        if (error == 1'b0) begin
            $display("Normal accelerator error status: PASS");
        end
        else begin
            $display("ERROR: Top-level error unexpectedly asserted");
            error_count = error_count + 1;
        end

        // ========================================================
        // READ STATUS
        // ========================================================
        axi_read(32'h00000004, read_data);

        $display(
            "STATUS before residue fault = %08h",
            read_data
        );

        // ========================================================
        // BASELINE SUMMARY
        // ========================================================
        $display("");
        $display("============================================================");
        $display("          RESIDUE TESTBENCH BASELINE SUMMARY");
        $display("============================================================");

        $display("Expected outputs = 36");
        $display("Actual outputs   = %0d", output_count);
        $display("Test errors      = %0d", error_count);

        if (error_count == 0) begin
            $display("");
            $display("RESIDUE BASELINE TEST: PASS");
        end
        else begin
            $display("");
            $display("RESIDUE BASELINE TEST: FAIL");
        end

        $display("============================================================");
        $display("");

        $finish;
    end

endmodule