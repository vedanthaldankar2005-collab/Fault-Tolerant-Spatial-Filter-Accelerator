`timescale 1ns / 1ps

module fault_injector #(
    parameter integer DATA_WIDTH = 32
)(
    input  logic                  enable,
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic [DATA_WIDTH-1:0] fault_mask,
    output logic [DATA_WIDTH-1:0] data_out
);

    always_comb begin
        if (enable)
            data_out = data_in ^ fault_mask;
        else
            data_out = data_in;
    end

endmodule