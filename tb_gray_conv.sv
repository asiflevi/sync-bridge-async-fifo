`timescale 1ns/1ps

module tb_gray_conv;

    // ---- Parameters ----
    localparam int W = 5;              // pointer width to test
    localparam int NUM_TESTS = 1 << W; // test all possible values

    // ---- DUT signals ----
    logic [W-1:0] bin;
    logic [W-1:0] gray;
    logic [W-1:0] bin_back;

    // ---- Instantiate DUTs ----
    bin2gray #(.W(W)) u_bin2gray (
        .bin (bin),
        .gray(gray)
    );

    gray2bin #(.W(W)) u_gray2bin (
        .gray(gray),
        .bin (bin_back)
    );

    // ---- Helper: count set bits (popcount) ----
    function automatic int popcount(input logic [W-1:0] v);
        int c;
        c = 0;
        for (int i = 0; i < W; i++) c += v[i];
        return c;
    endfunction

    // ---- Main test ----
    initial begin
        logic [W-1:0] gray_prev;
        int errors;

        errors = 0;
        gray_prev = '0;

        $display("==== Gray converter TB start (W=%0d) ====", W);

        // Test all binary values
        for (int i = 0; i < NUM_TESTS; i++) begin
            bin = logic'(i[W-1:0]);
            #1; // allow combinational propagation

            // 1) Round-trip check: bin -> gray -> bin
            if (bin_back !== bin) begin
                $error("Round-trip FAILED: bin=%0d (0x%0h) gray=0x%0h bin_back=%0d (0x%0h)",
                       i, bin, gray, bin_back, bin_back);
                errors++;
            end

            // 2) Gray adjacency property: consecutive codes differ by exactly 1 bit
            // Skip i=0 (no previous)
            if (i > 0) begin
                logic [W-1:0] diff;
                diff = gray ^ gray_prev;
                if (popcount(diff) != 1) begin
                    $error("Adjacency FAILED: i=%0d gray_prev=0x%0h gray=0x%0h diff=0x%0h popcount(diff)=%0d",
                           i, gray_prev, gray, diff, popcount(diff));
                    errors++;
                end
            end

            gray_prev = gray;
        end

        if (errors == 0) begin
            $display("==== PASS: All tests passed (W=%0d) ====", W);
        end else begin
            $display("==== FAIL: %0d errors (W=%0d) ====", errors, W);
        end

        $finish;
    end

endmodule

