//async fifo module from the scheme in the class
module async_fifo (
    input logic clka,
    input logic clkb,
    input logic resetb_clka,
    input logic resetb_clkb,
    input logic [7:0] din_clka,
    input logic wr,
    input logic rd,
    output logic full,
    output logic empty,
    output logic [7:0] dout_clkb
);




logic wr_en;
logic rd_en;
logic [15:0] dec_out;
logic [7:0] reg_file [15:0];
logic [15:0] ld;
logic [3:0] b2g_left_first;
logic [3:0] g2b_left_first;
logic [3:0] g2b_right_first;
logic [3:0] g2b_left_first_plus_one;
logic [3:0] g2b_right_first_plus_one;
logic [3:0] g2b_left_down;

logic [3:0] sync_blue_out;
logic [3:0] sync_yellow_out;
logic [3:0] g2b_right_down;
logic [3:0] b2g_right_first;

dff_sync  #(.WIDTH(4)) dff_sync_blue( .clk(clka) , .resetb(resetb_clka) , .d(b2g_right_first) , .q(sync_blue_out));
dff_sync  #(.WIDTH(4)) dff_sync_yellow( .clk(clkb) , .resetb(resetb_clkb) , .d(b2g_left_first) , .q(sync_yellow_out));




assign ld = ({16{wr_en}} & dec_out);
assign wr_en = (~full & wr);
assign rd_en = (~empty & rd);

assign g2b_left_first_plus_one=g2b_left_first+4'b1;
assign g2b_right_first_plus_one=g2b_right_first+4'b1;
assign full = (g2b_left_first_plus_one== g2b_left_down);
assign empty = (g2b_right_first_plus_one==g2b_right_down );



wr_ptr_gray wr_ptr_gray_inst( .clk(clka) , .resetb(resetb_clka) , .en(wr_en) , .out(b2g_left_first));
rd_ptr_gray rd_ptr_gray_inst( .clk(clkb) , .resetb(resetb_clkb) , .en(rd_en) , .out(b2g_right_first));

gray2bin gray2bin_left_first( .gray(b2g_left_first) ,.bin(g2b_left_first));
gray2bin gray2bin_left_second( .gray(sync_blue_out) ,.bin(g2b_left_down));

gray2bin gray2bin_right_first( .gray(b2g_right_first) ,.bin(g2b_right_first));
gray2bin gray2bin_right_second( .gray(sync_yellow_out) ,.bin(g2b_right_down));





always_comb begin
    dec_out = 16'b0;   // default: all zeros
    dec_out[g2b_left_first] = 1'b1;
end

assign dout_clkb = reg_file[g2b_right_first];

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin
        always_ff @(posedge clka or negedge resetb_clka) begin
            if (!resetb_clka)
                reg_file[i] <= 8'b0;
            else if (ld[i])
                reg_file[i] <= din_clka;
        end
    end
endgenerate

    
endmodule
