
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

    // 50 MHz clock
    always #10 CLOCK_50 = ~CLOCK_50;

    // Check the correct and incorrect outputs
    task check_result;
        input expected_correct;
        input expected_incorrect;
        begin
            if (correct_order !== expected_correct ||
                incorrect_order !== expected_incorrect) begin

                $display("FAIL: correct=%b incorrect=%b",
                         correct_order, incorrect_order);
                $stop;
            end
            else begin
                $display("PASS: correct=%b incorrect=%b",
                         correct_order, incorrect_order);
            end
        end
    endtask

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        submit = 0;

        submitted_ingredients = 0;
        required_ingredients = 3'b111;

        // Reset the module
        repeat (3) @(negedge CLOCK_50);
        resetn = 1;

        // Test 1: Correct burger
        submitted_ingredients = 3'b111;
        submit = 1;

        @(negedge CLOCK_50);
        check_result(1, 0);

        // Holding submit must not cause repeated submissions
        repeat (3) @(negedge CLOCK_50);
        check_result(0, 0);

        // Release submit
        submit = 0;
        @(negedge CLOCK_50);

        // Test 2: Missing ingredient
        submitted_ingredients = 3'b101;
        submit = 1;

        @(negedge CLOCK_50);
        check_result(0, 1);

        submit = 0;
        @(negedge CLOCK_50);

        // Test 3: Extra ingredient
        required_ingredients = 3'b101;
        submitted_ingredients = 3'b111;
        submit = 1;

        @(negedge CLOCK_50);
        check_result(0, 1);

        submit = 0;
        @(negedge CLOCK_50);

        // Test 4: Correct second recipe
        submitted_ingredients = 3'b101;
        submit = 1;

        @(negedge CLOCK_50);
        check_result(1, 0);

        submit = 0;
        @(negedge CLOCK_50);

        // Test 5: Reset clears result signals
        resetn = 0;
        @(negedge CLOCK_50);
        check_result(0, 0);

        $display("ALL ORDER VERIFICATION TESTS PASSED");
        $stop;
    end

endmodule
