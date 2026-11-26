
`timescale 1ns/1ps

module order_manager_tb;

    reg CLOCK_50;
    reg resetn;
    reg correct_order;

    wire [1:0] order_id;
    wire [2:0] required_ingredients;

    order_manager dut (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .order_id(order_id),
        .required_ingredients(required_ingredients)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        correct_order = 0;

        // Reset to the first order (111)
        #60;
        resetn = 1;

        // Complete order 0, move to order 1 (101)
        #20;
        correct_order = 1;
        #20;
        correct_order = 0;

        // Complete order 1, move to order 2 (011)
        #20;
        correct_order = 1;
        #20;
        correct_order = 0;

        // Complete order 2, move to order 3 (110)
        #20;
        correct_order = 1;
        #20;
        correct_order = 0;

        // Complete order 3, return to order 0 (111)
        #20;
        correct_order = 1;
        #20;
        correct_order = 0;

        // No correct order: order should stay the same
        #100;

        $stop;
    end

endmodule
