
`timescale 1ns / 1ps

// Testbench for tickgen (tick.v)
// The limits are shrunk so the test runs quickly:
//   60 Hz tick  -> every 6 clocks (limit 5)
//   90 Hz tick  -> every 4 clocks (limit 3)
//   1 s tick    -> every 10 clocks (limit 9)

module tick_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to tickgen
    reg CLOCK_50;
    reg resetn;
    reg overclk;

    // Outputs from tickgen
    wire gametick;
    wire tick1s;

    // Generate the 50 MHz FPGA clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // Count clocks between ticks and print each gap
    integer clocks = 0;
    integer last_game = 0;
    integer last_sec = 0;

    always @(posedge CLOCK_50) begin
        clocks = clocks + 1;

        if (gametick) begin
            $display("gametick at clock %0d, gap = %0d clocks, boost = %b",
                     clocks, clocks - last_game, DUT.boost);
            last_game = clocks;
        end

        if (tick1s) begin
            $display("  tick1s at clock %0d, gap = %0d clocks", clocks, clocks - last_sec);
            last_sec = clocks;
        end
    end

    initial begin

        // Reset
        resetn = 1'b0;
        overclk = 1'b0;
        #100;
        resetn = 1'b1;

        // Normal speed: gametick every 6 clocks
        $display("--- Normal speed (expect gap 6) ---");
        #(CLOCK_PERIOD * 20);

        // Press overclock in the middle of a count:
        // the current count finishes at 6, then gaps become 4
        $display("--- Overclock on (expect one more 6, then 4) ---");
        #(CLOCK_PERIOD * 3);
        overclk = 1'b1;
        #(CLOCK_PERIOD * 20);

        // Release overclock: back to 6
        $display("--- Overclock off (expect one more 4, then 6) ---");
        overclk = 1'b0;
        #(CLOCK_PERIOD * 20);

        // Reset while boosting: should restart at normal speed
        $display("--- Reset during boost (expect gap 6 after reset) ---");
        overclk = 1'b1;
        #(CLOCK_PERIOD * 5);
        resetn = 1'b0;
        #(CLOCK_PERIOD * 2);
        resetn = 1'b1;
        overclk = 1'b0;
        #(CLOCK_PERIOD * 20);

        $stop;
    end

    // tick1s must keep a gap of 10 the whole time, even while boosting
    tickgen #(.TICK60HZ(20'd5), .TICK90HZ(20'd3), .TICK1S(26'd9)) DUT (
        .clk(CLOCK_50),
        .clr(resetn),
        .overclk(overclk),
        .gametick(gametick),
        .tick1s(tick1s)
    );

endmodule
