
`timescale 1ns / 1ps

module vga_background_tb();

    parameter CLOCK_PERIOD = 20;

    // Inputs to the VGA background module
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [8:0] player_x;
    reg [7:0] player_y;

    // Outputs from the VGA adapter
    wire [9:0] LEDR;
    wire [7:0] VGA_R, VGA_G, VGA_B;
    wire VGA_HS, VGA_VS;
    wire VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

    // Generate a 50 MHz clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // Test reset and chef movement
    initial begin

        // Reset the VGA module
        KEY = 4'b1110;
        player_x = 9'd32;
        player_y = 8'd80;

        #100;
        KEY = 4'b1111;

        // Let the VGA controller run
        #2000000;

        // Move the chef to a different location
        player_x = 9'd64;
        player_y = 8'd80;

        #1000000;

        // Reset the system again
        KEY = 4'b1110;
        player_x = 9'd32;
        player_y = 8'd80;

        #100;
        KEY = 4'b1111;

        #2000000;

        $stop;

    end

    // Connect the VGA background module
    vga_background U1 (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .player_x(player_x),
        .player_y(player_y),
        .LEDR(LEDR),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

endmodule
