`timescale 1ns / 1ps

// Testbench for ctrlinput (input_ctrl.v)
// gametick is driven directly (every 4 clocks).
// space should pulse once per key press, lined up with a gametick,
// and never while timeup is high.

module input_ctrl_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to ctrlinput
    reg CLOCK_50;
    reg resetn;
    reg interact;
    reg gametick;
    reg timeup;

    // Outputs from ctrlinput
    wire space;

    // Generate the 50 MHz FPGA clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // gametick: one clock high every 4 clocks
    integer count = 0;
    always @(posedge CLOCK_50) begin
        count = count + 1;
        gametick <= (count % 4 == 0);
    end

    // Wait for n gameticks
    task wait_ticks(input integer n);
        begin
            repeat (n * 4) @(posedge CLOCK_50);
        end
    endtask

    initial begin

        // Reset
        resetn = 1'b0;
        gametick = 1'b0;
        interact = 1'b0;
        timeup = 1'b0;
        #100;
        resetn = 1'b1;
        wait_ticks(2);
        // expect space 0

        // Short tap between gameticks: space waits for the next gametick
        @(posedge CLOCK_50);
        interact <= 1'b1;
        @(posedge CLOCK_50);
        interact <= 1'b0;
        wait_ticks(3);
        // expect one space pulse, on the next gametick

        // Hold the key for many gameticks: still only one space pulse
        interact <= 1'b1;
        wait_ticks(10);
        interact <= 1'b0;
        wait_ticks(2);
        // expect only one space pulse for the whole hold

        // Two separate taps: two pulses
        interact <= 1'b1;
        wait_ticks(2);
        interact <= 1'b0;
        wait_ticks(2);
        interact <= 1'b1;
        wait_ticks(2);
        interact <= 1'b0;
        wait_ticks(2);
        // expect two space pulses, one per tap

        // Time is up: key presses are ignored
        timeup = 1'b1;
        interact <= 1'b1;
        wait_ticks(3);
        interact <= 1'b0;
        wait_ticks(3);
        // expect no space pulse

        // Press held across the end of timeup: no late pulse
        interact <= 1'b1;
        wait_ticks(2);
        timeup = 1'b0;
        wait_ticks(3);
        interact <= 1'b0;
        wait_ticks(2);
        // expect no space pulse (key was already down)

        // Press during reset: nothing comes out after reset
        resetn = 1'b0;
        interact <= 1'b1;
        @(posedge CLOCK_50);
        interact <= 1'b0;
        @(posedge CLOCK_50);
        resetn = 1'b1;
        wait_ticks(3);
        // expect no space pulse

        $stop;
    end

    ctrlinput DUT (
        .clk(CLOCK_50),
        .resetn(resetn),
        .interact(interact),
        .gametick(gametick),
        .timeup(timeup),
        .space(space)
    );

endmodule
