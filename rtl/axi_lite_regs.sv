`timescale 1ns / 1ps

module axi_lite_regs (
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
    input  logic       s_axi_rready,

    // Accelerator status
    output logic start,
    input  logic busy,
    input  logic done,
    input  logic error,

    // Fault manager status
    input  logic        fault_active,
    input  logic [3:0]  first_fault_code,
    input  logic [31:0] fault_count,

    // Kernel parity error
    output logic kernel_parity_err,

    // Signed 3x3 kernel coefficients
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

    localparam logic [31:0] ADDR_CONTROL      = 32'h00;
    localparam logic [31:0] ADDR_STATUS       = 32'h04;

    localparam logic [31:0] ADDR_KERNEL0      = 32'h08;
    localparam logic [31:0] ADDR_KERNEL1      = 32'h0C;
    localparam logic [31:0] ADDR_KERNEL2      = 32'h10;
    localparam logic [31:0] ADDR_KERNEL3      = 32'h14;
    localparam logic [31:0] ADDR_KERNEL4      = 32'h18;
    localparam logic [31:0] ADDR_KERNEL5      = 32'h1C;
    localparam logic [31:0] ADDR_KERNEL6      = 32'h20;
    localparam logic [31:0] ADDR_KERNEL7      = 32'h24;
    localparam logic [31:0] ADDR_KERNEL8      = 32'h28;

    localparam logic [31:0] ADDR_FAULT_STATUS = 32'h2C;
    localparam logic [31:0] ADDR_FAULT_COUNT  = 32'h30;

    logic [8:0] kernel_parity;

    logic [31:0] read_data_next;
    logic [1:0]  read_resp_next;

    // ------------------------------------------------------------
    // AXI ready signals
    // ------------------------------------------------------------

    always_comb begin
        s_axi_awready = ~s_axi_bvalid;
        s_axi_wready  = ~s_axi_bvalid;
        s_axi_arready = ~s_axi_rvalid;
    end

    // ------------------------------------------------------------
    // Kernel parity checking
    // ------------------------------------------------------------

    always_comb begin
        kernel_parity_err = 1'b0;

        if ((^kernel0) != kernel_parity[0])
            kernel_parity_err = 1'b1;

        if ((^kernel1) != kernel_parity[1])
            kernel_parity_err = 1'b1;

        if ((^kernel2) != kernel_parity[2])
            kernel_parity_err = 1'b1;

        if ((^kernel3) != kernel_parity[3])
            kernel_parity_err = 1'b1;

        if ((^kernel4) != kernel_parity[4])
            kernel_parity_err = 1'b1;

        if ((^kernel5) != kernel_parity[5])
            kernel_parity_err = 1'b1;

        if ((^kernel6) != kernel_parity[6])
            kernel_parity_err = 1'b1;

        if ((^kernel7) != kernel_parity[7])
            kernel_parity_err = 1'b1;

        if ((^kernel8) != kernel_parity[8])
            kernel_parity_err = 1'b1;
    end

    // ------------------------------------------------------------
    // AXI write and read transactions
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (rst) begin
            // AXI response registers
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;

            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'b0;

            // Control
            start <= 1'b0;

            // Kernel registers
            kernel0 <= 8'sd0;
            kernel1 <= 8'sd0;
            kernel2 <= 8'sd0;
            kernel3 <= 8'sd0;
            kernel4 <= 8'sd0;
            kernel5 <= 8'sd0;
            kernel6 <= 8'sd0;
            kernel7 <= 8'sd0;
            kernel8 <= 8'sd0;

            // Matching parity for zero-valued kernels
            kernel_parity <= 9'b0;

        end else begin

            // Default: start is a one-cycle pulse
            start <= 1'b0;

            // ----------------------------------------------------
            // Write response handshake
            // ----------------------------------------------------

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            // ----------------------------------------------------
            // Write transaction
            // ----------------------------------------------------

            if (s_axi_awvalid &&
                s_axi_awready &&
                s_axi_wvalid &&
                s_axi_wready) begin

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

                case (s_axi_awaddr)

                    ADDR_CONTROL: begin
                        if (s_axi_wstrb[0] && s_axi_wdata[0])
                            start <= 1'b1;
                    end

                    ADDR_KERNEL0: begin
                        if (s_axi_wstrb[0]) begin
                            kernel0 <= s_axi_wdata[7:0];
                            kernel_parity[0] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL1: begin
                        if (s_axi_wstrb[0]) begin
                            kernel1 <= s_axi_wdata[7:0];
                            kernel_parity[1] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL2: begin
                        if (s_axi_wstrb[0]) begin
                            kernel2 <= s_axi_wdata[7:0];
                            kernel_parity[2] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL3: begin
                        if (s_axi_wstrb[0]) begin
                            kernel3 <= s_axi_wdata[7:0];
                            kernel_parity[3] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL4: begin
                        if (s_axi_wstrb[0]) begin
                            kernel4 <= s_axi_wdata[7:0];
                            kernel_parity[4] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL5: begin
                        if (s_axi_wstrb[0]) begin
                            kernel5 <= s_axi_wdata[7:0];
                            kernel_parity[5] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL6: begin
                        if (s_axi_wstrb[0]) begin
                            kernel6 <= s_axi_wdata[7:0];
                            kernel_parity[6] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL7: begin
                        if (s_axi_wstrb[0]) begin
                            kernel7 <= s_axi_wdata[7:0];
                            kernel_parity[7] <= ^s_axi_wdata[7:0];
                        end
                    end

                    ADDR_KERNEL8: begin
                        if (s_axi_wstrb[0]) begin
                            kernel8 <= s_axi_wdata[7:0];
                            kernel_parity[8] <= ^s_axi_wdata[7:0];
                        end
                    end

                    default: begin
                        s_axi_bresp <= 2'b10;
                    end

                endcase
            end

            // ----------------------------------------------------
            // Read response handshake
            // ----------------------------------------------------

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            // ----------------------------------------------------
            // Read transaction
            // ----------------------------------------------------

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                s_axi_rdata  <= 32'b0;

                case (s_axi_araddr)

                    ADDR_CONTROL: begin
                        s_axi_rdata <= {31'b0, start};
                    end

                    ADDR_STATUS: begin
                        s_axi_rdata <= {
                            28'b0,
                            kernel_parity_err,
                            error,
                            done,
                            busy
                        };
                    end

                    ADDR_KERNEL0:
                        s_axi_rdata <= {{24{kernel0[7]}}, kernel0};

                    ADDR_KERNEL1:
                        s_axi_rdata <= {{24{kernel1[7]}}, kernel1};

                    ADDR_KERNEL2:
                        s_axi_rdata <= {{24{kernel2[7]}}, kernel2};

                    ADDR_KERNEL3:
                        s_axi_rdata <= {{24{kernel3[7]}}, kernel3};

                    ADDR_KERNEL4:
                        s_axi_rdata <= {{24{kernel4[7]}}, kernel4};

                    ADDR_KERNEL5:
                        s_axi_rdata <= {{24{kernel5[7]}}, kernel5};

                    ADDR_KERNEL6:
                        s_axi_rdata <= {{24{kernel6[7]}}, kernel6};

                    ADDR_KERNEL7:
                        s_axi_rdata <= {{24{kernel7[7]}}, kernel7};

                    ADDR_KERNEL8:
                        s_axi_rdata <= {{24{kernel8[7]}}, kernel8};

                    // Bit 0: fault active
                    // Bits 7:4: first fault code
                    ADDR_FAULT_STATUS: begin
                        s_axi_rdata <= {
                            24'b0,
                            first_fault_code,
                            3'b0,
                            fault_active
                        };
                    end

                    // Number of recorded fault episodes
                    ADDR_FAULT_COUNT: begin
                        s_axi_rdata <= fault_count;
                    end

                    default: begin
                        s_axi_rdata <= 32'b0;
                        s_axi_rresp <= 2'b10;
                    end

                endcase
            end
        end
    end

endmodule