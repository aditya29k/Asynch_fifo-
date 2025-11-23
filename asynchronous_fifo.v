`ifndef DATA_WIDTH;
	`define DATA_WIDTH 8
`endif

`ifndef DEPTH
	`define DEPTH 8
`endif

`ifndef PTR_WIDTH
	`define PTR_WIDTH $clog2(`DEPTH)
`endif

module async_fifo(
  input clka, rsta,
  input [`DATA_WIDTH-1:0] data_in,
  input wr_en,
  output full,
  
  input clkb, rstb,
  output reg [`DATA_WIDTH-1:0] data_out,
  input rd_en,
  output empty
);
  
  reg [`PTR_WIDTH:0] bin_wr_ptr, bin_rd_ptr;
  reg [`PTR_WIDTH:0] gray_wr_ptr, gray_rd_ptr;
  reg [`PTR_WIDTH:0] sync1_wr_ptr, sync1_rd_ptr;
  reg [`PTR_WIDTH:0] sync2_wr_ptr, sync2_rd_ptr;
  wire [`PTR_WIDTH:0] wr_sync, rd_sync;
  
  reg [`DATA_WIDTH-1:0] fifo [0:`DEPTH-1];
  
  integer i;
  
  function [`PTR_WIDTH:0] b2g;
    input [`PTR_WIDTH:0] bin;
    integer i;
    begin
      b2g[`PTR_WIDTH] = bin[`PTR_WIDTH];
      for(i=`PTR_WIDTH; i>0; i=i-1) begin
        b2g[i-1] = bin[i-1]^bin[i];
      end
    end
  endfunction
  
  always@(posedge clka) begin
    if(rsta) begin
      bin_wr_ptr <= 0;
      gray_wr_ptr <= 0;
      
      for(i = 0; i<`DEPTH; i=i+1) begin
        fifo[i] <= 0;
      end
    end
    else begin
      if(wr_en&&!full) begin
        fifo[bin_wr_ptr[`PTR_WIDTH-1:0]] <= data_in;
        bin_wr_ptr <= bin_wr_ptr + 1;
        gray_wr_ptr <= b2g(bin_wr_ptr+1);
      end
    end
  end
  
  always@(posedge clkb) begin
    if(rstb) begin
      bin_rd_ptr <= 0;
      gray_rd_ptr <= 0;
      data_out <= 0;
    end
    else begin
      if(rd_en&&!empty) begin
        data_out <= fifo[bin_rd_ptr[`PTR_WIDTH-1:0]];
        bin_rd_ptr <= bin_rd_ptr + 1;
        gray_rd_ptr <= b2g(bin_rd_ptr + 1);
      end
    end
  end
  
  always@(posedge clka) begin
    if(rsta) begin
      sync1_rd_ptr <= 0;
      sync2_rd_ptr <= 0;
    end
    else begin
      sync1_rd_ptr <= gray_rd_ptr;
      sync2_rd_ptr <= sync1_rd_ptr;
    end
  end
  
  always@(posedge clkb) begin
    if(rstb) begin
      sync1_wr_ptr <= 0;
      sync2_wr_ptr <= 0;
    end
    else begin
      sync1_wr_ptr <= gray_wr_ptr;
      sync2_wr_ptr <= sync1_wr_ptr;
    end
  end
  
  function [`PTR_WIDTH:0] g2b;
    input [`PTR_WIDTH:0] gray;
    integer i;
    begin
      g2b[`PTR_WIDTH] = gray[`PTR_WIDTH];
      for(i=`PTR_WIDTH; i>0; i=i-1) begin
        g2b[i-1] = gray[i-1]^g2b[i];
      end
    end
  endfunction
  
  assign wr_sync = g2b(sync2_wr_ptr);
  assign rd_sync = g2b(sync2_rd_ptr);
  
  assign full = (bin_wr_ptr[`PTR_WIDTH] != rd_sync[`PTR_WIDTH])&&(bin_wr_ptr[`PTR_WIDTH-1:0] == rd_sync[`PTR_WIDTH-1:0]);
  assign empty = (bin_rd_ptr == wr_sync);
  
endmodule

