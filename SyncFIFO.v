module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data,
    output wire fifo_full,
    output wire fifo_empty,
    output reg valid_wr,
    output reg valid_rd,
    output reg [ADDR_WIDTH:0] fifo_count
);

    // FIFO Depth
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    // Register File (FIFO Memory)
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Read and Write Pointers
    reg [ADDR_WIDTH:0] wr_ptr = 0;
    reg [ADDR_WIDTH:0] rd_ptr = 0;

    // Address Signals
    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // FIFO Full and Empty Conditions
    assign fifo_full  = (fifo_count == FIFO_DEPTH);
    assign fifo_empty = (fifo_count == 0);

    // Write Operation
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            valid_wr <= 0;
        end else if (wr_en && !fifo_full) begin
            fifo_mem[wr_addr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            valid_wr <= 1;
        end else begin
            valid_wr <= 0;
        end
    end

    // Read Operation
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_data <= 0;
            valid_rd <= 0;
        end else if (rd_en && !fifo_empty) begin
            rd_data <= fifo_mem[rd_addr];
            rd_ptr <= rd_ptr + 1;
            valid_rd <= 1;
        end else begin
            valid_rd <= 0;
        end
    end

    // Status Block: FIFO Count Management
    always @(posedge clk) begin
        if (rst) begin
            fifo_count <= 0;
        end else if (wr_en && !fifo_full && !(rd_en && !fifo_empty)) begin
            fifo_count <= fifo_count + 1;
        end else if (rd_en && !fifo_empty && !(wr_en && !fifo_full)) begin
            fifo_count <= fifo_count - 1;
        end
    end

endmodule

