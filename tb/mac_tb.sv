`timescale 1ns/1ps

module mac_tb;

    logic signed [7:0] pixel0;
    logic signed [7:0] pixel1;
    logic signed [7:0] pixel2;
    logic signed [7:0] pixel3;
    logic signed [7:0] pixel4;
    logic signed [7:0] pixel5;
    logic signed [7:0] pixel6;
    logic signed [7:0] pixel7;
    logic signed [7:0] pixel8;

    logic signed [7:0] kernel0;
    logic signed [7:0] kernel1;
    logic signed [7:0] kernel2;
    logic signed [7:0] kernel3;
    logic signed [7:0] kernel4;
    logic signed [7:0] kernel5;
    logic signed [7:0] kernel6;
    logic signed [7:0] kernel7;
    logic signed [7:0] kernel8;

    logic signed [19:0] result;

    mac dut (
        .pixel0  (pixel0),
        .pixel1  (pixel1),
        .pixel2  (pixel2),
        .pixel3  (pixel3),
        .pixel4  (pixel4),
        .pixel5  (pixel5),
        .pixel6  (pixel6),
        .pixel7  (pixel7),
        .pixel8  (pixel8),

        .kernel0 (kernel0),
        .kernel1 (kernel1),
        .kernel2 (kernel2),
        .kernel3 (kernel3),
        .kernel4 (kernel4),
        .kernel5 (kernel5),
        .kernel6 (kernel6),
        .kernel7 (kernel7),
        .kernel8 (kernel8),

        .result  (result)
    );

    initial begin

        pixel0 = 10;
        pixel1 = 20;
        pixel2 = 30;
        pixel3 = 40;
        pixel4 = 50;
        pixel5 = 60;
        pixel6 = 70;
        pixel7 = 80;
        pixel8 = 90;

        kernel0 = -1;
        kernel1 =  0;
        kernel2 =  1;
        kernel3 = -2;
        kernel4 =  0;
        kernel5 =  2;
        kernel6 = -1;
        kernel7 =  0;
        kernel8 =  1;

        #10;

        $display("MAC RESULT = %0d", result);

        $finish;

    end

endmodule