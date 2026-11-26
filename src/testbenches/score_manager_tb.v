
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

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        correct_order = 0;

        // Reset score to 0
        #60;
        resetn = 1;

        // First correct order: score = 10
        #20;
        correct_order = 1;
        #20;
        correct_order = 0;

        // Second correct order: score = 20
        #20;
        correct_order = 1;
        #20;
        correct_order = 0;

        // No correct order: score stays at 20
        #100;

        // Third correct order: score = 30
        correct_order = 1;
        #20;
        correct_order = 0;

        // Reset score to 0
        #40;
        resetn = 0;
        #40;

        $stop;
    end

endmodule
        