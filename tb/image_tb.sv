`timescale 1ns/1ps

module image_tb;

    localparam IMAGE_WIDTH  = 128;
    localparam IMAGE_HEIGHT = 128;
    localparam TOTAL_PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam TOTAL_OUTPUTS =
        (IMAGE_WIDTH - 2) * (IMAGE_HEIGHT - 2);

    localparam CLOCK_PERIOD_NS = 10;

    logic clk;
    logic rst;

    // AXI4-Lite interface
    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;

    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    logic        s_axi_wready;

    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    // Pixel and result interfaces
    logic [7:0] pixel_in;
    logic       pixel_valid;

    logic signed [19:0] result;
    logic               result_valid;

    logic busy;
    logic done;
    logic error;

    // Image memory
    reg [7:0] image_memory [0:TOTAL_PIXELS-1];

    // Counters
    integer pixel_index;
    integer pixel_count;
    integer output_count;
    integer file_handle;
    integer cycle_count;

    integer first_output_cycle;
    integer last_output_cycle;

    integer first_output_seen;
    integer last_output_seen;

    // Timestamp measurements
    time first_pixel_time;
    time first_output_time;
    time last_output_time;

    time first_output_latency;
    time last_output_latency;
    time output_production_time;

    // DUT
    accelerator_top #(
        .IMAGE_WIDTH(IMAGE_WIDTH)
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

    // Clock: 10 ns period = 100 MHz
    initial clk = 1'b0;
    always #(CLOCK_PERIOD_NS/2) clk = ~clk;

    // Count rising clock edges.
    always @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // AXI4-Lite write task
    task axi_write;
        input [31:0] address;
        input [31:0] data;

        begin
            @(negedge clk);

            s_axi_awaddr  = address;
            s_axi_awvalid = 1'b1;

            s_axi_wdata   = data;
            s_axi_wstrb   = 4'b0001;
            s_axi_wvalid  = 1'b1;

            @(posedge clk);
            #1;

            s_axi_awvalid = 1'b0;
            s_axi_wvalid  = 1'b0;

            wait (s_axi_bvalid == 1'b1);

            @(negedge clk);
            s_axi_bready = 1'b1;

            @(posedge clk);
            #1;

            s_axi_bready = 1'b0;
        end
    endtask

    // Capture an output and record first/last output timestamps.
    task capture_output;
        begin
            if (result_valid) begin

                $fdisplay(file_handle, "%0d", $signed(result));

                output_count = output_count + 1;

                if (first_output_seen == 0) begin
                    first_output_time = $time;
                    first_output_cycle = cycle_count;
                    first_output_seen = 1;
                end

                last_output_time = $time;
                last_output_cycle = cycle_count;
                last_output_seen = 1;
            end
        end
    endtask

    initial begin

        // Display all %t timestamps in nanoseconds.
        $timeformat(-9, 0, " ns", 12);

        // Initialize signals
        clk = 1'b0;
        rst = 1'b1;

        s_axi_awaddr  = 32'd0;
        s_axi_awvalid = 1'b0;

        s_axi_wdata   = 32'd0;
        s_axi_wstrb   = 4'd0;
        s_axi_wvalid  = 1'b0;

        s_axi_bready  = 1'b0;

        s_axi_araddr  = 32'd0;
        s_axi_arvalid = 1'b0;
        s_axi_rready  = 1'b0;

        pixel_in      = 8'd0;
        pixel_valid   = 1'b0;

        pixel_count   = 0;
        output_count  = 0;
        cycle_count   = 0;

        first_pixel_time  = 0;
        first_output_time = 0;
        last_output_time  = 0;

        first_output_cycle = 0;
        last_output_cycle  = 0;

        first_output_seen = 0;
        last_output_seen  = 0;

        // Load image
        $display("");
        $display("==============================================");
        $display("       128x128 SOBEL-X IMAGE TEST");
        $display("==============================================");

        $readmemh(
            "results/tree_input_128x128.hex",
            image_memory
        );

        $display("Image loaded: %0d pixels", TOTAL_PIXELS);

        // Open output file
        file_handle = $fopen(
            "results/rtl_tree_sobel_x_output.txt",
            "w"
        );

        if (file_handle == 0) begin
            $display("ERROR: Cannot open RTL output file.");
            $finish;
        end

        // Reset
        #20;
        rst = 1'b0;
        #20;

        // Program Sobel-X kernel:
        //
        // -1  0 +1
        // -2  0 +2
        // -1  0 +1

        $display("Programming Sobel-X kernel...");

        axi_write(32'h08, 32'h000000FF);
        axi_write(32'h0C, 32'h00000000);
        axi_write(32'h10, 32'h00000001);

        axi_write(32'h14, 32'h000000FE);
        axi_write(32'h18, 32'h00000000);
        axi_write(32'h1C, 32'h00000002);

        axi_write(32'h20, 32'h000000FF);
        axi_write(32'h24, 32'h00000000);
        axi_write(32'h28, 32'h00000001);

        $display("Sobel-X kernel programmed.");

        // Start accelerator
        axi_write(32'h00, 32'h00000001);

        // Begin image stream.
        // Timestamp the first pixel at its sampling edge.
        pixel_valid = 1'b1;

        for (pixel_index = 0;
             pixel_index < TOTAL_PIXELS;
             pixel_index = pixel_index + 1) begin

            @(negedge clk);
            pixel_in = image_memory[pixel_index];

            @(posedge clk);
            #1;

            if (pixel_index == 0)
                first_pixel_time = $time;

            pixel_count = pixel_count + 1;

            capture_output();
        end

        // Stop sending pixels
        @(negedge clk);
        pixel_valid = 1'b0;

        // Drain the remaining pipeline.
        repeat (20) begin
            @(posedge clk);
            #1;
            capture_output();
        end

        // Close output file
        $fclose(file_handle);

        // Calculate latency from measured timestamps.
        if ((first_output_seen != 0) &&
            (last_output_seen != 0)) begin

            first_output_latency =
                first_output_time - first_pixel_time;

            last_output_latency =
                last_output_time - first_pixel_time;

            output_production_time =
                last_output_time - first_output_time;
        end
        else begin
            first_output_latency = 0;
            last_output_latency = 0;
            output_production_time = 0;
        end

        // Final functional report
        $display("");
        $display("==============================================");
        $display("             FUNCTIONAL RESULTS");
        $display("==============================================");

        $display("Input pixels  = %0d", pixel_count);
        $display("RTL outputs   = %0d", output_count);
        $display("Expected      = %0d", TOTAL_OUTPUTS);
        $display("BUSY          = %0d", busy);
        $display("DONE          = %0d", done);
        $display("ERROR         = %0d", error);

        // Latency report
        $display("");
        $display("==============================================");
        $display("         SIMULATED HARDWARE LATENCY");
        $display("==============================================");

        $display("Clock period              = %0d ns",
                 CLOCK_PERIOD_NS);

        $display("Clock frequency           = 100 MHz");

        $display("First input pixel time    = %0t",
                 first_pixel_time);

        $display("First output time         = %0t",
                 first_output_time);

        $display("Last output time          = %0t",
                 last_output_time);

        $display("First-output latency      = %0t",
                 first_output_latency);

        $display("First-output latency cycles = %0d",
                 first_output_latency / CLOCK_PERIOD_NS);

        $display("Last-output latency       = %0t",
                 last_output_latency);

        $display("Last-output latency cycles = %0d",
                 last_output_latency / CLOCK_PERIOD_NS);

        $display("Output production time    = %0t",
                 output_production_time);

        $display("Output production cycles  = %0d",
                 output_production_time / CLOCK_PERIOD_NS);

        $display("==============================================");

        $display("");
        $display("RTL output file:");
        $display("results/rtl_tree_sobel_x_output.txt");

        // Pass/fail
        if ((pixel_count == TOTAL_PIXELS) &&
            (output_count == TOTAL_OUTPUTS) &&
            (error == 1'b0) &&
            (first_output_seen != 0) &&
            (last_output_seen != 0)) begin

            $display("");
            $display("128x128 TREE IMAGE RTL TEST: PASS");
        end
        else begin
            $display("");
            $display("128x128 TREE IMAGE RTL TEST: FAIL");
        end

        $display("==============================================");

        $finish;
    end

endmodule