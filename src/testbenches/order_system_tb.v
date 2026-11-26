
`timescale 1ns/1ps

module order_system_tb;

    reg CLOCK_50;
    reg resetn;
    reg submit;
    reg [2:0] submitted_ingredients;

    wire [1:0] order_id;
    wire [2:0] required_ingredients;
    wire correct_order;
    wire incorrect_order;
    wire [15:0] score;

    // Select the current burger order
    order_manager orders (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .order_id(order_id),
        .required_ingredients(required_ingredients)
    );

    // Verify the submitted burger
    order_verify verification (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .submit(submit),
        .submitted_ingredients(submitted_ingredients),
        .required_ingredients(required_ingredients),
        .correct_order(correct_order),
        .incorrect_order(incorrect_order)
    );

    // Update the score
    score_manager scoring (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .score(score)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        submit = 0;
        submitted_ingredients = 0;

        // Reset the game
        #60;
        resetn = 1;

        // Incorrect burger: score stays 0, order stays 0
        #20;
        submitted_ingredients = 3'b101;
        submit = 1;
        #60;
        submit = 0;

        // Correct burger 111: score 10, order 1
        #40;
        submitted_ingredients = 3'b111;
        submit = 1;
        #60;
        submit = 0;

        // Correct burger 101: score 20, order 2
        #40;
        submitted_ingredients = 3'b101;
        submit = 1;
        #60;
        submit = 0;

        // Correct burger 011: score 30, order 3
        #40;
        submitted_ingredients = 3'b011;
        submit = 1;
        #60;
        submit = 0;

        // Correct burger 110: score 40, order 0
        #40;
        submitted_ingredients = 3'b110;
        submit = 1;
        #60;
        submit = 0;

        // Incorrect burger: score stays 40
        #40;
        submitted_ingredients = 3'b011;
        submit = 1;
        #60;
        submit = 0;

        // Reset score and order
        #40;
        resetn = 0;
        #40;

        $stop;
    end

endmodule
