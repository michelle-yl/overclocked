`default_nettype none 

/*  This code serves as an example that illustrates usage of the VGA output in the DE1-SoC 
 *  board. The code uses a VGA adapter to send pixel colors to the VGA display. To use the demo 
 *  first press KEY[0] to reset the circuit. It will display the contents of a video memory
 *  in the VGA adapter as a background image.
*/
module vga_background(CLOCK_50, KEY, LEDR, VGA_R, VGA_G, VGA_B,
                      VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, player_x, player_y);
	
    parameter RESOLUTION = "320x240"; // "640x480" "320x240" "160x120" //adjusted
    parameter COLOR_DEPTH = 6; // 9 6 3 // adjusted 

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 9 : 8); //chooses bit size based on chosen resolution
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = (RESOLUTION == "640x480") ? 9 : ((RESOLUTION == "320x240") ? 8 : 7);

	input wire CLOCK_50;	
	input wire [3:0] KEY;
    
    // Chef position provided by the game
    input wire [8:0] player_x; //chef coordinates provided by movement logic, gets passed into sprite renderer
    input wire [7:0] player_y;

	output wire [9:0] LEDR;
    output wire [7:0] VGA_R;
    output wire [7:0] VGA_G;
    output wire [7:0] VGA_B;
    output wire VGA_HS; //tells monitor when new horizontal line begins
    output wire VGA_VS; //new vertical line begins
    output wire VGA_BLANK_N; //indicates when video output is enabled
    output wire VGA_SYNC_N; //sync related outputers
    output wire VGA_CLK;  //pixel clock 25Mhz

	// The four signals below are used in demos that actively draw pixels on top of the 
    // background MIF. In this example, only the background is drawn, so these signals are 
    // just used as placeholders in this very simple example. 
	wire [COLOR_DEPTH-1:0] color;     //6 bit color of pixel to write   
    wire [nX-1:0] X;                  //x coord
    wire [nY-1:0] Y;                     
    wire write;                       //write pixel into vga memoroy 0 means no
    
    // display the color depth
    assign LEDR[3:0] = (COLOR_DEPTH == 9) ? 4'b1001 : ((COLOR_DEPTH == 6) ? 4'b0110 : 4'b0011); //selects binary value displayed on first four leds
   
    // Draw the chef on top of the kitchen background
    sprite_renderer chef_renderer (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),
        .player_x(player_x),
        .player_y(player_y),
        .VGA_x(X),
        .VGA_y(Y),
        .VGA_color(color),
        .VGA_write(write)
    );

    // instantiate the VGA adapter
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
        .VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = RESOLUTION; // 320x240
    defparam VGA.BACKGROUND_IMAGE = "assets/kitchen_background.mif"; //which .mif file has the image
    defparam VGA.COLOR_DEPTH = COLOR_DEPTH; //six bits per pixel
endmodule

`default_nettype wire //incase you use an undecleared signal name 
