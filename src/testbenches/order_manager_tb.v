
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

    // Check the currently selected burger order
    task check_order;
        input [1:0] expected_id;
        input [2:0] expected_ingredients;
        begin
            if (order_id !== expected_id ||
                required_ingredients !== expected_ingredients) begin
                $display("FAIL: order=%d ingredients=%b",
                         order_id, required_ingredients);
                $stop;
            end
            else
                $display("PASS: order=%d ingredients=%b",
                         order_id, required_ingredients);
        end
    endtask

    // Simulate successfully completing an order
    task complete_order;
        begin
            @(negedge CLOCK_50);
            correct_order = 1;

            @(negedge CLOCK_50);
            correct_order = 0;
        end
    endtask

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        correct_order = 0;

        // Reset should select the first burger
        repeat (3) @(negedge CLOCK_50);
        resetn = 1;
        check_order(2'd0, 3'b111);

        // Move through all four recipes
        complete_order();
        check_order(2'd1, 3'b101);

        complete_order();
        check_order(2'd2, 3'b011);

        complete_order();
        check_order(2'd3, 3'b110);

        // After the fourth order, return to the first
        complete_order();
        check_order(2'd0, 3'b111);

        // No correct_order pulse means no change
        repeat (5) @(negedge CLOCK_50);
        check_order(2'd0, 3'b111);

        $display("ALL ORDER MANAGER TESTS PASSED");
        $stop;
    end

endmodule
