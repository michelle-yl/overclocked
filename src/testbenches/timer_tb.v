
`timescale 1ns / 1ps

// Testbench for timer (timer.v)
// tick1s is driven directly, one pulse per "second", so the full
// 2 minute countdown takes only a few microseconds.

module timer_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to timer
    reg CLOCK_50;
    reg resetn;
    reg tick1s;

    // Outputs from timer
    wire [3:0] min, tens, ones;
    wire timeup;

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
        #100;
        resetn = 1'b1;
        @(posedge CLOCK_50);
        // Check: Start      (expect 2:00)
        seconds(1);
        // Check: After 1 s  (expect 1:59)
        seconds(9);
        // Check: After 10 s (expect 1:50)
        seconds(50);
        // Check: After 60 s (expect 1:00)
        seconds(1);
        // Check: After 61 s (expect 0:59)
        seconds(58);
        // Check: After 119 s (expect 0:01)
        seconds(1);
        // Check: After 120 s (expect 0:00, timeup 1)
        seconds(5);
        // Check: After 125 s (expect still 0:00)
        // Reset goes back to 2:00
        resetn = 1'b0;
        @(posedge CLOCK_50);
        resetn = 1'b1;
        @(posedge CLOCK_50);
        // Check: After reset (expect 2:00)
        $stop;
    end

    timer DUT (
        .clk(CLOCK_50),
        .clr(resetn),
        .tick1s(tick1s),
        .min(min),
        .tens(tens),
        .ones(ones),
        .timeup(timeup)
    );

endmodule
