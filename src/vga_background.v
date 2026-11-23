
`default_nettype none

/*
 * This code serves as an example that illustrates usage of the VGA output
 * in the DE1-SoC board. The code uses a VGA adapter to send pixel colors
 * to the VGA display.
 *
 * Press KEY[0] to reset the circuit.
 * It displays the kitchen background with the chef drawn on top.
 */

module vga_background(
    CLOCK_50, KEY, LEDR, VGA_R, VGA_G, VGA_B,
    VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
    player_x, player_y, order_id, required_ingredients,
    heat_level
);

    parameter RESOLUTION = "320x240"; // "640x480" "320x240" "160x120"
    parameter COLOR_DEPTH = 6; // 9 6 3

    // Specify the number of bits needed for an X (column) pixel coordinate
    // Chooses bit size based on chosen resolution
    parameter nX = (RESOLUTION == "640x480") ? 10 :
                   ((RESOLUTION == "320x240") ? 9 : 8);

    // Specify the number of bits needed for a Y (row) pixel coordinate
    parameter nY = (RESOLUTION == "640x480") ? 9 :
                   ((RESOLUTION == "320x240") ? 8 : 7);

    input wire CLOCK_50;
    input wire [3:0] KEY;

    // Chef position provided by the game
    // Chef coordinates provided by movement logic
    // Gets passed into sprite renderer
    input wire [8:0] player_x;
    input wire [7:0] player_y;

    // NEW: Milestone 2 - Current burger recipe
    input wire [1:0] order_id;
    input wire [2:0] required_ingredients;

    // NEW: Milestone 2 - Heat level for the heat bar graphic
    input wire [5:0] heat_level;

    output wire [9:0] LEDR;

    output wire [7:0] VGA_R;
    output wire [7:0] VGA_G;
    output wire [7:0] VGA_B;

    output wire VGA_HS; // tells monitor when new horizontal line begins
    output wire VGA_VS; // new vertical line begins
    output wire VGA_BLANK_N; // indicates when video output is enabled
    output wire VGA_SYNC_N; // sync related outputs
    output wire VGA_CLK; // pixel clock 25 MHz

    // The four signals below are used in demos that actively draw pixels
    // on top of the background MIF.
    //
    // In our game, the chef, order display, and heat bar draw pixels.
    // We select which renderer sends pixels to the VGA adapter.

    wire [COLOR_DEPTH-1:0] color; // 6-bit color of pixel to write
    wire [nX-1:0] X; // x coordinate
    wire [nY-1:0] Y; // y coordinate
    wire write; // write pixel into VGA memory; 0 means no

    // Display the color depth
    // Selects binary value displayed on first four LEDs
    assign LEDR[3:0] = (COLOR_DEPTH == 9) ? 4'b1001 :
                       ((COLOR_DEPTH == 6) ? 4'b0110 : 4'b0011);

    assign LEDR[9:4] = 6'b000000;

    // NEW: Milestone 2
    // Each renderer has its own pixel information

    // Chef renderer signals
    wire [8:0] chef_x;
    wire [7:0] chef_y;
    wire [5:0] chef_color;
    wire chef_write;
    wire chef_busy;

    // Order display signals
    wire [8:0] order_x;
    wire [7:0] order_y;
    wire [5:0] order_color;
    wire order_write;
    wire order_enable;

    // NEW: Milestone 2 - Heat bar signals
    wire [8:0] heat_x;
    wire [7:0] heat_y;
    wire [5:0] heat_color;
    wire heat_write;
    wire heat_enable;

    // Draw the chef on top of the kitchen background
    sprite_renderer chef_renderer (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),
        .player_x(player_x),
        .player_y(player_y),
        .VGA_x(chef_x),
        .VGA_y(chef_y),
        .VGA_color(chef_color),
        .VGA_write(chef_write),

        // NEW: Milestone 2
        .busy(chef_busy)
    );

    // NEW: Milestone 2
    // The chef renderer gets priority over the order display
    // The order display pauses while the chef is drawing or clearing
    assign order_enable = !chef_busy && !chef_write;

    // NEW: Milestone 2
    // Draw three coloured boxes representing the current burger order
    order_display order_graphics (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),
        .enable(order_enable),
        .order_id(order_id),
        .required_ingredients(required_ingredients),
        .VGA_x(order_x),
        .VGA_y(order_y),
        .VGA_color(order_color),
        .VGA_write(order_write)
    );

    // NEW: Milestone 2 - Heat bar graphics
    // Wait until the chef and order renderers are not writing
    assign heat_enable = !chef_busy && !chef_write && !order_write;

    heat_bar heat_graphics (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),
        .heat_level(heat_level),
        .chef_busy(chef_busy),
        .enable(heat_enable),
        .VGA_x(heat_x),
        .VGA_y(heat_y),
        .VGA_color(heat_color),
        .VGA_write(heat_write)
    );

    // NEW: Milestone 2
    // Select which renderer controls the VGA adapter inputs
    //
    // The chef has highest priority.
    // The order display has second priority.
    // The heat bar uses VGA when both are not writing.
    //
    // Only one pixel can be written per clock cycle.

    assign X = chef_write ? chef_x :
               order_write ? order_x : heat_x;

    assign Y = chef_write ? chef_y :
               order_write ? order_y : heat_y;

    assign color = chef_write ? chef_color :
                   order_write ? order_color : heat_color;

    assign write = chef_write || order_write || heat_write;

    // Instantiate the VGA adapter
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(color),
        .x(X),
        .y(Y),
        .write(write),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    defparam VGA.RESOLUTION = RESOLUTION; // 320x240
    defparam VGA.BACKGROUND_IMAGE = "assets/kitchen_background.mif"; // which .mif file has the image
    defparam VGA.COLOR_DEPTH = COLOR_DEPTH; // six bits per pixel

endmodule

`default_nettype wire
