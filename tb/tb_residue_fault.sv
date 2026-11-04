`timescale 1ns/1ps

module tb_residue_fault;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;

    // ============================================================
    // AXI4-LITE SIGNALS
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

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    // ============================================================
    // PIXEL INTERFACE
    // ============================================================

    logic [7:0] pixel_in;
    logic       pixel_valid;

    // ============================================================
    // OUTPUTS
    // ============================================================

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
    integer residue_detection_count;
    integer i;

    // ============================================================
    // DUT
    // ============================================================

    accelerator_top #(
        .IMAGE_WIDTH(8)
    ) dut (
        .clk(clk),
        .rst(rst),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),

        .result(result),
        .result_valid(result_valid),

        .busy(busy),
        .done(done),
        .error(error)
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
    // TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIAL VALUES
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

        read_data = 32'd0;

        error_count = 0;
        residue_detection_count = 0;

        // --------------------------------------------------------
        // HEADER
        // --------------------------------------------------------

        $display("");
        $display("============================================================");
        $display("       RESIDUE SINGLE-BIT FAULT-INJECTION TEST");
        $display("============================================================");
        $display("");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        $display("Applying reset...");

        repeat (5) begin
            @(posedge clk);
        end

        rst = 1'b0;

        repeat (2) begin
            @(posedge clk);
        end

        if (busy == 1'b0) begin
            $display("Reset check: PASS");
        end
        else begin
            $display("ERROR: Reset check failed");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // PROGRAM IDENTITY KERNEL
        //
        //       0 0 0
        //       0 1 0
        //       0 0 0
        //
        // --------------------------------------------------------

        $display("");
        $display("Programming identity kernel...");

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
            $display("ERROR: Kernel parity error");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // INITIAL RESIDUE STATUS
        // --------------------------------------------------------

        if ((dut.residue_error0 == 1'b0) &&
            (dut.residue_error1 == 1'b0) &&
            (dut.residue_error2 == 1'b0)) begin

            $display("Initial residue status: PASS");

        end
        else begin

            $display("ERROR: Residue error already asserted");
            error_count = error_count + 1;

        end

        // --------------------------------------------------------
        // START ACCELERATOR
        // --------------------------------------------------------

        $display("");
        $display("Starting accelerator...");

        axi_write(32'h00000000, 32'h00000001);

        repeat (2) begin
            @(posedge clk);
        end

        // --------------------------------------------------------
        // FAULT INJECTION
        //
        // Force replica 0 MAC result to zero.
        //
        // For the identity-kernel 8x8 image, valid results are
        // non-zero, so the residue checker should detect the
        // corrupted MAC result.
        // --------------------------------------------------------

        $display("");
        $display("Injecting fault into replica 0 MAC result...");
        $display("Target = dut.filter0.mac_result");

        force dut.filter0.mac_result = 20'sd0;

        #2;

        $display(
            "Forced MAC result = %0d",
            dut.filter0.mac_result
        );

        // --------------------------------------------------------
        // SEND IMAGE
        // --------------------------------------------------------

        $display("");
        $display("Sending 8x8 image...");

        for (i = 0; i < 64; i = i + 1) begin

            @(negedge clk);

            pixel_in    = i;
            pixel_valid = 1'b1;

            @(posedge clk);
            #1;

            if (dut.residue_error0 == 1'b1) begin

                residue_detection_count =
                    residue_detection_count + 1;

                $display(
                    "Residue fault detected at pixel %0d",
                    i
                );

            end

        end

        // --------------------------------------------------------
        // STOP PIXEL INPUT
        // --------------------------------------------------------

        @(negedge clk);

        pixel_valid = 1'b0;
        pixel_in    = 8'd0;

        // --------------------------------------------------------
        // ALLOW REMAINING PIPELINE ACTIVITY
        // --------------------------------------------------------

        repeat (15) begin

            @(posedge clk);
            #1;

            if (dut.residue_error0 == 1'b1) begin

                residue_detection_count =
                    residue_detection_count + 1;

            end

        end

        // --------------------------------------------------------
        // RESIDUE DETECTION RESULT
        // --------------------------------------------------------

        $display("");
        $display("============================================================");
        $display("              RESIDUE DETECTION RESULT");
        $display("============================================================");

        $display(
            "Residue detection count = %0d",
            residue_detection_count
        );

        if (residue_detection_count > 0) begin

            $display("RESIDUE FAULT DETECTION: PASS");

        end
        else begin

            $display(
                "ERROR: Replica 0 residue checker did not detect fault"
            );

            error_count = error_count + 1;

        end

        // --------------------------------------------------------
        // TOP LEVEL ERROR
        // --------------------------------------------------------

        $display("");
        $display(
            "Top-level error signal = %0d",
            error
        );

        if (error == 1'b1) begin

            $display("TOP-LEVEL ERROR PROPAGATION: PASS");

        end
        else begin

            $display(
                "ERROR: Residue fault did not propagate to top-level error"
            );

            error_count = error_count + 1;

        end

        // --------------------------------------------------------
        // STATUS REGISTER
        // --------------------------------------------------------

        axi_read(32'h00000004, read_data);

        $display(
            "STATUS during injected fault = %08h",
            read_data
        );

        // --------------------------------------------------------
        // RELEASE FAULT
        // --------------------------------------------------------

        $display("");
        $display("Releasing injected fault...");

        release dut.filter0.mac_result;

        #2;

        $display(
            "MAC result after release = %0d",
            dut.filter0.mac_result
        );

        // --------------------------------------------------------
        // SUMMARY
        // --------------------------------------------------------

        $display("");
        $display("============================================================");
        $display("          RESIDUE FAULT-INJECTION TEST SUMMARY");
        $display("============================================================");

        $display(
            "Injected fault    = filter0.mac_result forced to 0"
        );

        $display(
            "Residue detections = %0d",
            residue_detection_count
        );

        $display(
            "Final test errors  = %0d",
            error_count
        );

        if (error_count == 0) begin

            $display("");
            $display("RESIDUE FAULT-INJECTION TEST: PASS");

        end
        else begin

            $display("");
            $display("RESIDUE FAULT-INJECTION TEST: FAIL");

        end

        $display("============================================================");
        $display("");

        $finish;

    end

endmodule