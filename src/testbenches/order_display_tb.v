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

    integer i;
    integer pixel_writes;

    // Connect the order display module
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

    // Generate a 50 MHz clock
    always #10 CLOCK_50 = ~CLOCK_50;

    // Check a pixel's position, colour, and write signal
    task check_pixel;
        input [8:0] expected_x;
        input [7:0] expected_y;
        input [5:0] expected_color;
        begin
            if (VGA_x !== expected_x ||
                VGA_y !== expected_y ||
                VGA_color !== expected_color ||
                VGA_write !== 1'b1) begin

                $display("FAIL: x=%d y=%d color=%b write=%b",
                         VGA_x, VGA_y, VGA_color, VGA_write);
                $stop;
            end
            else begin
                $display("PASS: x=%d y=%d color=%b",
                         VGA_x, VGA_y, VGA_color);
            end
        end
    endtask

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        enable = 0;
        order_id = 0;
        required_ingredients = 3'b111;
        pixel_writes = 0;

        // Reset the module
        repeat (3) @(negedge CLOCK_50);
        resetn = 1;
        enable = 1;

        // Test 1: First pixel is the bun colour
        #1;
        check_pixel(9'd224, 8'd8, 6'b111000);

        // Test 2: Count all 768 pixels in the order display
        for (i = 0; i < 768; i = i + 1) begin
            #1;
            if (VGA_write)
                pixel_writes = pixel_writes + 1;

            @(negedge CLOCK_50);
        end

        if (pixel_writes !== 768) begin
            $display("FAIL: expected 768 pixels, got %d",
                     pixel_writes);
            $stop;
        end

        $display("PASS: all 768 pixels drawn");

        // Test 3: Change to bun + lettuce (no meat)
        order_id = 2'd1;
        required_ingredients = 3'b101;

        // Let the module detect the new order
        @(negedge CLOCK_50);
        #1;

        check_pixel(9'd224, 8'd8, 6'b111000);

        // Advance to the first pixel of the meat box
        repeat (256) @(negedge CLOCK_50);
        #1;

        check_pixel(9'd248, 8'd8, 6'b010101);

        // Test 4: Pause when the chef uses VGA
        enable = 0;
        #1;

        if (VGA_write !== 0) begin
            $display("FAIL: display did not pause");
            $stop;
        end

        $display("PASS: display pauses");

        // Test 5: Resume when the chef finishes
        enable = 1;
        #1;

        if (VGA_write !== 1) begin
            $display("FAIL: display did not resume");
            $stop;
        end

        $display("PASS: display resumes");

        $display("ALL ORDER DISPLAY TESTS PASSED");
        $stop;
    end

endmodule