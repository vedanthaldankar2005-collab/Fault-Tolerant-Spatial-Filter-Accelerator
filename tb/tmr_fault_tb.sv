`timescale 1ns / 1ps

module tmr_fault_tb;

    localparam integer WIDTH = 20;

    logic signed [WIDTH-1:0] replica0;
    logic signed [WIDTH-1:0] replica1;
    logic signed [WIDTH-1:0] replica2;

    logic signed [WIDTH-1:0] voted_output;
    logic                    error_detected;

    integer test_count;
    integer error_count;

    // --------------------------------------------------
    // Device Under Test
    // --------------------------------------------------

    tmr #(
        .WIDTH(WIDTH)
    ) dut (
        .replica0(replica0),
        .replica1(replica1),
        .replica2(replica2),
        .voted_output(voted_output),
        .error_detected(error_detected)
    );

    // --------------------------------------------------
    // Test Result Checker
    // --------------------------------------------------

    task automatic check_result(
        input logic signed [WIDTH-1:0] expected_output,
        input logic expected_error,
        input string test_name
    );
        begin
            #1;

            test_count = test_count + 1;

            if ((voted_output !== expected_output) ||
                (error_detected !== expected_error)) begin

                $display("FAIL: %s", test_name);

                $display(
                    "  Expected output = %0d",
                    expected_output
                );

                $display(
                    "  Actual output   = %0d",
                    voted_output
                );

                $display(
                    "  Expected error  = %b",
                    expected_error
                );

                $display(
                    "  Actual error    = %b",
                    error_detected
                );

                error_count = error_count + 1;
            end
            else begin

                $display(
                    "PASS: %s | Output=%0d | Error=%b",
                    test_name,
                    voted_output,
                    error_detected
                );

            end
        end
    endtask

    // --------------------------------------------------
    // Main Test Sequence
    // --------------------------------------------------

    initial begin

        test_count  = 0;
        error_count = 0;

        replica0 = '0;
        replica1 = '0;
        replica2 = '0;

        $display("");
        $display("========================================");
        $display(" TMR FAULT-INJECTION TESTBENCH");
        $display("========================================");

        // ----------------------------------------------
        // TEST 1: All replicas agree
        // ----------------------------------------------

        replica0 = 20'sd100;
        replica1 = 20'sd100;
        replica2 = 20'sd100;

        check_result(
            20'sd100,
            1'b0,
            "All replicas agree"
        );

        // ----------------------------------------------
        // TEST 2: Fault in replica 0
        // Replicas 1 and 2 agree on the correct value.
        // ----------------------------------------------

        replica0 = 20'sd999;
        replica1 = 20'sd100;
        replica2 = 20'sd100;

        check_result(
            20'sd100,
            1'b1,
            "Fault in replica 0"
        );

        // ----------------------------------------------
        // TEST 3: Fault in replica 1
        // Replicas 0 and 2 agree on the correct value.
        // ----------------------------------------------

        replica0 = 20'sd100;
        replica1 = -20'sd300;
        replica2 = 20'sd100;

        check_result(
            20'sd100,
            1'b1,
            "Fault in replica 1"
        );

        // ----------------------------------------------
        // TEST 4: Fault in replica 2
        // Replicas 0 and 1 agree on the correct value.
        // ----------------------------------------------

        replica0 = 20'sd100;
        replica1 = 20'sd100;
        replica2 = 20'sd500;

        check_result(
            20'sd100,
            1'b1,
            "Fault in replica 2"
        );

        // ----------------------------------------------
        // TEST 5: All replicas disagree
        //
        // Bitwise majority:
        // 10 = 00001010
        // 20 = 00010100
        // 30 = 00011110
        //
        // The bitwise majority is 00011110 = 30.
        // ----------------------------------------------

        replica0 = 20'sd10;
        replica1 = 20'sd20;
        replica2 = 20'sd30;

        check_result(
            20'sd30,
            1'b1,
            "All replicas disagree"
        );

        // ----------------------------------------------
        // TEST 6: Negative result agreement
        // ----------------------------------------------

        replica0 = -20'sd25;
        replica1 = -20'sd25;
        replica2 = -20'sd25;

        check_result(
            -20'sd25,
            1'b0,
            "Negative result agreement"
        );

        // ----------------------------------------------
        // Final Summary
        // ----------------------------------------------

        $display("");
        $display("========================================");
        $display(" TMR TEST SUMMARY");
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