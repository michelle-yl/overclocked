
module top (CLOCK_50, SW, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
            VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
            PS2_CLK, PS2_DAT);

    input CLOCK_50;             // DE-series 50 MHz clock signal
    input wire [9:0] SW;        // DE-series switches
    input wire [3:0] KEY;       // DE-series pushbuttons
       
    // PS/2 keyboard connections
    input wire PS2_CLK;
    input wire PS2_DAT;

    // Signals sent from the keyboard module to the game
    wire move_up;
    wire move_down;
    wire move_left;
    wire move_right;
    wire interact;
    wire overclock;

    output wire [6:0] HEX0;     // DE-series HEX displays
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;

    output wire [9:0] LEDR;     // DE-series LEDs   

    output wire [7:0] VGA_R;
    output wire [7:0] VGA_G;
    output wire [7:0] VGA_B;
    output wire VGA_HS;
    output wire VGA_VS;
    output wire VGA_BLANK_N;
    output wire VGA_SYNC_N;
    output wire VGA_CLK;

        vga_background background (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .LEDR(),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
        .player_x(9'd100),  // Temporary chef position for testing
        .player_y(8'd100), // Michelle's movement coordinates will replace these later
    );
    // Read keyboard input and track which keys are held down
    keyboard_input keyboard (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),
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

