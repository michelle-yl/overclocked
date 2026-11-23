
`timescale 1ns / 1ps

module sprite_renderer_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to the sprite renderer
    reg CLOCK_50;
    reg resetn;
    reg [8:0] player_x;
    reg [7:0] player_y;

    // Outputs sent to the VGA adapter
    wire [8:0] VGA_x;
    wire [7:0] VGA_y;
    wire [5:0] VGA_color;
    wire VGA_write;

    // Generate the 50 MHz clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // Test the different drawing stages
    initial begin

        // Reset the renderer and set the starting position
        resetn = 1'b0;
        player_x = 9'd32; //x = 32
        player_y = 8'd80; //y = 80

        #100;
        resetn = 1'b1; //releases reset 

        // TEST 1: Initial chef drawing
        // Allow time to draw
        // and draw the chef at (32, 80)
        #2000000; 

        // TEST 2: Change chef position
        // The renderer should erase the old chef
        // and draw the chef at (64, 80)
        player_x = 9'd64; //moving chef to these coordinates
        player_y = 8'd80;

        #1000000;

        // TEST 3: Reset again
        // The renderer should rebuild the kitchen
        // and draw one chef at the starting position
        resetn = 1'b0;
        player_x = 9'd32;
        player_y = 8'd80;

        #100;
        resetn = 1'b1;

        // Allow the full rebuild and drawing to finish
        #2000000;

        $stop;

    end

    // Instantiate our sprite renderer
    sprite_renderer U1 (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .player_x(player_x),
        .player_y(player_y),
        .VGA_x(VGA_x),
        .VGA_y(VGA_y),
        .VGA_color(VGA_color),
        .VGA_write(VGA_write)
    );

endmodule
