module tb;

    parameter ADDR_WIDTH = 3;
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 8;

    reg wr_en, rd_en;
    reg [DATA_WIDTH-1:0] wr_data;
    wire full, empty;
    reg wr_clk, wr_rst;
    reg rd_clk, rd_rst;
    wire [DATA_WIDTH-1:0] rd_data;
    
    reg [DATA_WIDTH-1:0] q[$];
    reg [DATA_WIDTH-1:0] temp;

    async_fifo_assertion #(ADDR_WIDTH, DATA_WIDTH, DEPTH) DUT (wr_en, wr_data, full, wr_clk, wr_rst, rd_en, rd_clk, rd_rst, rd_data, empty);

    always #10 wr_clk = ~wr_clk;
    always #35 rd_clk = ~rd_clk;

  	task write(); 

        wr_clk = 1'b0; wr_rst = 1'b1;
        wr_en = 1'b0;
        wr_data = 0;

        repeat(5) @(posedge wr_clk);
        wr_rst = 1'b0;

        for (int i = 0; i < DEPTH; i++) begin
          @(posedge wr_clk); // let reset be applied fully then wr_en = 1'b1 not at same clk
            if (!full) begin
                wr_en = 1;
                wr_data = $urandom_range(0, 255);
                q.push_back(wr_data);
                $display("WRITE: %0d", wr_data);
            end
          @(posedge wr_clk); // data written then wr_en is 0
            wr_en = 0;
        end

        wr_en = 0; 

    endtask

  task read();

        rd_clk = 1'b0; rd_rst = 1'b1;
        rd_en = 1'b0;

        repeat(10) @(posedge rd_clk);
        rd_rst = 1'b0;

        repeat(5) @(posedge wr_clk); // for data to propogate across domains

        while (q.size() > 0) begin
            if (!empty) begin
                rd_en = 1;
                @(posedge rd_clk);
                temp = q.pop_front();
                if (rd_data === temp) begin
                    $display("DATA MATCHED: %0d", temp);
                end else begin
                    $display("DATA MISMATCHED: pop_data: %0d, output: %0d", temp, rd_data);
                end
              rd_en = 1'b0;
            end
        end

  endtask
  
  initial begin
    
    fork
      
      write();
      read();
      
    join

    $finish();
    
  end

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars;

    end

endmodule