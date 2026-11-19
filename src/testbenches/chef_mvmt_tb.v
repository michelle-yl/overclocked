
`timescale 1ns / 1ps

// Testbench for movechef (chef_mvmt.v)
// gametick is driven directly (every 4 clocks) so the test runs quickly.
// Each step is 8 gameticks x 2 px = 16 px = one tile.

module chef_mvmt_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to movechef
    reg CLOCK_50;
    reg resetn;
    reg gametick;
    reg up, down, left, right;

    // Outputs from movechef
    wire [8:0] chefx;
    wire [7:0] chefy;
    wire [4:0] tilex;
    wire [3:0] tiley;

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

    // Print the chef's position
    task show(input [8*40:1] label);
        begin
            $display("%0s: pixel (%0d, %0d), tile (%0d, %0d), state = %b",
                     label, chefx, chefy, tilex, tiley, DUT.state);
        end
    endtask

    initial begin

        // Reset
        resetn = 1'b0;
        gametick = 1'b0;
        up = 0; down = 0; left = 0; right = 0;
        #100;
        resetn = 1'b1;
        wait_ticks(1);
        show("1. After reset (expect tile 2,5)");

        // Tap right and release early: the step still finishes
        right = 1;
        wait_ticks(3);
        right = 0;
        wait_ticks(8);
        show("2. Tap right (expect tile 3,5)");

        // Hold up: moves one tile, then the crate row blocks it
        up = 1;
        wait_ticks(20);
        up = 0;
        show("3. Hold up (expect tile 3,4)");

        // Up again: blocked by the counter row
        up = 1;
        wait_ticks(10);
        up = 0;
        show("4. Up again (expect still 3,4)");

        // Up and right together: up has priority, and up is blocked
        up = 1; right = 1;
        wait_ticks(10);
        up = 0; right = 0;
        show("5. Up + right (expect still 3,4)");

        // Walk down 2 and right 3 to tile (6,6), next to the assembly counter
        down = 1;
        wait_ticks(18);
        down = 0;
        wait_ticks(2);
        right = 1;
        wait_ticks(27);
        right = 0;
        wait_ticks(2);
        show("6. Down 2, right 3 (expect tile 6,6)");

        // Down into the assembly counter at row 7: blocked
        down = 1;
        wait_ticks(10);
        down = 0;
        show("7. Down into counter (expect still 6,6)");

        $stop;
    end

    movechef DUT (
        .clk(CLOCK_50),
        .clr(resetn),
        .gametick(gametick),
        .up(up),
        .down(down),
        .left(left),
        .right(right),
        .chefx(chefx),
        .chefy(chefy),
        .tilex(tilex),
        .tiley(tiley)
    );

endmodule
