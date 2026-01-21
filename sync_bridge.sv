module sync_bridge (
    input logic clka,//80MHz clock
    input logic clkb,//50MHz clock
    input logic resetb_clkb,//Async active low reset, with positive edge synchronized with clkb
    input logic [7:0] din_clka,//Data from burst generator
    input logic data_req_clkb,//Data request from block B (1 cycle)
    input logic data_valid_clka,//Data valid indication from block A
    output logic data_req_clka,//Data request to block A
    output logic data_valid_clkb,//Data valid indication to block B
    output logic [7:0] dout_clkb//Random data to block B
);

//internal signals as appear in the scheme
logic synced_pulse;
logic resetb_clka;
logic one_pulse;
logic derive_d;
logic derive_q;
logic data_valid_for_b;
logic data_valid_for_b_sampled;

async_fifo async_fifo_inst( .clka(clka) , .clkb(clkb) , .resetb_clkb(resetb_clkb) ,
 .din_clka(din_clka) , .wr(data_valid_clka) , .rd(1'b1) , .empty(data_valid_for_b) , .dout_clkb(dout_clkb) , .resetb_clka(resetb_clka));

//resetb_clka creating using techniuqe from class
dff_sync dff_sync_inst_reseta( .clk(clka) , .resetb(resetb_clkb) , .d(1'b1) , .q(resetb_clka));

//data request from block b sync to domain a
dff_sync dff_sync_inst_second( .clk(clka) , .resetb(resetb_clka) , .d(data_req_clkb) , .q(synced_pulse));

//extesnion of the synced pulse from domain b into 21 cyceles 
req_extension req_extension_inst( .clk(clka) ,.resetb(resetb_clka) , .data_req(synced_pulse) , .out(data_req_clka));

//assigin data_valid_clkb
assign data_valid_clkb = data_valid_for_b_sampled;

//flop to sample the not(empty) from fifo to assign data_valid_clkb as in the scheme
always_ff@(posedge clkb or negedge resetb_clkb)begin
    if(!resetb_clkb)begin
        data_valid_for_b_sampled<=1'b0;
    end
    else begin
     data_valid_for_b_sampled<=~(data_valid_for_b);
    
    end

end
endmodule
