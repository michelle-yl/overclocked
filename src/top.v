
module top (CLOCK_50, SW, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
            VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
            PS2_CLK, PS2_DAT);

    // ---------------- Ports ----------------
    input wire CLOCK_50;        // DE-series 50 MHz clock signal
    input wire [9:0] SW;        // DE-series switches
    input wire [3:0] KEY;       // DE-series pushbuttons, KEY[0] = reset (active low)

    input wire PS2_CLK;         // PS/2 keyboard
    input wire PS2_DAT;

    output wire [6:0] HEX0;     // DE-series HEX displays
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;

    output wire [9:0] LEDR;     // DE-series LEDs

    output wire [7:0] VGA_R;    // VGA output
    output wire [7:0] VGA_G;
    output wire [7:0] VGA_B;
    output wire VGA_HS;
    output wire VGA_VS;
    output wire VGA_BLANK_N;
    output wire VGA_SYNC_N;
    output wire VGA_CLK;

    // ---------------- Internal signals ----------------
    // Keyboard to game
    wire move_up, move_down, move_left, move_right;
    wire interact;
    wire overclock;

    // Timing pulses
    wire gametick;              // 60 Hz, or 90 Hz while overclocking
    wire tick1s;                // 1 Hz, for the game timer

    // Chef position
    wire [8:0] chefx;           // pixel x, 0-319
    wire [7:0] chefy;           // pixel y, 0-239
    wire [4:0] tilex;           // tile column, 0-19
    wire [3:0] tiley;           // tile row, 0-14

    // Game timer digits (BCD)
    wire [3:0] t_min, t_tens, t_ones;
    wire timeup;                // 1 at 0:00

    // ---------------- Reset ----------------
    // Registers start at 0 when the board is programmed, so startup_count
    // holds the design in reset for 15 clocks to load the real start values.
    // After that, KEY[0] resets everything (active low).
    reg [3:0] startup_count = 4'd0;
    always @(posedge CLOCK_50)
        if (startup_count != 4'd15)
            startup_count <= startup_count + 1'b1;

    wire resetn = KEY[0] & (startup_count == 4'd15);

    // ---------------- Modules ----------------
    // Read keyboard input and track which keys are held down
    keyboard_input keyboard (
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

    // Game tick (60/90 Hz) and 1 second tick
    tickgen ticks (
        .clk(CLOCK_50),
        .clr(resetn),
        .overclk(overclock),
        .gametick(gametick),
        .tick1s(tick1s)
    );

    // Chef movement on the 16 px tile grid
    movechef chef (
        .clk(CLOCK_50),
        .clr(resetn),
        .gametick(gametick),
        .up(move_up),
        .down(move_down),
        .left(move_left),
        .right(move_right),
        .chefx(chefx),
        .chefy(chefy),
        .tilex(tilex),
        .tiley(tiley)
    );

    // 2:00 countdown game timer
    timer gtimer (
        .clk(CLOCK_50),
        .clr(resetn),
        .tick1s(tick1s),
        .min(t_min),
        .tens(t_tens),
        .ones(t_ones),
        .timeup(timeup)
    );

    // Kitchen background with the chef drawn on top
    vga_background background (
        .CLOCK_50(CLOCK_50),
        .KEY({KEY[3:1], resetn}),
        .LEDR(),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),
        .player_x(chefx),
        .player_y(chefy)
    );

    // ---------------- HEX displays ----------------
    // HEX5-3: game time, m ss
    hex7seg hx5 (.in(t_min),  .out(HEX5));
    hex7seg hx4 (.in(t_tens), .out(HEX4));
    hex7seg hx3 (.in(t_ones), .out(HEX3));

    // HEX2: chef tile y (hex), HEX1-0: chef tile x (hex), for debugging
    hex7seg hx2 (.in(tiley),              .out(HEX2));
    hex7seg hx1 (.in({3'b000, tilex[4]}), .out(HEX1));
    hex7seg hx0 (.in(tilex[3:0]),         .out(HEX0));

    // ---------------- LEDs ----------------
    // LEDR[5:0]: which keys are held, LEDR[9]: time is up
    assign LEDR[0] = move_up;
    assign LEDR[1] = move_down;
    assign LEDR[2] = move_left;
    assign LEDR[3] = move_right;
    assign LEDR[4] = interact;
    assign LEDR[5] = overclock;
    assign LEDR[8:6] = 3'b000;
    assign LEDR[9] = timeup;

endmodule
