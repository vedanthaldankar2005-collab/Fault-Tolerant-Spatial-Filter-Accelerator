`timescale 1ns / 1ps

module fault_manager_tb;

    logic clk;
    logic rst_n;

    logic tmr_error;
    logic kernel_parity_error;
    logic residue_error;
    logic timeout_error;

    logic clear_fault;

    logic fault_active;
    logic [3:0] first_fault_code;
    logic [31:0] fault_count;

    integer test_count;
    integer error_count;

    localparam logic [3:0] FAULT_NONE    = 4'd0;
    localparam logic [3:0] FAULT_TMR     = 4'd1;
    localparam logic [3:0] FAULT_PARITY  = 4'd2;
    localparam logic [3:0] FAULT_RESIDUE = 4'd3;
    localparam logic [3:0] FAULT_TIMEOUT = 4'd4;

    // Device under test
    fault_manager dut (
        .clk(clk),
        .rst_n(rst_n),
        .tmr_error(tmr_error),
        .kernel_parity_error(kernel_parity_error),
        .residue_error(residue_error),
        .timeout_error(timeout_error),
        .clear_fault(clear_fault),
        .fault_active(fault_active),
        .first_fault_code(first_fault_code),
        .fault_count(fault_count)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_status(
        input logic expected_active,
        input logic [3:0] expected_code,
        input logic [31:0] expected_count,
        input string test_name
    );
        begin
            test_count = test_count + 1;

            if ((fault_active !== expected_active) ||
                (first_fault_code !== expected_code) ||
                (fault_count !== expected_count)) begin

                $display("FAIL: %s", test_name);
                $display("  Expected active = %b", expected_active);
                $display("  Actual active   = %b", fault_active);
                $display("  Expected code   = %0d", expected_code);
                $display("  Actual code     = %0d", first_fault_code);
                $display("  Expected count  = %0d", expected_count);
                $display("  Actual count    = %0d", fault_count);

                error_count = error_count + 1;
            end
            else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin

        rst_n = 1'b0;

        tmr_error          = 1'b0;
        kernel_parity_error = 1'b0;
        residue_error      = 1'b0;
        timeout_error      = 1'b0;
        clear_fault        = 1'b0;

        test_count  = 0;
        error_count = 0;

        $display("");
        $display("========================================");
        $display(" FAULT MANAGER TESTBENCH");
        $display("========================================");

        // Release reset
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b0, FAULT_NONE, 32'd0, "Reset state");

        // Test 1: Detect a TMR fault
        tmr_error = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b1, FAULT_TMR, 32'd1, "TMR fault detected");

        // Keep the fault asserted; count should not increment again.
        @(negedge clk);
        #1;
        check_status(1'b1, FAULT_TMR, 32'd1, "TMR fault remains latched");

        // Remove the fault and clear the latched status.
        tmr_error = 1'b0;
        clear_fault = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b0, FAULT_NONE, 32'd1, "Clear TMR fault");

        clear_fault = 1'b0;

        // Test 2: Detect a kernel parity fault
        kernel_parity_error = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b1, FAULT_PARITY, 32'd2, "Parity fault detected");

        kernel_parity_error = 1'b0;
        clear_fault = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b0, FAULT_NONE, 32'd2, "Clear parity fault");

        clear_fault = 1'b0;

        // Test 3: Detect a residue-checking fault
        residue_error = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b1, FAULT_RESIDUE, 32'd3, "Residue fault detected");

        residue_error = 1'b0;
        clear_fault = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b0, FAULT_NONE, 32'd3, "Clear residue fault");

        clear_fault = 1'b0;

        // Test 4: Detect a timeout
        timeout_error = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b1, FAULT_TIMEOUT, 32'd4, "Timeout detected");

        timeout_error = 1'b0;
        clear_fault = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b0, FAULT_NONE, 32'd4, "Clear timeout");

        clear_fault = 1'b0;

        // Test 5: Simultaneous faults use the documented priority.
        // TMR has priority over parity, residue, and timeout.
        tmr_error           = 1'b1;
        kernel_parity_error = 1'b1;
        residue_error       = 1'b1;
        timeout_error       = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b1, FAULT_TMR, 32'd5, "Simultaneous fault priority");

        // Remove faults and clear status.
        tmr_error           = 1'b0;
        kernel_parity_error = 1'b0;
        residue_error       = 1'b0;
        timeout_error       = 1'b0;
        clear_fault         = 1'b1;

        @(negedge clk);
        #1;
        check_status(1'b0, FAULT_NONE, 32'd5, "Clear simultaneous faults");

        clear_fault = 1'b0;

        // Final summary
        $display("");
        $display("========================================");
        $display(" FAULT MANAGER TEST SUMMARY");
        $display("========================================");
        $display("Tests executed : %0d", test_count);
        $display("Errors         : %0d", error_count);

        if (error_count == 0)
            $display("FINAL RESULT: PASS");
        else
            $display("FINAL RESULT: FAIL");

        $display("========================================");

        $finish;
    end

endmodule