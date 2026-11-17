
`timescale 1ns / 1ps

module keyboard_input_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to the keyboard module
    reg CLOCK_50;
    reg resetn;
    reg PS2_CLK;
    reg PS2_DAT;

    // Outputs from the keyboard module
    wire move_up;
    wire move_down;
    wire move_left;
    wire move_right;
    wire interact;
    wire overclock;

    // Generate the 50 MHz FPGA clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // Simulate pressing the W key
    initial begin

        // Reset the keyboard module
        resetn = 1'b0;
        PS2_CLK = 1'b1;
        PS2_DAT = 1'b1;

        #100;
        resetn = 1'b1;

        // W has scan code 1D
        // PS/2 sends 11 bits:
        // Start, 8 data bits, parity, stop

        // Start bit: 0
        #100;
        PS2_DAT = 1'b0;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 0: 1
        #2000;
        PS2_DAT = 1'b1;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 1: 0
        #2000;
        PS2_DAT = 1'b0;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 2: 1
        #2000;
        PS2_DAT = 1'b1;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 3: 1
        #2000;
        PS2_DAT = 1'b1;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 4: 1
        #2000;
        PS2_DAT = 1'b1;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 5: 0
        #2000;
        PS2_DAT = 1'b0;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 6: 0
        #2000;
        PS2_DAT = 1'b0;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Data bit 7: 0
        #2000;
        PS2_DAT = 1'b0;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Odd parity bit: 1
        #2000;
        PS2_DAT = 1'b1;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Stop bit: 1
        #2000;
        PS2_DAT = 1'b1;
        #2000;
        PS2_CLK = 1'b0;
        #2000;
        PS2_CLK = 1'b1;

        // Keyboard returns to idle
        #2000;
        PS2_DAT = 1'b1;

        // Leave time to observe move_up in ModelSim
        #10000;

        // Reset again to check that move_up clears
        resetn = 1'b0;
        #200;
        resetn = 1'b1;

        #10000;

        $stop;

    end

    // Instantiate the keyboard module
    keyboard_input U1 (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .move_up(move_up),
        .move_down(move_down),
        .move_left(move_left),
        .move_right(move_right),
        .interact(interact),
        .overclock(overclock)
    );

endmodule
