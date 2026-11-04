`timescale 1ns/1ps

module axi_lite_regs (

    input  logic        clk,
    input  logic        rst,

    // ============================================================
    // AXI4-Lite WRITE ADDRESS
    // ============================================================

    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // ============================================================
    // AXI4-Lite WRITE DATA
    // ============================================================

    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // ============================================================
    // AXI4-Lite WRITE RESPONSE
    // ============================================================

    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // ============================================================
    // AXI4-Lite READ ADDRESS
    // ============================================================

    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // ============================================================
    // AXI4-Lite READ DATA
    // ============================================================

    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // ============================================================
    // CONTROL / STATUS
    // ============================================================

    output logic        start,
    input  logic        busy,
    input  logic        done,
    input  logic        error,

    // ============================================================
    // KERNEL PARITY ERROR
    // ============================================================

    output logic        kernel_parity_err,

    // ============================================================
    // KERNEL REGISTERS
    // ============================================================

    output logic signed [7:0] kernel0,
    output logic signed [7:0] kernel1,
    output logic signed [7:0] kernel2,
    output logic signed [7:0] kernel3,
    output logic signed [7:0] kernel4,
    output logic signed [7:0] kernel5,
    output logic signed [7:0] kernel6,
    output logic signed [7:0] kernel7,
    output logic signed [7:0] kernel8
);

    // ============================================================
    // KERNEL PARITY STORAGE
    // ============================================================

    logic kernel0_parity;
    logic kernel1_parity;
    logic kernel2_parity;
    logic kernel3_parity;
    logic kernel4_parity;
    logic kernel5_parity;
    logic kernel6_parity;
    logic kernel7_parity;
    logic kernel8_parity;

    // ============================================================
    // ADDRESS DEFINITIONS
    // ============================================================

    localparam [31:0] ADDR_CONTROL = 32'h00000000;
    localparam [31:0] ADDR_STATUS  = 32'h00000004;

    localparam [31:0] ADDR_KERNEL0 = 32'h00000008;
    localparam [31:0] ADDR_KERNEL1 = 32'h0000000C;
    localparam [31:0] ADDR_KERNEL2 = 32'h00000010;
    localparam [31:0] ADDR_KERNEL3 = 32'h00000014;
    localparam [31:0] ADDR_KERNEL4 = 32'h00000018;
    localparam [31:0] ADDR_KERNEL5 = 32'h0000001C;
    localparam [31:0] ADDR_KERNEL6 = 32'h00000020;
    localparam [31:0] ADDR_KERNEL7 = 32'h00000024;
    localparam [31:0] ADDR_KERNEL8 = 32'h00000028;

    // ============================================================
    // AXI READY SIGNALS
    // ============================================================

    always_comb begin

        s_axi_awready = ~s_axi_bvalid;
        s_axi_wready  = ~s_axi_bvalid;
        s_axi_arready = ~s_axi_rvalid;

    end

    // ============================================================
    // KERNEL PARITY CHECK
    //
    // Even parity is stored when the kernel is written.
    // XOR reduction of the current kernel is compared against
    // the stored parity bit.
    // ============================================================

    always_comb begin

        kernel_parity_err =
            ((^kernel0) != kernel0_parity) |
            ((^kernel1) != kernel1_parity) |
            ((^kernel2) != kernel2_parity) |
            ((^kernel3) != kernel3_parity) |
            ((^kernel4) != kernel4_parity) |
            ((^kernel5) != kernel5_parity) |
            ((^kernel6) != kernel6_parity) |
            ((^kernel7) != kernel7_parity) |
            ((^kernel8) != kernel8_parity);

    end

    // ============================================================
    // AXI WRITE / READ LOGIC
    // ============================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            // ----------------------------------------------------
            // AXI RESPONSE RESET
            // ----------------------------------------------------

            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;

            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'd0;

            // ----------------------------------------------------
            // CONTROL RESET
            // ----------------------------------------------------

            start <= 1'b0;

            // ----------------------------------------------------
            // KERNEL RESET
            // ----------------------------------------------------

            kernel0 <= 8'sd0;
            kernel1 <= 8'sd0;
            kernel2 <= 8'sd0;
            kernel3 <= 8'sd0;
            kernel4 <= 8'sd0;
            kernel5 <= 8'sd0;
            kernel6 <= 8'sd0;
            kernel7 <= 8'sd0;
            kernel8 <= 8'sd0;

            // ----------------------------------------------------
            // PARITY RESET
            // ----------------------------------------------------

            kernel0_parity <= 1'b0;
            kernel1_parity <= 1'b0;
            kernel2_parity <= 1'b0;
            kernel3_parity <= 1'b0;
            kernel4_parity <= 1'b0;
            kernel5_parity <= 1'b0;
            kernel6_parity <= 1'b0;
            kernel7_parity <= 1'b0;
            kernel8_parity <= 1'b0;

        end

        else begin

            // ====================================================
            // DEFAULT START PULSE
            // ====================================================

            start <= 1'b0;

            // ====================================================
            // WRITE RESPONSE HANDSHAKE
            // ====================================================

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // ====================================================
            // WRITE TRANSACTION
            // ====================================================

            if (s_axi_awvalid &&
                s_axi_awready &&
                s_axi_wvalid &&
                s_axi_wready) begin

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

                case (s_axi_awaddr)

                    // ------------------------------------------------
                    // CONTROL REGISTER
                    // bit 0 = START
                    // ------------------------------------------------

                    ADDR_CONTROL: begin

                        if (s_axi_wstrb[0]) begin

                            if (s_axi_wdata[0]) begin
                                start <= 1'b1;
                            end

                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 0
                    // ------------------------------------------------

                    ADDR_KERNEL0: begin

                        if (s_axi_wstrb[0]) begin
                            kernel0        <= s_axi_wdata[7:0];
                            kernel0_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 1
                    // ------------------------------------------------

                    ADDR_KERNEL1: begin

                        if (s_axi_wstrb[0]) begin
                            kernel1        <= s_axi_wdata[7:0];
                            kernel1_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 2
                    // ------------------------------------------------

                    ADDR_KERNEL2: begin

                        if (s_axi_wstrb[0]) begin
                            kernel2        <= s_axi_wdata[7:0];
                            kernel2_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 3
                    // ------------------------------------------------

                    ADDR_KERNEL3: begin

                        if (s_axi_wstrb[0]) begin
                            kernel3        <= s_axi_wdata[7:0];
                            kernel3_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 4
                    // ------------------------------------------------

                    ADDR_KERNEL4: begin

                        if (s_axi_wstrb[0]) begin
                            kernel4        <= s_axi_wdata[7:0];
                            kernel4_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 5
                    // ------------------------------------------------

                    ADDR_KERNEL5: begin

                        if (s_axi_wstrb[0]) begin
                            kernel5        <= s_axi_wdata[7:0];
                            kernel5_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 6
                    // ------------------------------------------------

                    ADDR_KERNEL6: begin

                        if (s_axi_wstrb[0]) begin
                            kernel6        <= s_axi_wdata[7:0];
                            kernel6_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 7
                    // ------------------------------------------------

                    ADDR_KERNEL7: begin

                        if (s_axi_wstrb[0]) begin
                            kernel7        <= s_axi_wdata[7:0];
                            kernel7_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // KERNEL 8
                    // ------------------------------------------------

                    ADDR_KERNEL8: begin

                        if (s_axi_wstrb[0]) begin
                            kernel8        <= s_axi_wdata[7:0];
                            kernel8_parity <= ^s_axi_wdata[7:0];
                        end

                    end

                    // ------------------------------------------------
                    // INVALID ADDRESS
                    // ------------------------------------------------

                    default: begin
                        s_axi_bresp <= 2'b10;
                    end

                endcase

            end

            // ====================================================
            // READ RESPONSE HANDSHAKE
            // ====================================================

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

            // ====================================================
            // READ TRANSACTION
            // ====================================================

            if (s_axi_arvalid && s_axi_arready) begin

                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;

                case (s_axi_araddr)

                    // ------------------------------------------------
                    // CONTROL REGISTER
                    // ------------------------------------------------

                    ADDR_CONTROL: begin

                        s_axi_rdata <= {
                            31'd0,
                            start
                        };

                    end

                    // ------------------------------------------------
                    // STATUS REGISTER
                    //
                    // bit 0 = busy
                    // bit 1 = done
                    // bit 2 = unified error
                    // bit 3 = kernel parity error
                    // ------------------------------------------------

                    ADDR_STATUS: begin

                        s_axi_rdata <= {
                            28'd0,
                            kernel_parity_err,
                            error,
                            done,
                            busy
                        };

                    end

                    // ------------------------------------------------
                    // KERNEL REGISTERS
                    // ------------------------------------------------

                    ADDR_KERNEL0: begin
                        s_axi_rdata <= {{24{kernel0[7]}}, kernel0};
                    end

                    ADDR_KERNEL1: begin
                        s_axi_rdata <= {{24{kernel1[7]}}, kernel1};
                    end

                    ADDR_KERNEL2: begin
                        s_axi_rdata <= {{24{kernel2[7]}}, kernel2};
                    end

                    ADDR_KERNEL3: begin
                        s_axi_rdata <= {{24{kernel3[7]}}, kernel3};
                    end

                    ADDR_KERNEL4: begin
                        s_axi_rdata <= {{24{kernel4[7]}}, kernel4};
                    end

                    ADDR_KERNEL5: begin
                        s_axi_rdata <= {{24{kernel5[7]}}, kernel5};
                    end

                    ADDR_KERNEL6: begin
                        s_axi_rdata <= {{24{kernel6[7]}}, kernel6};
                    end

                    ADDR_KERNEL7: begin
                        s_axi_rdata <= {{24{kernel7[7]}}, kernel7};
                    end

                    ADDR_KERNEL8: begin
                        s_axi_rdata <= {{24{kernel8[7]}}, kernel8};
                    end

                    // ------------------------------------------------
                    // INVALID ADDRESS
                    // ------------------------------------------------

                    default: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rresp <= 2'b10;
                    end

                endcase

            end

        end

    end

endmodule