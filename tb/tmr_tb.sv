`timescale 1ns/1ps

module tmr_tb;

    logic signed [19:0] replica0;
    logic signed [19:0] replica1;
    logic signed [19:0] replica2;

    logic signed [19:0] voted_output;
    logic               error_detected;

    integer errors;

    // ------------------------------------------------
    // Device under test
    // ------------------------------------------------

    tmr #(
        .WIDTH(20)
    ) dut (
        .replica0        (replica0),
        .replica1        (replica1),
        .replica2        (replica2),
        .voted_output    (voted_output),
        .error_detected  (error_detected)
    );

    // ------------------------------------------------
    // Test
    // ------------------------------------------------

    initial begin

        errors = 0;

        // ------------------------------------------------
        // TEST 1: All replicas agree
        // ------------------------------------------------

        replica0 = 20'sd100;
        replica1 = 20'sd100;
        replica2 = 20'sd100;

        #10;

        $display("TEST 1: All replicas agree");
        $display(
            "OUTPUT = %0d, ERROR = %0d",
            voted_output,
            error_detected
        );

        if (voted_output !== 20'sd100) begin
            $display("ERROR: Incorrect majority output");
            errors = errors + 1;
        end

        if (error_detected !== 1'b0) begin
            $display("ERROR: False fault detection");
            errors = errors + 1;
        end

        // ------------------------------------------------
        // TEST 2: Replica 1 faulty
        // ------------------------------------------------

        replica0 = 20'sd100;
        replica1 = 20'sd999;
        replica2 = 20'sd100;

        #10;

        $display("");
        $display("TEST 2: Replica 1 faulty");
        $display(
            "OUTPUT = %0d, ERROR = %0d",
            voted_output,
            error_detected
        );

        if (voted_output !== 20'sd100) begin
            $display("ERROR: Fault was not masked");
            errors = errors + 1;
        end

        if (error_detected !== 1'b1) begin
            $display("ERROR: Fault was not detected");
            errors = errors + 1;
        end

        // ------------------------------------------------
        // TEST 3: Replica 0 faulty
        // ------------------------------------------------

        replica0 = 20'sd555;
        replica1 = 20'sd200;
        replica2 = 20'sd200;

        #10;

        $display("");
        $display("TEST 3: Replica 0 faulty");
        $display(
            "OUTPUT = %0d, ERROR = %0d",
            voted_output,
            error_detected
        );

        if (voted_output !== 20'sd200) begin
            $display("ERROR: Fault was not masked");
            errors = errors + 1;
        end

        if (error_detected !== 1'b1) begin
            $display("ERROR: Fault was not detected");
            errors = errors + 1;
        end

        // ------------------------------------------------
        // TEST 4: Replica 2 faulty
        // ------------------------------------------------

        replica0 = 20'sd300;
        replica1 = 20'sd300;
        replica2 = 20'sd777;

        #10;

        $display("");
        $display("TEST 4: Replica 2 faulty");
        $display(
            "OUTPUT = %0d, ERROR = %0d",
            voted_output,
            error_detected
        );

        if (voted_output !== 20'sd300) begin
            $display("ERROR: Fault was not masked");
            errors = errors + 1;
        end

        if (error_detected !== 1'b1) begin
            $display("ERROR: Fault was not detected");
            errors = errors + 1;
        end

        // ------------------------------------------------
        // Final verification
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("TMR TEST");
        $display("========================================");

        $display(
            "ERROR COUNT = %0d",
            errors
        );

        if (errors == 0) begin
            $display("TMR TEST: PASS");
        end
        else begin
            $display("TMR TEST: FAIL");
        end

        $display("========================================");

        $finish;

    end

endmodule