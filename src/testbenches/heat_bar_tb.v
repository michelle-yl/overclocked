
`timescale 1ns/1ps

module heat_bar_tb;

    reg CLOCK_50;
    reg resetn;
    reg [5:0] heat_level;
    reg chef_busy;
    reg enable;

    wire [8:0] VGA_x;
    wire [7:0] VGA_y;
    wire [5:0] VGA_color;
    wire VGA_write;

    heat_bar dut (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .heat_level(heat_level),
        .chef_busy(chef_busy),
        .enable(enable),
        .VGA_x(VGA_x),
        .VGA_y(VGA_y),
        .VGA_color(VGA_color),
        .VGA_write(VGA_write)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    // Change the heat level and check the first pixel
    task check_heat;
        input [5:0] new_heat;
        input [5:0] expected_color;
        begin
            @(negedge CLOCK_50);
            heat_level = new_heat;

            @(negedge CLOCK_50);
            #1;

            if (VGA_x !== 9'd224 ||
                VGA_y !== 8'd32 ||
                VGA_color !== expected_color ||
                VGA_write !== 1'b1) begin

                $display("FAIL: heat=%d x=%d y=%d color=%b",
                         new_heat, VGA_x, VGA_y, VGA_color);
                $stop;
            end
            else
                $display("PASS: heat=%d color=%b",
                         new_heat, VGA_color);
        end
    endtask

    initial begin
        CLOCK_50 = 0;
        resetn = 0;
        heat_level = 0;
        chef_busy = 0;
        enable = 0;

        repeat (3) @(negedge CLOCK_50);
        resetn = 1;
        enable = 1;

        // Empty heat bar should be grey
        #1;
        if (VGA_color !== 6'b010101) begin
            $display("FAIL: empty bar is not grey");
            $stop;
        end
        $display("PASS: empty bar");

        // Low heat should be green
        check_heat(6'd10, 6'b001100);

        // Medium heat should be yellow
        check_heat(6'd30, 6'b111100);

        // High heat should be red
        check_heat(6'd55, 6'b110000);

        // Disable the heat display
        @(negedge CLOCK_50);
        enable = 0;
        #1;

        if (VGA_write !== 0) begin
            $display("FAIL: heat bar did not pause");
            $stop;
        end
        $display("PASS: heat bar pauses");

        // Resume drawing
        @(negedge CLOCK_50);
        enable = 1;
        #1;

        if (VGA_write !== 1) begin
            $display("FAIL: heat bar did not resume");
            $stop;
        end
        $display("PASS: heat bar resumes");

        $display("ALL HEAT BAR TESTS PASSED");
        $stop;
    end

endmodule
