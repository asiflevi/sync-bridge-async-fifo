module gray2bin #(
    parameter int W = 4
) (
    input  logic [W-1:0] gray,
    output logic [W-1:0] bin
);
    integer i;

    always_comb begin
        // MSB is the same
        bin[W-1] = gray[W-1];

        // Reconstruct remaining bits
        for (i = W-2; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
    end
endmodule

