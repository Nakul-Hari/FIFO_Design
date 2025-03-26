`timescale 1ns / 1ps

module tb_async_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = 1 << ADDR_WIDTH;

    // DUT Signals
    reg wr_clk = 0, rd_clk = 0;
    reg wr_rst_n = 0, rd_rst_n = 0;
    reg wr_en = 0, rd_en = 0;
    reg [DATA_WIDTH-1:0] wr_data = 0;
    wire [DATA_WIDTH-1:0] rd_data;
    wire fifo_full, fifo_empty;

    // Instantiate the FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .wr_rst_n(wr_rst_n),
        .rd_rst_n(rd_rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

    // Testbench Variables
    reg [DATA_WIDTH-1:0] test_vector [0:FIFO_DEPTH-1];
    integer write_ptr = 0, read_ptr = 0;

    // Clock Generation
    initial begin
        forever #5 wr_clk = ~wr_clk; // 10ns period
    end

    initial begin
        forever #7 rd_clk = ~rd_clk; // 14ns period
    end

    // Automatic keyword used with tasks (and functions) specifies that the task should have automatic storage for its local variables
  
  
    // Task: Write to FIFO
    task automatic write_fifo(input [DATA_WIDTH-1:0] data);
        begin
            @(posedge wr_clk);
            if (!fifo_full) begin
                wr_data = data;
                wr_en = 1;
                @(posedge wr_clk);
                wr_en = 0;
                test_vector[write_ptr] = data; // Store for verification
                write_ptr = (write_ptr + 1) % FIFO_DEPTH;
                $display("WRITE: Data = %h at time %t", data, $time);
            end else begin
                $display("ATTEMPTED WRITE WHEN FULL: Data = %h at time %t", data, $time);
            end
        end
    endtask

    // Task: Read from FIFO
    task automatic read_fifo;
        begin
            @(posedge rd_clk);
            if (!fifo_empty) begin
                rd_en = 1;
                @(posedge rd_clk); // First cycle: rd_en asserted
                rd_en = 0;
                @(posedge rd_clk);  // Second cycle: data available
                if (rd_data !== test_vector[read_ptr]) begin
                    $display("ERROR: Data Mismatch! Expected = %h, Got = %h at time %t", test_vector[read_ptr], rd_data, $time);
                end else begin
                    $display("READ: Data = %h at time %t", rd_data, $time);
                end
                read_ptr = (read_ptr + 1) % FIFO_DEPTH;
            end else begin
                $display("ATTEMPTED READ WHEN EMPTY at time %t", $time);
            end
        end
    endtask
  
  
    // Assertions
    always @(posedge wr_clk) begin
        if (wr_en && fifo_full) begin
            $display("ASSERTION FAILED: Write attempted when FIFO is full at time %t", $time);
            $stop;
        end
    end

    always @(posedge rd_clk) begin
        if (rd_en && fifo_empty) begin
            $display("ASSERTION FAILED: Read attempted when FIFO is empty at time %t", $time);
            $stop;
        end
    end

    // Test Sequence
    initial begin
        // Apply reset
        #20;
        wr_rst_n = 1;
        rd_rst_n = 1;


        // Corner Case: Attempt to Write when Full
        repeat (FIFO_DEPTH) begin
            write_fifo($random);
            #10;
        end
        write_fifo($random); // This should trigger full condition
      

        // Corner Case: Attempt to Read when Empty
        repeat (FIFO_DEPTH) begin
          
            read_fifo();
            #14;
        end
        read_fifo(); // This should trigger empty condition
      

        // Finish Simulation
        $display("TEST COMPLETED");
        $finish;
    end
endmodule
