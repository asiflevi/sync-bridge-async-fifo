`timescale 1ns/1ps

module tb_ptr_simple;

  // clock
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;   // 100 MHz

  // reset and enable
  logic resetb;
  logic en;

  // outputs
  logic [3:0] wgray;
  logic [3:0] rgray;

  // DUTs
  wr_ptr_gray u_wptr (
    .clk    (clk),
    .resetb (resetb),
    .en     (en),
    .out    (wgray)
  );

  rd_ptr_gray u_rptr (
    .clk    (clk),
    .resetb (resetb),
    .en     (en),
    .out    (rgray)
  );

  integer i;

  initial begin
    // init
    resetb = 0;
    en     = 0;

    // hold reset low
    repeat (2) @(posedge clk);

    // release reset
    resetb = 1;

    // wait a little
    repeat (2) @(posedge clk);

    // ---- 50 simultaneous enable pulses ----
    for (i = 0; i < 50; i = i + 1) begin
      en = 1;
      @(posedge clk);
      en = 0;
      repeat (2) @(posedge clk);   // spacing for readability
    end

    repeat (5) @(posedge clk);
    $finish;
  end

endmodule
