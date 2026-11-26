
`timescale 1ns/1ps

module heat_bar_tb;

    reg CLOCK_50;
    reg resetn;
    reg [5:0] heat_level;
    reg chef_busy;
    reg enable;

    wire [8:0] VGA_x;
    wire [7:0] VGA_y;
    wire [5:0] VGA_color;
    wire VGA_write;

    heat_bar dut (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .heat_level(heat_level),
        .chef_busy(chef_busy),
        .enable(enable),
        .VGA_x(VGA_x),
        .VGA_y(VGA_y),
        .VGA_color(VGA_color),
        .VGA_write(VGA_write)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        heat_level = 0;
        chef_busy = 0;
        enable = 0;

        // Reset and start drawing
        #60;
        resetn = 1;
        enable = 1;

        // Empty bar (grey)
        #10300;

        // Low heat (green)
        heat_level = 6'd10;
        #10300;

        // Medium heat (yellow)
        heat_level = 6'd30;
        #10300;

        // High heat (red)
        heat_level = 6'd55;
        #200;

        // Pause drawing
        enable = 0;
        #100;

        // Resume drawing
        enable = 1;
        #10300;

        $stop;
    end

endmodule
