
`timescale 1ns/1ps

module order_display_tb;

    reg CLOCK_50;
    reg resetn;
    reg enable;
    reg [1:0] order_id;
    reg [2:0] required_ingredients;

    wire [8:0] VGA_x;
    wire [7:0] VGA_y;
    wire [5:0] VGA_color;
    wire VGA_write;

    order_display dut (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .enable(enable),
        .order_id(order_id),
        .required_ingredients(required_ingredients),
        .VGA_x(VGA_x),
        .VGA_y(VGA_y),
        .VGA_color(VGA_color),
        .VGA_write(VGA_write)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        enable = 0;
        order_id = 0;
        required_ingredients = 3'b111;

        // Reset and begin drawing
        #60;
        resetn = 1;
        enable = 1;

        // Draw all 768 pixels for order 0 (111)
        #15500;

        // Change to order 1: bun and lettuce, no meat
        order_id = 2'd1;
        required_ingredients = 3'b101;

        // Draw all 768 pixels for the new order
        #15500;

        // Change back to order 0
        order_id = 2'd0;
        required_ingredients = 3'b111;

        // Pause while drawing
        #200;
        enable = 0;
        #100;

        // Resume drawing
        enable = 1;
        #15500;

        $stop;
    end

endmodule
