`timescale 1ns / 1ps

module fault_injector_tb;

    localparam integer DATA_WIDTH = 32;

    logic                  enable;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] fault_mask;
    logic [DATA_WIDTH-1:0] data_out;

    integer test_count;
    integer error_count;

    fault_injector #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .enable(enable),
        .data_in(data_in),
        .fault_mask(fault_mask),
        .data_out(data_out)
    );

    task automatic check_result(
        input logic [DATA_WIDTH-1:0] expected,
        input string test_name
    );
        begin
            #1;

            test_count = test_count + 1;

            if (data_out !== expected) begin
                $display(
                    "FAIL: %s | Expected=%h Actual=%h",
                    test_name, expected, data_out
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "PASS: %s | Output=%h",
                    test_name, data_out
                );
            end
        end
    endtask

    initial begin
        enable      = 1'b0;
        data_in     = '0;
        fault_mask  = '0;
        test_count  = 0;
        error_count = 0;

        $display("----------------------------------------");
        $display("FAULT INJECTOR TESTBENCH");
        $display("----------------------------------------");

        // Test 1: Disabled injection passes data unchanged.
        enable     = 1'b0;
        data_in    = 32'h12345678;
        fault_mask = 32'h00000001;
        check_result(32'h12345678, "Injection disabled");

        // Test 2: Flip bit 0.
        enable     = 1'b1;
        data_in    = 32'h00000000;
        fault_mask = 32'h00000001;
        check_result(32'h00000001, "Flip bit 0");

        // Test 3: Flip bit 2.
        enable     = 1'b1;
        data_in    = 32'h00000000;
        fault_mask = 32'h00000004;
        check_result(32'h00000004, "Flip bit 2");

        // Test 4: Flip multiple bits.
        enable     = 1'b1;
        data_in    = 32'h12345678;
        fault_mask = 32'h0000000F;
        check_result(32'h12345677, "Flip selected low bits");

        // Test 5: Zero mask leaves data unchanged.
        enable     = 1'b1;
        data_in    = 32'hA5A5A5A5;
        fault_mask = 32'h00000000;
        check_result(32'hA5A5A5A5, "Zero fault mask");

        // Test 6: Disable injection after a fault-enabled case.
        enable     = 1'b0;
        data_in    = 32'hFFFFFFFF;
        fault_mask = 32'h000000FF;
        check_result(32'hFFFFFFFF, "Injection disabled again");

        $display("----------------------------------------");
        $display("Tests executed : %0d", test_count);
        $display("Errors         : %0d", error_count);

        if (error_count == 0)
            $display("FINAL RESULT: PASS");
        else
            $display("FINAL RESULT: FAIL");

        $display("----------------------------------------");

        $finish;
    end

endmodule