
`timescale 1ns/1ps

module score_manager_tb;

    reg CLOCK_50;
    reg resetn;
    reg correct_order;

    wire [15:0] score;

    score_manager dut (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .score(score)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    task check_score;
        input [15:0] expected;
        begin
            if (score !== expected) begin
                $display("FAIL: expected=%d actual=%d",
                         expected, score);
                $stop;
            end
            else
                $display("PASS: score=%d", score);
        end
    endtask

    // Generate a one-clock correct-order pulse
    task add_points;
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

        repeat (3) @(negedge CLOCK_50);
        check_score(0);

        resetn = 1;

        // Correct order gives 10 points
        add_points();
        check_score(10);

        // Another correct order gives 20 total
        add_points();
        check_score(20);

        // No pulse means the score stays the same
        repeat (5) @(negedge CLOCK_50);
        check_score(20);

        // Third correct order
        add_points();
        check_score(30);

        // Reset returns the score to zero
        resetn = 0;
        @(negedge CLOCK_50);
        check_score(0);

        $display("ALL SCORE MANAGER TESTS PASSED");
        $stop;
    end

endmodule
