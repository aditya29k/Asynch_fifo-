module async_fifo#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3,
    parameter DEPTH = 8
)(
    input wr_clk, wr_en, wr_rst,
    input [DATA_WIDTH-1 : 0] wr_data,
    input rd_clk, rd_en, rd_rst,
    output [DATA_WIDTH-1 : 0] rd_data,
    output full, empty
);

    reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];

    reg [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray, wr_ptr_sync1, wr_ptr_sync2;
    wire [ADDR_WIDTH:0] wr_ptr_sync_bin;
    reg [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray, rd_ptr_sync1, rd_ptr_sync2;
    wire [ADDR_WIDTH:0] rd_ptr_sync_bin;

    // WRITE LOGIC
    always@(posedge wr_clk) begin
        if(wr_rst) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end
        else if(wr_en&~full)begin
            wr_ptr_bin <= wr_ptr_bin + 1;
            fifo[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_gray <= (wr_ptr_bin+1)^((wr_ptr_bin+1)>>1);
        end
    end

    // READ LOGIC
    always@(posedge rd_clk) begin
        if(rd_rst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end
        else if(rd_en&~empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= (rd_ptr_bin+1)^((rd_ptr_bin+1)>>1);
        end
    end

    assign rd_data = fifo[rd_ptr_bin[ADDR_WIDTH-1:0]];

    // WRITE DOUBLE SYNC
    always@(posedge rd_clk, posedge rd_rst) begin
        if(rd_rst) begin
            wr_ptr_sync1 <= 0;
            wr_ptr_sync2 <= 0;
        end
        else begin
            wr_ptr_sync1 <= wr_ptr_gray;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end

    // READ DOUBLE SYNC
    always@(posedge wr_clk, posedge wr_rst) begin
        if(wr_rst) begin
            rd_ptr_sync1 <= 0;
            rd_ptr_sync2 <= 0;
        end
        else begin
            rd_ptr_sync1 <= rd_ptr_gray;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end

    // G2B FUNCTION
    function [ADDR_WIDTH:0] g2b;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        begin

            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for(i = ADDR_WIDTH; i>0; i = i - 1) begin
                bin[i-1] = bin[i]^gray[i-1];
            end
            g2b = bin;
        end 

    endfunction
    
    // BINARY SYNCH WIRE'S
    assign rd_ptr_sync_bin = g2b(rd_ptr_sync2);
    assign wr_ptr_sync_bin = g2b(wr_ptr_sync2);

    // FLAGS

    assign full = (wr_ptr_bin[ADDR_WIDTH] != rd_ptr_sync_bin[ADDR_WIDTH])&(wr_ptr_bin[ADDR_WIDTH-1:0] == rd_ptr_sync_bin[ADDR_WIDTH-1:0]);
    assign empty = (rd_ptr_bin == wr_ptr_sync_bin);


endmodule