`timescale 1ns/1ps

module register_tb;

    logic       clk;
    logic       rst;
    logic [7:0] data_in;
    logic [7:0] data_out;

    register dut (
        .clk      (clk),
        .rst      (rst),
        .data_in  (data_in),
        .data_out (data_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, register_tb);

        clk     = 0;
        rst     = 1;
        data_in = 0;

        #10;

        rst = 0;

        data_in = 8'd10;
        #10;
        $display("data_in = %0d, data_out = %0d", data_in, data_out);

        data_in = 8'd20;
        #10;
        $display("data_in = %0d, data_out = %0d", data_in, data_out);

        data_in = 8'd30;
        #10;
        $display("data_in = %0d, data_out = %0d", data_in, data_out);

        $finish;

    end

endmodule