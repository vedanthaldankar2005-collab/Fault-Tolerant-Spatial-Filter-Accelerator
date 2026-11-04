`timescale 1ns/1ps

module axi_lite_regs_tb;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;

    // ============================================================
    // AXI4-LITE WRITE ADDRESS CHANNEL
    // ============================================================

    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;

    // ============================================================
    // AXI4-LITE WRITE DATA CHANNEL
    // ============================================================

    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    logic        s_axi_wready;

    // ============================================================
    // AXI4-LITE WRITE RESPONSE CHANNEL
    // ============================================================

    logic [1:0] s_axi_bresp;
    logic       s_axi_bvalid;
    logic       s_axi_bready;

    // ============================================================
    // AXI4-LITE READ ADDRESS CHANNEL
    // ============================================================

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    // ============================================================
    // AXI4-LITE READ DATA CHANNEL
    // ============================================================

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    // ============================================================
    // CONTROL / STATUS
    // ============================================================

    logic start;
    logic busy;
    logic done;
    logic error;

    // Hybrid fault-detection output
    logic kernel_parity_err;

    // ============================================================
    // KERNEL REGISTERS
    // ============================================================

    logic signed [7:0] kernel0;
    logic signed [7:0] kernel1;
    logic signed [7:0] kernel2;
    logic signed [7:0] kernel3;
    logic signed [7:0] kernel4;
    logic signed [7:0] kernel5;
    logic signed [7:0] kernel6;
    logic signed [7:0] kernel7;
    logic signed [7:0] kernel8;

    // ============================================================
    // TEST VARIABLES
    // ============================================================

    integer errors;

    logic [31:0] read_data;

    // ============================================================
    // DUT
    // ============================================================

    axi_lite_regs dut (

        .clk           (clk),
        .rst           (rst),

        // AXI write address
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),

        // AXI write data
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),

        // AXI write response
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),

        // AXI read address
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),

        // AXI read data
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),

        // Control / status
        .start         (start),
        .busy          (busy),
        .done          (done),
        .error         (error),

        // Parity error
        .kernel_parity_err (kernel_parity_err),

        // Kernel registers
        .kernel0       (kernel0),
        .kernel1       (kernel1),
        .kernel2       (kernel2),
        .kernel3       (kernel3),
        .kernel4       (kernel4),
        .kernel5       (kernel5),
        .kernel6       (kernel6),
        .kernel7       (kernel7),
        .kernel8       (kernel8)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // AXI WRITE TASK
    // ============================================================

    task automatic axi_write;

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

    // ============================================================
    // AXI READ TASK
    // ============================================================

    task automatic axi_read;

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

        busy  = 1'b0;
        done  = 1'b0;
        error = 1'b0;

        errors    = 0;
        read_data = 32'd0;

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        #20;

        rst = 1'b0;

        #10;

        $display("");
        $display("==============================================");
        $display(" AXI4-LITE REGISTER TEST");
        $display("==============================================");

        // --------------------------------------------------------
        // TEST 1
        // --------------------------------------------------------

        $display("");
        $display("TEST 1: Write KERNEL0");

        axi_write(
            32'h0000_0008,
            32'h0000_0005
        );

        #5;

        if (kernel0 == 8'sd5) begin

            $display(
                "PASS: kernel0 = %0d",
                kernel0
            );

        end
        else begin

            $display(
                "FAIL: kernel0 = %0d, expected 5",
                kernel0
            );

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // TEST 2
        // --------------------------------------------------------

        $display("");
        $display("TEST 2: Check normal parity");

        #5;

        if (kernel_parity_err == 1'b0) begin

            $display(
                "PASS: kernel_parity_err = 0"
            );

        end
        else begin

            $display(
                "FAIL: kernel_parity_err = 1 during normal operation"
            );

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // TEST 3
        // --------------------------------------------------------

        $display("");
        $display("TEST 3: Read KERNEL0");

        axi_read(
            32'h0000_0008,
            read_data
        );

        if (read_data[7:0] == 8'h05) begin

            $display(
                "PASS: KERNEL0 read = 0x%08h",
                read_data
            );

        end
        else begin

            $display(
                "FAIL: KERNEL0 read = 0x%08h, expected 0x00000005",
                read_data
            );

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // TEST 4
        // ONE-BIT FAULT INJECTION
        // --------------------------------------------------------

        $display("");
        $display("TEST 4: Inject one-bit fault into KERNEL0");

        $display(
            "Before fault: kernel0 = %b",
            kernel0
        );

        // Flip bit 3
        force dut.kernel0[3] = ~dut.kernel0[3];

        #2;

        $display(
            "After fault : kernel0 = %b",
            kernel0
        );

        // --------------------------------------------------------
        // TEST 5
        // PARITY ERROR DETECTION
        // --------------------------------------------------------

        $display("");
        $display("TEST 5: Check parity fault detection");

        #5;

        if (kernel_parity_err == 1'b1) begin

            $display(
                "PASS: PARITY ERROR DETECTED"
            );

            $display(
                "      kernel_parity_err = 1"
            );

        end
        else begin

            $display(
                "FAIL: PARITY ERROR WAS NOT DETECTED"
            );

            $display(
                "      kernel_parity_err = %b",
                kernel_parity_err
            );

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // TEST 6
        // REMOVE FAULT
        // --------------------------------------------------------

        $display("");
        $display("TEST 6: Remove injected fault");

        // Release the force.
        //
        // Icarus Verilog can leave a released variable at the
        // forced value, so explicitly restore the original bit.
        release dut.kernel0[3];

        #1;

        // Original KERNEL0 value was 00000101.
        // Bit 3 was changed to 1 during fault injection.
        // Restore bit 3 to 0.
        dut.kernel0[3] = 1'b0;

        #5;

        $display(
            "Restored kernel0 = %b",
            kernel0
        );

        if (kernel_parity_err == 1'b0) begin

            $display(
                "PASS: Parity returned to normal"
            );

        end
        else begin

            $display(
                "FAIL: Parity error remained after fault removal"
            );

            $display(
                "      kernel_parity_err = %b",
                kernel_parity_err
            );

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // TEST 7
        // PROGRAM COMPLETE 3x3 KERNEL
        // --------------------------------------------------------

        $display("");
        $display("TEST 7: Program complete 3x3 kernel");

        axi_write(
            32'h0000_0008,
            32'h0000_0001
        );

        axi_write(
            32'h0000_000C,
            32'h0000_0002
        );

        axi_write(
            32'h0000_0010,
            32'h0000_0003
        );

        axi_write(
            32'h0000_0014,
            32'h0000_0004
        );

        axi_write(
            32'h0000_0018,
            32'h0000_0005
        );

        axi_write(
            32'h0000_001C,
            32'h0000_0006
        );

        axi_write(
            32'h0000_0020,
            32'h0000_0007
        );

        axi_write(
            32'h0000_0024,
            32'h0000_0008
        );

        axi_write(
            32'h0000_0028,
            32'h0000_0009
        );

        #5;

        if (kernel_parity_err == 1'b0) begin

            $display(
                "PASS: All kernel registers programmed"
            );

            $display(
                "PASS: No parity error"
            );

        end
        else begin

            $display(
                "FAIL: Parity error after kernel programming"
            );

            errors = errors + 1;

        end

        // --------------------------------------------------------
        // FINAL RESULT
        // --------------------------------------------------------

        #20;

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display(
                " ALL AXI/PARITY TESTS PASSED"
            );

        end
        else begin

            $display(
                " TEST FAILED: %0d ERROR(S)",
                errors
            );

        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule