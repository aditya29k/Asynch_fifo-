`ifndef DATA_WIDTH;
	`define DATA_WIDTH 8
`endif

`ifndef DEPTH
	`define DEPTH 8
`endif

`ifndef PTR_WIDTH
	`define PTR_WIDTH 3
`endif

interface async_intf;
  
  logic clka, rsta, clkb, rstb;
  logic [`DATA_WIDTH-1:0] data_in, data_out;
  logic wr_en, rd_en;
  logic full, empty;
  
endinterface

class transaction;
  
  rand bit [`DATA_WIDTH-1:0] data_in;
  rand bit wr_en, rd_en;
  
endclass

module tb;
  
  async_intf intf();
  
  async_fifo DUT (.clka(intf.clka), .rsta(intf.rsta), .clkb(intf.clkb), .rstb(intf.rstb), .data_in(intf.data_in), .data_out(intf.data_out), .wr_en(intf.wr_en), .rd_en(intf.rd_en), .full(intf.full), .empty(intf.empty));
  
  transaction trans;
  
  initial begin
    intf.clka <= 0;
    intf.clkb <= 0;
  end
  
  always #5 intf.clka <= ~intf.clka;
  always #15 intf.clkb <= ~intf.clkb;
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
  task reset();
    intf.rsta <= 1'b1;
    intf.rstb <= 1'b1;
    intf.data_in <= 0;
    intf.wr_en <= 1'b0;
    intf.rd_en <= 1'b0;
    repeat(2) @(posedge intf.clkb);
    $display("SYSTEM RESET");
    intf.rsta <= 1'b0;
    intf.rstb <= 1'b0;
  endtask
  
  task write(transaction trans);
    @(posedge intf.clka);
    intf.wr_en <= 1'b1;
    intf.data_in <= trans.data_in;
    @(posedge intf.clka);
    intf.wr_en <= 1'b0;
    if(intf.full) begin
      $display("FIFO IS FULL");
      return;
    end
    else $display("DATA WRITTEN: %0d", trans.data_in);
    @(posedge intf.clka);
  endtask
  
  task read(transaction trans);
    @(posedge intf.clkb);
    intf.rd_en <= 1'b1;
    @(posedge intf.clkb);
    intf.rd_en <= 1'b0;
    @(posedge intf.clkb);
    if(intf.empty) begin
      $display("FIFO IS EMPTY last data: %0d", intf.data_out);
      return;
    end
    else $display("DATA: %0d", intf.data_out);
    @(posedge intf.clkb);
  endtask
  
  task run();
    trans = new();
    assert(trans.randomize()) else $error("RANDOMIZATION ERROR");
    fork
      if(trans.wr_en) write(trans);
      if(trans.rd_en) read(trans);
    join
    $display("-----------------");
  endtask
  
  initial begin
    reset();
    repeat(10)run();
    $finish();
  end
  
endmodule
