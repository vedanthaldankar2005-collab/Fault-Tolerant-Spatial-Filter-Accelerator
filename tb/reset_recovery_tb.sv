`timescale 1ns/1ps

module reset_recovery_tb;

    logic        clk;
    logic        rst;

    // ------------------------------------------------
    // AXI4-Lite interface
    // ------------------------------------------------

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

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    // ------------------------------------------------
    // Pixel input
    // ------------------------------------------------

    logic [7:0] pixel_in;
    logic       pixel_valid;

    // ------------------------------------------------
    // Accelerator output
    // ------------------------------------------------

    logic signed [19:0] result;
    logic               result_valid;

    logic busy;
    logic done;
    logic error;

    // ------------------------------------------------
    // Test variables
    // ------------------------------------------------

    integer i;
    integer j;
    integer output_count;
    integer error_count;

    logic [31:0] read_data;

    // ------------------------------------------------
    // Device Under Test
    // ------------------------------------------------

    accelerator_top #(
        .IMAGE_WIDTH(8)
    ) dut (
        .clk           (clk),
        .rst           (rst),

        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),

        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),

        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),

        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),

        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),

        .pixel_in      (pixel_in),
        .pixel_valid   (pixel_valid),

        .result        (result),
        .result_valid  (result_valid),

        .busy          (busy),
        .done          (done),
        .error         (error)
    );

    // ------------------------------------------------
    // Clock
    // ------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------
    // AXI Write Task
    // ------------------------------------------------

    task axi_write;
        input [31:0] address;
        input [31:0] data;

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

    // ------------------------------------------------
    // AXI Read Task
    // ------------------------------------------------

    task axi_read;
        input  [31:0] address;
        output [31:0] data;

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

    // ------------------------------------------------
    // Main Test
    // ------------------------------------------------

    initial begin

        // ------------------------------------------------
        // Initial conditions
        // ------------------------------------------------

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

        output_count = 0;
        error_count  = 0;

        // ------------------------------------------------
        // Initial Reset
        // ------------------------------------------------

        @(posedge clk);
        #1;

        if ((busy !== 1'b0) ||
            (done  !== 1'b0) ||
            (error !== 1'b0)) begin

            $display("ERROR: Initial reset state is incorrect");
            error_count = error_count + 1;

        end

        #20;

        rst = 1'b0;

        #10;

        // ------------------------------------------------
        // Program Identity Kernel
        // ------------------------------------------------

        $display("");
        $display("Programming identity kernel...");

        // Identity kernel:
        //
        // 0 0 0
        // 0 1 0
        // 0 0 0

        axi_write(32'h08, 32'h0000_0000);
        axi_write(32'h0C, 32'h0000_0000);
        axi_write(32'h10, 32'h0000_0000);

        axi_write(32'h14, 32'h0000_0000);
        axi_write(32'h18, 32'h0000_0001);
        axi_write(32'h1C, 32'h0000_0000);

        axi_write(32'h20, 32'h0000_0000);
        axi_write(32'h24, 32'h0000_0000);
        axi_write(32'h28, 32'h0000_0000);

        // ------------------------------------------------
        // Start Accelerator
        // ------------------------------------------------

        $display("Starting accelerator...");

        axi_write(32'h00, 32'h0000_0001);

        #1;

        if (busy !== 1'b1) begin

            $display("ERROR: BUSY did not assert");
            error_count = error_count + 1;

        end

        // ------------------------------------------------
        // Send 8x8 Image
        // ------------------------------------------------

        pixel_valid = 1'b1;

        for (i = 0; i < 64; i = i + 1) begin

            pixel_in = i;

            #10;

            if (result_valid) begin

                output_count = output_count + 1;

            end

        end

        // ------------------------------------------------
        // Stop input
        // ------------------------------------------------

        pixel_valid = 1'b0;

        // ------------------------------------------------
        // Capture remaining pipeline outputs
        // ------------------------------------------------

        // Allow several clock cycles for the final
        // window/result to propagate through the pipeline.

        for (j = 0; j < 4; j = j + 1) begin

            #10;

            if (result_valid) begin

                output_count = output_count + 1;

            end

        end

        // ------------------------------------------------
        // Verify completed operation
        // ------------------------------------------------

        if (output_count != 36) begin

            $display(
                "ERROR: Expected 36 outputs, got %0d",
                output_count
            );

            error_count = error_count + 1;

        end

        if (done !== 1'b1) begin

            $display("ERROR: DONE did not assert");

            error_count = error_count + 1;

        end

        if (error !== 1'b0) begin

            $display("ERROR: Unexpected ERROR flag");

            error_count = error_count + 1;

        end

        $display("");
        $display("PROCESSING COMPLETE");
        $display("OUTPUT COUNT = %0d", output_count);
        $display("DONE         = %0d", done);
        $display("ERROR        = %0d", error);

        // ------------------------------------------------
        // Reset after completed operation
        // ------------------------------------------------

        $display("");
        $display("Applying reset after completed operation...");

        rst = 1'b1;

        @(posedge clk);
        #1;

        // ------------------------------------------------
        // Verify reset recovery
        // ------------------------------------------------

        if ((busy !== 1'b0) ||
            (done  !== 1'b0) ||
            (error !== 1'b0)) begin

            $display("ERROR: Reset recovery failed");

            error_count = error_count + 1;

        end
        else begin

            $display("Reset recovery successful");

        end

        // ------------------------------------------------
        // Final result
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("RESET RECOVERY TEST");
        $display("========================================");

        $display(
            "OUTPUTS BEFORE RESET = %0d",
            output_count
        );

        $display(
            "EXPECTED OUTPUTS     = 36"
        );

        $display(
            "BUSY AFTER RESET     = %0d",
            busy
        );

        $display(
            "DONE AFTER RESET     = %0d",
            done
        );

        $display(
            "ERROR AFTER RESET    = %0d",
            error
        );

        $display(
            "NUMERICAL ERRORS     = %0d",
            error_count
        );

        if ((output_count == 36) &&
            (error_count == 0) &&
            (busy == 1'b0) &&
            (done == 1'b0) &&
            (error == 1'b0)) begin

            $display("RESET RECOVERY TEST: PASS");

        end
        else begin

            $display("RESET RECOVERY TEST: FAIL");

        end

        $display("========================================");

        $finish;

    end

endmodule