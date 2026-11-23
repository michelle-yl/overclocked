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

    // Check the submitted burger against the current order
    order_verify verification (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .submit(submit),
        .submitted_ingredients(submitted_ingredients),
        .required_ingredients(required_ingredients),
        .correct_order(correct_order),
        .incorrect_order(incorrect_order)
    );

    // Add 10 points for each correct submission
    score_manager scoring (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .score(score)
    );

    // Generate the 50 MHz clock
    always #10 CLOCK_50 = ~CLOCK_50;

    // Check that the order and score match expected values
    task check_game;
        input [1:0] expected_order;
        input [15:0] expected_score;
        begin
            if (order_id !== expected_order ||
                score !== expected_score) begin
                $display("FAIL: order=%d score=%d",
                         order_id, score);
                $stop;
            end
            else begin
                $display("PASS: order=%d score=%d",
                         order_id, score);
            end
        end
    endtask

    // Submit a burger and allow the modules to update
    task submit_burger;
        input [2:0] ingredients;
        begin
            @(negedge CLOCK_50);
            submitted_ingredients = ingredients;
            submit = 1;

            // Allow verification, scoring and order change
            repeat (3) @(negedge CLOCK_50);

            submit = 0;
            @(negedge CLOCK_50);
        end
    endtask

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        submit = 0;
        submitted_ingredients = 0;

        // Reset the game
        repeat (3) @(negedge CLOCK_50);
        resetn = 1;

        check_game(0, 0);

        // Wrong burger should not change anything
        submit_burger(3'b101);
        check_game(0, 0);

        // Correct full burger
        submit_burger(3'b111);
        check_game(1, 10);

        // Correct bun + lettuce burger
        submit_burger(3'b101);
        check_game(2, 20);

        // Correct bun + meat burger
        submit_burger(3'b011);
        check_game(3, 30);

        // Correct lettuce wrap
        submit_burger(3'b110);
        check_game(0, 40);

        // Wrong burger should not increase score
        submit_burger(3'b011);
        check_game(0, 40);

        // Reset should clear the score and order
        resetn = 0;
        repeat (2) @(negedge CLOCK_50);
        check_game(0, 0);

        $display("ALL ORDER SYSTEM TESTS PASSED");
        $stop;
    end

endmodule