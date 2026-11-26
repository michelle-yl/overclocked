`timescale 1ns / 1ps

// Testbench for trackheat (heat_tracking.v)
// tick1s is driven directly, one pulse per "second".
// Heat rises 4 per second while overclocked, falls 2 per second otherwise.
// warning when heat >= 24, meltdown pulses when heat hits 31.

module heat_tracking_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to trackheat
    reg CLOCK_50;
    reg resetn;
    reg tick1s;
    reg key;
    reg inplay;

    // Outputs from trackheat
    wire overclk;
    wire [4:0] heat;
    wire warning;
    wire meltdown;

    // Generate the 50 MHz FPGA clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // One "second": tick1s high for one clock, then wait a clock
    // so the new value is visible before it is printed
    task one_second;
        begin
            @(posedge CLOCK_50) tick1s <= 1'b1;
            @(posedge CLOCK_50) tick1s <= 1'b0;
            @(posedge CLOCK_50);
        end
    endtask

    task seconds(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                one_second;
        end
    endtask

    initial begin

        // Reset
        resetn = 1'b0;
        tick1s = 1'b0;
        key = 1'b0;
        inplay = 1'b0;
        #100;
        resetn = 1'b1;
        @(posedge CLOCK_50);
        // expect heat 0, overclk 0

        // Not in play: key does nothing
        key = 1'b1;
        seconds(3);
        // expect overclk 0, heat 0
        key = 1'b0;

        // Game starts, key not held: heat stays at 0 (no underflow)
        inplay = 1'b1;
        seconds(2);
        // expect heat 0

        // Hold overclock for 3 seconds
        key = 1'b1;
        seconds(3);
        // expect overclk 1, heat 12

        // Release for 2 seconds
        key = 1'b0;
        seconds(2);
        // expect overclk 0, heat 8

        // Hold again until warning
        key = 1'b1;
        seconds(4);
        // expect heat 24, warning 1

        // Keep holding: 28, then meltdown
        seconds(1);
        // expect heat 28, warning 1
        seconds(1);
        // expect heat 31, meltdown pulse, overclk drops to 0

        // Still holding after meltdown: heat cools to 29, then since
        // heat != 31 overclock turns back on and melts down again
        seconds(2);
        // expect heat 29, overclk back to 1, then heat 31 + second meltdown pulse

        // Let go and cool all the way down (31 -> 1 in 15 s, then 0)
        key = 1'b0;
        seconds(16);
        // expect heat 0, warning off below 24

        // Game ends while overclocked: heat freezes
        key = 1'b1;
        seconds(2);
        // expect heat 8
        inplay = 1'b0;
        seconds(3);
        // expect overclk 0, heat still 8
        key = 1'b0;

        // Reset clears heat
        resetn = 1'b0;
        @(posedge CLOCK_50);
        resetn = 1'b1;
        @(posedge CLOCK_50);
        // expect heat 0

        $stop;
    end

    trackheat DUT (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick1s(tick1s),
        .key(key),
        .inplay(inplay),
        .overclk(overclk),
        .heat(heat),
        .warning(warning),
        .meltdown(meltdown)
    );

endmodule
