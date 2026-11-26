`timescale 1ns / 1ps

// Testbench for stove (stove.v)
// TICKS is shrunk to 2 so the test runs quickly:
//   progress goes up every 2 gameticks
//   cooked after 16 x 2 = 32 gameticks, burnt after 32 more
// gametick is driven directly (every 4 clocks).
// State: EMPTY 0, COOKING 1, COOKED 2, BURNT 3
// Held:  EMPTY 0, RAW 3, COOKED 4, BURNT 5

module stove_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to stove
    reg CLOCK_50;
    reg resetn;
    reg gametick;
    reg space;
    reg [2:0] held;

    // Outputs from stove
    wire [1:0] state;
    wire [3:0] progress;
    wire [2:0] give;

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

    // Press space once (one clock pulse)
    task press;
        begin
            @(posedge CLOCK_50) space <= 1'b1;
            @(posedge CLOCK_50) space <= 1'b0;
            @(posedge CLOCK_50);
        end
    endtask

    initial begin

        // Reset
        resetn = 1'b0;
        gametick = 1'b0;
        space = 1'b0;
        held = 3'd0;
        #100;
        resetn = 1'b1;
        wait_ticks(1);
        // expect state 0, progress 0, give 0

        // Empty hands at an empty stove: nothing to take
        press;
        // expect still state 0

        // Holding a bun: stove ignores it, give passes the bun back
        held = 3'd1;
        press;
        // expect state 0, give 1

        // Place a raw patty: give shows EMPTY (hands get emptied)
        held = 3'd3;
        #1;
        // expect give 0 before the press
        press;
        held = 3'd0;    // interactions.v would now empty the hands
        // expect state 1 (cooking), progress 0

        // Halfway: progress about 8
        wait_ticks(16);
        // expect state 1, progress ~8

        // Finish cooking
        wait_ticks(17);
        // expect state 2 (cooked), progress back to 0
        // give shows 4 (cooked) because hands are empty

        // Take the cooked patty
        press;
        // expect state 0, progress 0

        // Cook again, but leave it too long
        held = 3'd3;
        press;
        held = 3'd0;
        wait_ticks(33);
        // expect state 2 (cooked)
        wait_ticks(33);
        // expect state 3 (burnt), give 5

        // Burnt stays burnt, progress no longer moves
        wait_ticks(10);
        // expect still state 3, progress 0

        // Can't put a raw patty on top of a burnt one
        held = 3'd3;
        press;
        // expect still state 3, give 3 (raw stays in hand)

        // Take the burnt patty
        held = 3'd0;
        press;
        // expect state 0

        // Reset in the middle of cooking
        held = 3'd3;
        press;
        held = 3'd0;
        wait_ticks(10);
        resetn = 1'b0;
        @(posedge CLOCK_50);
        resetn = 1'b1;
        wait_ticks(1);
        // expect state 0, progress 0

        $stop;
    end

    stove #(.TICKS(2)) DUT (
        .clk(CLOCK_50),
        .resetn(resetn),
        .gametick(gametick),
        .space(space),
        .held(held),
        .state(state),
        .progress(progress),
        .give(give)
    );

endmodule
