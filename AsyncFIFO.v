module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire wr_clk,           // Write clock
    input wire rd_clk,           // Read clock
    input wire wr_rst_n,         // Write domain reset (active low)
    input wire rd_rst_n,         // Read domain reset (active low)
    input wire wr_en,            // Write enable
    input wire rd_en,            // Read enable
    input wire [DATA_WIDTH-1:0] wr_data, // Write data
    output reg [DATA_WIDTH-1:0] rd_data, // Read data
    output wire fifo_full,       // FIFO full flag
    output wire fifo_empty       // FIFO empty flag
);

    // FIFO Depth
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    // FIFO Memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Write Pointer (Gray Code)
    reg [ADDR_WIDTH:0] wr_ptr_bin = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1 = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2 = 0;

    // Read Pointer (Gray Code)
    reg [ADDR_WIDTH:0] rd_ptr_bin = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1 = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2 = 0;

    // Write Pointer Synchronization to Read Clock Domain
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Read Pointer Synchronization to Write Clock Domain
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Binary to Gray Code Conversion
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary Code Conversion
    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Write Operation
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) 
          begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end 
      else if (wr_en && !fifo_full) 
        begin
            fifo_mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
        end
    end

    // Read Operation
    always @(posedge rd_clk or negedge rd_rst_n) begin
      if (!rd_rst_n) 
        begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            rd_data <= 0;
        end 
      else if (rd_en && !fifo_empty) 
        begin
            rd_data <= fifo_mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
        end
    end

    // FIFO Full Condition
    assign fifo_full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});

    // FIFO Empty Condition
    assign fifo_empty = (rd_ptr_gray == wr_ptr_gray_sync2);

endmodule
