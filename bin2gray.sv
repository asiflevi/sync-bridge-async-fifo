module bin2gray #(
    parameter int W = 4
) (
    input  logic [W-1:0] bin,
    output logic [W-1:0] gray
);
    // Gray code conversion:
    // gray = bin ^ (bin >> 1)
    always_comb begin
        gray = (bin >> 1) ^ bin;
    end
endmodule

