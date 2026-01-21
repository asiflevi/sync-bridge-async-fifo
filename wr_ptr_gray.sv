module wr_ptr_gray(
    input  logic            clk,
    input  logic            resetb,
    input  logic            en,
    output logic [3:0] out
);

    logic [3:0] q_gray, d_gray;
    logic [3:0] q_bin,  d_bin;

    // Gray -> Bin
    gray2bin #(.W(4)) u_g2b (
        .gray(q_gray),
        .bin (q_bin)
    );

    // compute next binary
    always_comb begin
        d_bin  = q_bin;
        if (en) d_bin = q_bin + 1'b1;
    end

    // Bin -> Gray
    bin2gray #(.W(4)) u_b2g (
        .bin (d_bin),
        .gray(d_gray)
    );

    // register Gray
    always_ff @(posedge clk or negedge resetb) begin
        if (!resetb) begin
            q_gray <= 4'b0;
        end else begin
            q_gray <= d_gray;
        end
    end

    assign out = q_gray;

endmodule
