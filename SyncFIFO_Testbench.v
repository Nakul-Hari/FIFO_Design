`timescale 1ns / 1ps

module tb_sync_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    // DUT Signals
    reg clk, rst, wr_en, rd_en;
    reg [DATA_WIDTH-1:0] wr_data;
    wire [DATA_WIDTH-1:0] rd_data;
    wire fifo_full, fifo_empty;

    // Instantiate FIFO
    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

    // Testbench Variables
    reg [DATA_WIDTH-1:0] expected_data [0:FIFO_DEPTH-1];
    integer write_ptr, read_ptr;

    // Clock Generation
    always #5 clk = ~clk;

    // Task: Write to FIFO
    task automatic write_fifo(input [DATA_WIDTH-1:0] data);
        begin
            if (!fifo_full) begin
                wr_data = data;
                wr_en = 1;
                #10;  // Wait for one clock cycle
                wr_en = 0;
                expected_data[write_ptr] = data; // Store for verification
                write_ptr = (write_ptr + 1) % FIFO_DEPTH;
                $display("WRITE: Data = %h | FIFO Full = %b | FIFO Empty = %b", data, fifo_full, fifo_empty);
            end else begin
                $display("ATTEMPTED WRITE WHEN FULL: Data = %h | FIFO Full = %b", data, fifo_full);
            end
        end
    endtask

    // Task: Read from FIFO
    task automatic read_fifo;
        begin
            if (!fifo_empty) begin
                rd_en = 1;
                #10;  // Wait for one clock cycle
                rd_en = 0;
                if (rd_data !== expected_data[read_ptr]) begin
                    $display("ERROR: Data Mismatch! Expected = %h, Got = %h", expected_data[read_ptr], rd_data);
                end else begin
                    $display("READ: Data = %h | FIFO Full = %b | FIFO Empty = %b", rd_data, fifo_full, fifo_empty);
                end
                read_ptr = (read_ptr + 1) % FIFO_DEPTH;
            end else begin
                $display("ATTEMPTED READ WHEN EMPTY | FIFO Empty = %b", fifo_empty);
            end
        end
    endtask

    // Assertions for Self-Checking is full
    property no_write_when_full;
        @(posedge clk) disable iff (rst)
        (wr_en && fifo_full) |-> ##1 !$isunknown(wr_data);
    endproperty
    assert property (no_write_when_full)
    else $error("ASSERTION FAILED: Write attempted when FIFO is full");

    // Assert that no read occurs when FIFO is empty
    property no_read_when_empty;
        @(posedge clk) disable iff (rst)
        (rd_en && fifo_empty) |-> ##1 !$isunknown(rd_data);
    endproperty
    assert property (no_read_when_empty)
    else $error("ASSERTION FAILED: Read attempted when FIFO is empty");

    // Test Sequence
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        write_ptr = 0;
        read_ptr = 0;
        #20;
        rst = 0;  // Release Reset

        // Randomized Write and Read Operations
        repeat (20) begin
            if ($random % 2) begin
                write_fifo($random);
            end else begin
                read_fifo();
            end
            #10;
        end

        // Attempt to overfill the FIFO
        repeat (FIFO_DEPTH + 2) begin
            write_fifo($random);
            #10;
        end

        // Attempt to over-read the FIFO
        repeat (FIFO_DEPTH + 2) begin
            read_fifo();
            #10;
        end

        // Finish Simulation
        $display("TEST COMPLETED");
        $finish;
    end
endmodule

