`timescale 1ns/1ps

module tb_parity;

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
    // PIXEL / ACCELERATOR INTERFACE
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
    // MAIN TEST
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

        read_data     = 32'd0;
        error_count   = 0;

        // --------------------------------------------------------
        // TEST HEADER
        // --------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("             PHASE 1 - KERNEL PARITY TEST");
        $display("============================================================");
        $display("");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------
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

        // --------------------------------------------------------
        // PROGRAM IDENTITY KERNEL
        //
        // Kernel:
        //
        //  0 0 0
        //  0 1 0
        //  0 0 0
        //
        // Addresses:
        // 0x08 -> kernel0
        // 0x0C -> kernel1
        // 0x10 -> kernel2
        // 0x14 -> kernel3
        // 0x18 -> kernel4
        // 0x1C -> kernel5
        // 0x20 -> kernel6
        // 0x24 -> kernel7
        // 0x28 -> kernel8
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

        // --------------------------------------------------------
        // VERIFY NORMAL PARITY
        // --------------------------------------------------------
        if (dut.regs.kernel_parity_err == 1'b0) begin
            $display("Kernel programming: PASS");
        end
        else begin
            $display("ERROR: Kernel programming parity error");
            error_count = error_count + 1;
        end

        $display(
            "Normal parity check: %s",
            (dut.regs.kernel_parity_err == 1'b0) ? "PASS" : "FAIL"
        );

        $display(
            "kernel_parity_err = %0d",
            dut.regs.kernel_parity_err
        );

        // --------------------------------------------------------
        // READ STATUS BEFORE FAULT
        //
        // STATUS:
        // bit 0 = busy
        // bit 1 = done
        // bit 2 = unified error
        // bit 3 = kernel parity error
        // --------------------------------------------------------
        axi_read(32'h00000004, read_data);

        $display(
            "STATUS before fault = %08h",
            read_data
        );

        if (read_data[3] == 1'b0) begin
            $display("STATUS parity bit before fault: PASS");
        end
        else begin
            $display("ERROR: STATUS parity bit unexpectedly set");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // SINGLE-BIT FAULT INJECTION
        //
        // Inject fault into kernel0 bit 3.
        //
        // Original kernel0 = 00000000
        // Faulted kernel0 = 00001000
        //
        // Stored parity remains 0.
        // Calculated parity becomes 1.
        // Therefore parity error must become 1.
        // --------------------------------------------------------
        $display("");
        $display("Injecting single-bit fault...");
        $display("Fault location: dut.regs.kernel0[3]");

        force dut.regs.kernel0[3] = 1'b1;

        #2;

        $display(
            "Corrupted kernel0 = %08b",
            dut.regs.kernel0
        );

        $display(
            "Stored kernel0 parity = %0d",
            dut.regs.kernel0_parity
        );

        $display(
            "Calculated kernel0 parity = %0d",
            ^dut.regs.kernel0
        );

        $display(
            "kernel_parity_err = %0d",
            dut.regs.kernel_parity_err
        );

        // --------------------------------------------------------
        // CHECK PARITY DETECTION
        // --------------------------------------------------------
        if (dut.regs.kernel_parity_err == 1'b1) begin
            $display("");
            $display("PARITY FAULT DETECTION: PASS");
        end
        else begin
            $display("");
            $display("ERROR: PARITY FAULT DETECTION FAILED");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // CHECK STATUS DURING FAULT
        // --------------------------------------------------------
        axi_read(32'h00000004, read_data);

        $display(
            "STATUS during fault = %08h",
            read_data
        );

        if (read_data[3] == 1'b1) begin
            $display("STATUS[3] parity error indication: PASS");
        end
        else begin
            $display("ERROR: STATUS[3] parity error indication missing");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // RELEASE FAULT
        // --------------------------------------------------------
        $display("");
        $display("Releasing injected fault...");

        release dut.regs.kernel0[3];

        // Icarus Verilog can retain the released value on a
        // hierarchical variable. Explicitly restore the original
        // value so that the recovery test is deterministic.
        #1;
        dut.regs.kernel0[3] = 1'b0;

        #2;

        $display(
            "Restored kernel0 = %08b",
            dut.regs.kernel0
        );

        $display(
            "kernel_parity_err = %0d",
            dut.regs.kernel_parity_err
        );

        // --------------------------------------------------------
        // CHECK PARITY RECOVERY
        // --------------------------------------------------------
        if (dut.regs.kernel_parity_err == 1'b0) begin
            $display("Parity recovery: PASS");
        end
        else begin
            $display("ERROR: Parity error did not clear after recovery");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // CHECK STATUS AFTER RECOVERY
        // --------------------------------------------------------
        axi_read(32'h00000004, read_data);

        $display(
            "STATUS after recovery = %08h",
            read_data
        );

        if (read_data[3] == 1'b0) begin
            $display("STATUS[3] recovery: PASS");
        end
        else begin
            $display("ERROR: STATUS[3] did not clear after recovery");
            error_count = error_count + 1;
        end

        // --------------------------------------------------------
        // FINAL SUMMARY
        // --------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("                    PARITY TEST SUMMARY");
        $display("============================================================");

        $display("Fault injected  = kernel0[3]");
        $display(
            "Fault detected  = %0d",
            (dut.regs.kernel_parity_err == 1'b0) ? 0 : 1
        );

        $display(
            "Test errors     = %0d",
            error_count
        );

        $display("");

        if (error_count == 0) begin
            $display("KERNEL PARITY TEST: PASS");
        end
        else begin
            $display("KERNEL PARITY TEST: FAIL");
        end

        $display("============================================================");
        $display("");

        $finish;
    end

endmodule