module register (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] data_in,
    output logic [7:0] data_out
);

    always_ff @(posedge clk) begin
        if (rst)
            data_out <= 8'd0;
        else
            data_out <= data_in;
    end

endmodule