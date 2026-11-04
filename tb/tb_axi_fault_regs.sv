`timescale 1ns / 1ps

module tb_axi_fault_regs;

    logic clk = 0;
    logic rst = 1;

    always #5 clk = ~clk;

    logic [31:0] s_axi_awaddr = 0;
    logic s_axi_awvalid = 0;
    wire s_axi_awready;

    logic [31:0] s_axi_wdata = 0;
    logic [3:0] s_axi_wstrb = 4'hF;
    logic s_axi_wvalid = 0;
    wire s_axi_wready;

    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    logic s_axi_bready = 1;

    logic [31:0] s_axi_araddr = 0;
    logic s_axi_arvalid = 0;
    wire s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    logic s_axi_rready = 1;

    logic [7:0] pixel_in = 0;
    logic pixel_valid = 0;

    wire signed [19:0] result;
    wire result_valid;
    wire busy;
    wire done;
    wire error;

    integer errors = 0;
    logic [31:0] read_value;

    accelerator_top #(
        .IMAGE_WIDTH(8)
    ) dut (
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

        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),

        .result(result),
        .result_valid(result_valid),

        .busy(busy),
        .done(done),
        .error(error)
    );

    task automatic axi_read(input logic [31:0] address);
        begin
            @(negedge clk);
            s_axi_araddr = address;
            s_axi_arvalid = 1'b1;

            do @(posedge clk);
            while (!s_axi_arready);

            @(negedge clk);
            s_axi_arvalid = 1'b0;

            do @(posedge clk);
            while (!s_axi_rvalid);

            read_value = s_axi_rdata;

            @(negedge clk);
            s_axi_rready = 1'b1;

            @(posedge clk);
            @(negedge clk);

            $display("AXI READ address=0x%08h data=0x%08h",
                     address, read_value);
        end
    endtask

    initial begin
        $display("========================================");
        $display(" AXI FAULT REGISTER READBACK TEST");
        $display("========================================");

        repeat (4) @(negedge clk);
        rst = 0;

        repeat (3) @(negedge clk);

        // Check fault status register at 0x2C.
        axi_read(32'h0000002C);

        if ((^read_value) === 1'bx) begin
            $display("FAIL: Fault status contains unknown bits");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Fault status register is readable");
        end

        // Check fault count register at 0x30.
        axi_read(32'h00000030);

        if ((^read_value) === 1'bx) begin
            $display("FAIL: Fault count contains unknown bits");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Fault count register is readable");
        end

        if (errors == 0)
            $display("AXI FAULT REGISTER READBACK: PASS");
        else
            $display("AXI FAULT REGISTER READBACK: FAIL (%0d errors)",
                     errors);

        $finish;
    end

    initial begin
        #100000;
        $display("FAIL: Simulation timeout");
        $finish;
    end

endmodule