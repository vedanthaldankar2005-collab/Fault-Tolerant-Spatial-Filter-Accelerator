`timescale 1ns / 1ps

module accelerator_top #(
    parameter IMAGE_WIDTH = 8
) (
    input  logic clk,
    input  logic rst,

    // AXI4-Lite write address
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // AXI4-Lite write data
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // AXI4-Lite write response
    output logic [1:0] s_axi_bresp,
    output logic       s_axi_bvalid,
    input  logic       s_axi_bready,

    // AXI4-Lite read address
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // AXI4-Lite read data
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // Pixel input
    input  logic [7:0] pixel_in,
    input  logic       pixel_valid,

    // Filter output
    output logic signed [19:0] result,
    output logic               result_valid,

    // Accelerator status
    output logic busy,
    output logic done,
    output logic error
);

    // ------------------------------------------------------------
    // Control and kernel registers
    // ------------------------------------------------------------

    logic start;

    logic signed [7:0] kernel0;
    logic signed [7:0] kernel1;
    logic signed [7:0] kernel2;
    logic signed [7:0] kernel3;
    logic signed [7:0] kernel4;
    logic signed [7:0] kernel5;
    logic signed [7:0] kernel6;
    logic signed [7:0] kernel7;
    logic signed [7:0] kernel8;

    // ------------------------------------------------------------
    // Fault signals
    // ------------------------------------------------------------

    logic kernel_parity_err;

    logic residue_error0;
    logic residue_error1;
    logic residue_error2;
    logic residue_error;

    logic tmr_error;

    logic fault_active;
    logic [3:0]  first_fault_code;
    logic [31:0] fault_count;

    // ------------------------------------------------------------
    // Filter replica outputs
    // ------------------------------------------------------------

    logic signed [19:0] filter_result0;
    logic signed [19:0] filter_result1;
    logic signed [19:0] filter_result2;

    logic result_valid0;
    logic result_valid1;
    logic result_valid2;

    logic signed [19:0] voted_result;

    // ------------------------------------------------------------
    // AXI4-Lite register block
    // ------------------------------------------------------------

    axi_lite_regs regs (
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

        .start(start),
        .busy(busy),
        .done(done),
        .error(error),

        .fault_active(fault_active),
        .first_fault_code(first_fault_code),
        .fault_count(fault_count),

        .kernel_parity_err(kernel_parity_err),

        .kernel0(kernel0),
        .kernel1(kernel1),
        .kernel2(kernel2),
        .kernel3(kernel3),
        .kernel4(kernel4),
        .kernel5(kernel5),
        .kernel6(kernel6),
        .kernel7(kernel7),
        .kernel8(kernel8)
    );

    // ------------------------------------------------------------
    // Filter replica 0
    // ------------------------------------------------------------

    spatial_filter #(
        .IMAGE_WIDTH(IMAGE_WIDTH)
    ) filter0 (
        .clk(clk),
        .rst(rst),

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),

        .kernel0(kernel0),
        .kernel1(kernel1),
        .kernel2(kernel2),
        .kernel3(kernel3),
        .kernel4(kernel4),
        .kernel5(kernel5),
        .kernel6(kernel6),
        .kernel7(kernel7),
        .kernel8(kernel8),

        .result(filter_result0),
        .result_valid(result_valid0),
        .residue_error(residue_error0)
    );

    // ------------------------------------------------------------
    // Filter replica 1
    // ------------------------------------------------------------

    spatial_filter #(
        .IMAGE_WIDTH(IMAGE_WIDTH)
    ) filter1 (
        .clk(clk),
        .rst(rst),

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),

        .kernel0(kernel0),
        .kernel1(kernel1),
        .kernel2(kernel2),
        .kernel3(kernel3),
        .kernel4(kernel4),
        .kernel5(kernel5),
        .kernel6(kernel6),
        .kernel7(kernel7),
        .kernel8(kernel8),

        .result(filter_result1),
        .result_valid(result_valid1),
        .residue_error(residue_error1)
    );

    // ------------------------------------------------------------
    // Filter replica 2
    // ------------------------------------------------------------

    spatial_filter #(
        .IMAGE_WIDTH(IMAGE_WIDTH)
    ) filter2 (
        .clk(clk),
        .rst(rst),

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),

        .kernel0(kernel0),
        .kernel1(kernel1),
        .kernel2(kernel2),
        .kernel3(kernel3),
        .kernel4(kernel4),
        .kernel5(kernel5),
        .kernel6(kernel6),
        .kernel7(kernel7),
        .kernel8(kernel8),

        .result(filter_result2),
        .result_valid(result_valid2),
        .residue_error(residue_error2)
    );

    // ------------------------------------------------------------
    // TMR majority voter
    // ------------------------------------------------------------

    tmr #(
        .WIDTH(20)
    ) result_tmr (
        .replica0(filter_result0),
        .replica1(filter_result1),
        .replica2(filter_result2),

        .voted_output(voted_result),
        .error_detected(tmr_error)
    );

    // ------------------------------------------------------------
    // Output combination
    // ------------------------------------------------------------

    always_comb begin
        result = voted_result;

        result_valid =
            result_valid0 &
            result_valid1 &
            result_valid2;

        residue_error =
            residue_error0 |
            residue_error1 |
            residue_error2;

        error =
            tmr_error |
            kernel_parity_err |
            residue_error;
    end

    // ------------------------------------------------------------
    // BUSY and DONE CONTROL
    //
    // Reset: BUSY=0, DONE=0
    // Start: BUSY=1, DONE=0
    // Output valid: BUSY=0, DONE=1
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin
            if (start) begin
                busy <= 1'b1;
                done <= 1'b0;
            end
            else if (result_valid) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // Fault manager
    // ------------------------------------------------------------

    fault_manager fault_mgr (
        .clk(clk),
        .rst_n(~rst),

        .tmr_error(tmr_error),
        .kernel_parity_error(kernel_parity_err),
        .residue_error(residue_error),
        .timeout_error(1'b0),

        .clear_fault(1'b0),

        .fault_active(fault_active),
        .first_fault_code(first_fault_code),
        .fault_count(fault_count)
    );

endmodule