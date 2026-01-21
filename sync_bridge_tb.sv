`timescale 1ns/1ns

// Testbench for sync_bridge
// Goal:
//  1) Generate two unrelated clocks (clka=80MHz, clkb=50MHz)
//  2) In domain B: assert a request pulse (data_req_clkb) to trigger a transfer
//  3) In domain A: when request arrives (data_req_clka), drive a burst of data words
//  4) Monitor: collect written data into a queue on clka
//  5) Checker: whenever data_valid_clkb asserts on clkb, compare dout_clkb to the expected queue front
module sync_bridge_tb();

    // -------------------------
    // DUT interface signals
    // -------------------------
    logic        clka;
    logic        clkb;
    logic        resetb_clkb;

    logic [7:0]  din_clka;

    logic        data_req_clkb;     // request generated in clock domain B
    logic        data_req_clka;     // request seen in clock domain A (after sync inside DUT)

    logic        data_valid_clka;   // "write valid" in domain A (we drive it)
    logic        data_valid_clkb;   // "read valid" in domain B (DUT outputs it)

    logic [7:0]  dout_clkb;

    // -------------------------
    // Scoreboard storage
    // queue1 stores the expected stream of bytes written in domain A.
    // Whenever DUT claims valid output in domain B, we pop from the queue and compare.
    // -------------------------
    integer queue1[$];
    integer cur_poppped;

    // -------------------------
    // Instantiate DUT
    // -------------------------
    sync_bridge sync_bridge_inst(
        .clka           (clka),
        .clkb           (clkb),
        .resetb_clkb    (resetb_clkb),
        .data_req_clka  (data_req_clka),
        .data_req_clkb  (data_req_clkb),
        .data_valid_clka(data_valid_clka),
        .din_clka       (din_clka),
        .data_valid_clkb(data_valid_clkb),
        .dout_clkb      (dout_clkb)
    );

    // -------------------------
    // Clock generation
    // clka period = 12.5ns  (80 MHz)
    // clkb period = 20ns    (50 MHz)
    // -------------------------
    always #6.25ns clka = ~clka;
    always #10ns   clkb = ~clkb;

    // -------------------------
    // Convenience "sync" tasks:
    // These tasks block until the next rising edge of each clock.
    // Useful to make the stimulus timing very explicit.
    // -------------------------
    task automatic sync_b();
        @(posedge clkb);
        // optional small delay if you want sampling away from edge:
        // #1ns;
    endtask

    task automatic sync_a();
        @(posedge clka);
        // optional small delay if you want sampling away from edge:
        // #1ns;
    endtask

    // -------------------------
    // Domain A stimulus:
    // We drive incrementing bytes on din_clka whenever we decide "data_valid_clka=1".
    // -------------------------
    initial din_clka = 8'd0;

    // Increment din_clka modulo 256
    function void counter_inputs();
        if (din_clka == 8'd255)
            din_clka = 8'd0;
        else
            din_clka = din_clka + 8'd1;
    endfunction

    // Drive one data beat in domain A:
    // - on a clka edge, update din_clka
    // - assert data_valid_clka for this beat
    // NOTE: As written, data_valid_clka stays 1 until you later deassert it in the main sequence.
    task automatic driver_a();
        @(posedge clka);
            counter_inputs();
            data_valid_clka = 1'b1;
    endtask

    // -------------------------
    // Domain B stimulus:
    // - release reset
    // - issue a single-cycle request pulse (data_req_clkb) in domain B
    // -------------------------
    task automatic driver_b();
        // bring resetb high (release reset) aligned to clkb
        sync_b();
        resetb_clkb = 1'b1;

        // wait a bit before asserting request (gives DUT time to settle)
        #20ns;

        // assert request for exactly 1 clkb cycle
        sync_b();
        data_req_clkb = 1'b1;

        sync_b();
        data_req_clkb = 1'b0;
    endtask

    // -------------------------
    // MONITOR (Domain A):
    // On each clka rising edge, if data_valid_clka is 1,
    // push din_clka into the expected queue.
    //
    // #1ns delay: sample after din_clka is updated inside driver_a() at posedge
    // (this avoids race/ordering issues between monitor and driver).
    // -------------------------
    initial forever begin
        @(posedge clka);
        #1ns;
        if (data_valid_clka == 1'b1)
            queue1.push_back(din_clka);
    end

    // -------------------------
    // MONITOR + CHECKER (Domain B):
    // On each clkb rising edge, if DUT asserts data_valid_clkb,
    // compare dout_clkb to next expected value from queue1.
    //
    // #1ns delay: sample after DUT updates dout_clkb/data_valid_clkb.
    // -------------------------
    initial forever begin
        @(posedge clkb);
        #1ns;
        if (data_valid_clkb == 1'b1)
            my_chekcer();
    end

    // -------------------------
    // CHECKER:
    // Pop the next expected data from queue1 and compare to dut output.
    // -------------------------
    function void my_chekcer();
        cur_poppped = queue1.pop_front();
        if (cur_poppped != dout_clkb)
            $display("FAIL! expected=%0d   got=%0d)",cur_poppped, dout_clkb);
        else
            $display("PASS: expected == got (%0d)", dout_clkb);
    endfunction

    // -------------------------
    // Main test sequence
    // We run two bursts:
    //  1) pulse request in B, wait for request to show up in A, then drive ~21 beats in A
    //  2) wait, then do it again
    // -------------------------
    initial begin
        // initialize EVERYTHING to known state
        {clka, clkb, resetb_clkb,
         data_req_clka, data_req_clkb,
         data_valid_clka, data_valid_clkb,
         din_clka, dout_clkb, cur_poppped} = '0;

        // small time before starting stimulus (clocks already toggling)
        #10ns;

        // -------- Burst #1 --------
        driver_b();

        // Wait until the request has propagated into domain A (data_req_clka asserted by DUT)
        wait (data_req_clka);

        // Drive a burst of data beats in domain A
        repeat (21)
            driver_a();

        // Stop driving data (idle)
        din_clka        = 8'd0;
        data_valid_clka = 1'b0;

        // allow enough time for data to drain through DUT
        #1000ns;

        // -------- Burst #2 --------
        driver_b();
        wait (data_req_clka);

        repeat (21)
            driver_a();

        din_clka        = 8'd0;
        data_valid_clka = 1'b0;

        #1000ns;

        $stop;
    end

endmodule
