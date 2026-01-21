`timescale 1ns/1ps

module tb_async_fifo_v2;
  // Clocks per Lab 5 specs: clka=80MHz (12.5ns), clkb=50MHz (20ns)
  logic clka = 0, clkb = 0;
  always #6.25 clka = ~clka; 
  always #10.0  clkb = ~clkb;

  logic resetb_clkb, wr, rd, full, empty;
  logic resetb_clka;
  logic [7:0] din_clka, dout_clkb;

  // Instantiate DUT
  // async_fifo dut (.*);

  my_fifo dut (.*);

  // --- WRITE SIDE (Block A) ---
  initial begin
    resetb_clkb = 0;
    resetb_clka = 0;
    wr = 0; din_clka = 0;
    #50
    resetb_clkb = 1;
    resetb_clka = 1;
  
    
    // Fill the FIFO completely
    @(posedge clka);
    while (!full) begin
      wr = 1;
      din_clka = din_clka + 1;
      @(posedge clka);
    end
    wr = 0;
  end

  // --- READ SIDE (Block B) ---
  initial begin
    rd = 0;
    wait(resetb_clkb);
    
    // Just keep reading whenever data is available
    forever begin
      @(posedge clkb);
      rd = !empty; // Read if not empty
    end
  end

  // --- FINISH ---
  initial #1000 $finish;

endmodule