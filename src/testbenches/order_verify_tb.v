
`timescale 1ns/1ps

module order_verify_tb;

    reg CLOCK_50;
    reg resetn;
    reg submit;

    reg [2:0] submitted_ingredients;
    reg [2:0] required_ingredients;

    wire correct_order;
    wire incorrect_order;

    order_verify dut (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .submit(submit),
        .submitted_ingredients(submitted_ingredients),
        .required_ingredients(required_ingredients),
        .correct_order(correct_order),
        .incorrect_order(incorrect_order)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        submit = 0;

        submitted_ingredients = 0;
        required_ingredients = 3'b111;

        // Reset the module
        #60;
        resetn = 1;

        // Test 1: Correct burger (111 = 111)
        #20;
        submitted_ingredients = 3'b111;
        submit = 1;

        // Hold submit high to check for repeated submissions
        #80;
        submit = 0;

        // Test 2: Missing ingredient (101 != 111)
        #40;
        submitted_ingredients = 3'b101;
        submit = 1;
        #40;
        submit = 0;

        // Test 3: Extra ingredient (111 != 101)
        #40;
        required_ingredients = 3'b101;
        submitted_ingredients = 3'b111;
        submit = 1;
        #40;
        submit = 0;

        // Test 4: Correct second recipe (101 = 101)
        #40;
        submitted_ingredients = 3'b101;
        submit = 1;
        #40;
        submit = 0;

        // Test 5: Reset clears the outputs
        #40;
        resetn = 0;
        #40;

        $stop;
    end

endmodule
