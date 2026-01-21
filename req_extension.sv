module req_extension (
    input logic clk,
    input logic resetb,
    input logic data_req,
    output logic out
);

logic [4:0] count;
logic [4:0] next_count;
logic en;
logic [4:0] mux_out;

localparam MAX_VAL = 5'd21;

assign out = (count!= 5'd0);
assign en = (data_req | (count != 5'd0));

always_comb begin 
    // Default assignments: All signals get a value here first
    next_count = count; 
    mux_out    = count;

    if (count == MAX_VAL) begin
        next_count = 5'd0;
    end
    else begin
        if (!en) begin
            mux_out = count;
        end
        else begin
            mux_out = count + 5'd1;
        end
        next_count = mux_out;
    end   
end

always_ff@(posedge clk or negedge resetb)begin
    if(!resetb) begin
        count<=5'd0;
    end
    else begin
        count<=next_count;
    end
end

endmodule