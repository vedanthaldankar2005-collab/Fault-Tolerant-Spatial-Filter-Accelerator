`timescale 1ns/1ps

module accelerator_top_tb;

    logic clk;
    logic rst;

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

    logic [7:0] pixel_in;
    logic       pixel_valid;

    logic signed [19:0] result;
    logic               result_valid;

    logic busy;
    logic done;
    logic error;

    integer i;
    integer output_count;
    integer error_count;
    integer expected_result;

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

        output_count    = 0;
        error_count     = 0;
        expected_result = 0;

        // ------------------------------------------------
        // Reset
        // ------------------------------------------------

        @(posedge clk);
        #1;

        if ((busy !== 1'b0) ||
            (done  !== 1'b0) ||
            (error !== 1'b0)) begin

            $display("ERROR: Reset state is incorrect");
            error_count = error_count + 1;

        end

        #20;

        rst = 1'b0;

        #10;

        // ------------------------------------------------
        // Identity Kernel
        //
        // 0 0 0
        // 0 1 0
        // 0 0 0
        // ------------------------------------------------

        $display("");
        $display("Programming identity kernel through AXI...");

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
        // Readback
        // ------------------------------------------------

        axi_read(32'h08, read_data);

        if (read_data !== 32'h0000_0000) begin

            $display(
                "ERROR: Kernel readback failed: %h",
                read_data
            );

            error_count = error_count + 1;

        end
        else begin

            $display(
                "Kernel readback successful: %h",
                read_data
            );

        end

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
        // Pixel values = 0 to 63
        // ------------------------------------------------

        pixel_valid = 1'b1;

        for (i = 0; i < 64; i = i + 1) begin

            pixel_in = i;

            #10;

            if (result_valid) begin

                expected_result = i - 10;

                output_count = output_count + 1;

                $display(
                    "OUTPUT %0d = %0d",
                    output_count,
                    result
                );

                if (result !== expected_result) begin

                    error_count = error_count + 1;

                    $display(
                        "ERROR: Expected %0d, got %0d",
                        expected_result,
                        result
                    );

                end

            end

        end

        pixel_valid = 1'b0;

        // ------------------------------------------------
        // Final pipelined output
        // ------------------------------------------------

        #10;

        if (result_valid) begin

            output_count = output_count + 1;
            expected_result = 54;

            $display(
                "OUTPUT %0d = %0d",
                output_count,
                result
            );

            if (result !== expected_result) begin

                error_count = error_count + 1;

                $display(
                    "ERROR: Expected %0d, got %0d",
                    expected_result,
                    result
                );

            end

        end

        // ------------------------------------------------
        // Final Status
        // ------------------------------------------------

        #10;

        axi_read(32'h04, read_data);

        $display("");
        $display(
            "STATUS REGISTER = %h",
            read_data
        );

        // ------------------------------------------------
        // Final Verification
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("COMPLETE ACCELERATOR TEST");
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

        $display(
            "DONE              = %0d",
            done
        );

        $display(
            "ERROR             = %0d",
            error
        );

        if ((output_count == 36) &&
            (error_count == 0) &&
            (done == 1'b1) &&
            (error == 1'b0)) begin

            $display("COMPLETE ACCELERATOR TEST: PASS");

        end
        else begin

            $display("COMPLETE ACCELERATOR TEST: FAIL");

        end

        $display("========================================");

        $finish;

    end

endmodule