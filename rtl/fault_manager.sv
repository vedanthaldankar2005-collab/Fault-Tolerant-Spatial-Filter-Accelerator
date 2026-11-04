`timescale 1ns / 1ps

module fault_manager (
    input  logic       clk,
    input  logic       rst_n,

    // Fault inputs
    input  logic       tmr_error,
    input  logic       kernel_parity_error,
    input  logic       residue_error,
    input  logic       timeout_error,

    // Software acknowledgement
    input  logic       clear_fault,

    // Latched fault status
    output logic       fault_active,

    // First detected fault category
    output logic [3:0] first_fault_code,

    // Total number of fault events observed
    output logic [31:0] fault_count
);

    // Fault category encoding
    localparam logic [3:0] FAULT_NONE    = 4'd0;
    localparam logic [3:0] FAULT_TMR     = 4'd1;
    localparam logic [3:0] FAULT_PARITY  = 4'd2;
    localparam logic [3:0] FAULT_RESIDUE = 4'd3;
    localparam logic [3:0] FAULT_TIMEOUT = 4'd4;

    logic fault_now;
    logic [3:0] current_fault_code;

    // Detect whether any fault is present.
    always_comb begin
        fault_now = tmr_error |
                    kernel_parity_error |
                    residue_error |
                    timeout_error;
    end

    // Select the highest-priority fault category.
    // Priority: TMR > parity > residue > timeout.
    always_comb begin
        current_fault_code = FAULT_NONE;

        if (tmr_error)
            current_fault_code = FAULT_TMR;
        else if (kernel_parity_error)
            current_fault_code = FAULT_PARITY;
        else if (residue_error)
            current_fault_code = FAULT_RESIDUE;
        else if (timeout_error)
            current_fault_code = FAULT_TIMEOUT;
    end

    // Latch fault information until software clears it.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_active    <= 1'b0;
            first_fault_code <= FAULT_NONE;
            fault_count     <= 32'd0;
        end
        else begin

            // Count each newly observed fault assertion.
            if (fault_now && !fault_active) begin
                fault_count <= fault_count + 1'b1;
            end

            // Preserve the first fault category while active.
            if (fault_now && !fault_active) begin
                fault_active     <= 1'b1;
                first_fault_code <= current_fault_code;
            end
            else if (clear_fault && !fault_now) begin
                fault_active     <= 1'b0;
                first_fault_code <= FAULT_NONE;
            end

        end
    end

endmodule