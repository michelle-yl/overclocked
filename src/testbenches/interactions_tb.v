`timescale 1ns / 1ps

// Testbench for interactions (interactions.v)
// space is driven as a one clock pulse, like ctrlinput gives it.
// The stove input is driven by hand to stand in for stove.v's "give".
// Held codes: EMPTY 0, BUN 1, LETTUCE 2, RAW 3, COOKED 4, BURNT 5
// Plate bits: [0] bun, [1] cooked patty, [2] lettuce

module interactions_tb();

    parameter CLOCK_PERIOD = 20;

    // Station codes (same as defs.vh)
    parameter ST_NONE = 3'd0, ST_BUN = 3'd1, ST_LETTUCE = 3'd2, ST_PATTY = 3'd3,
              ST_STOVE = 3'd4, ST_PLATE = 3'd5, ST_TRASH = 3'd6;

    // Inputs to interactions
    reg CLOCK_50;
    reg resetn;
    reg space;
    reg [2:0] station;
    reg [2:0] stove;
    reg done;

    // Outputs from interactions
    wire [2:0] held;
    wire [2:0] plate;
    wire serve;

    // Generate the 50 MHz FPGA clock
    initial begin
        CLOCK_50 = 1'b0;
    end

    always begin
        #(CLOCK_PERIOD / 2);
        CLOCK_50 = ~CLOCK_50;
    end

    // Stand at station s and press space once
    task press(input [2:0] s);
        begin
            station = s;
            @(posedge CLOCK_50) space <= 1'b1;
            @(posedge CLOCK_50) space <= 1'b0;
            @(posedge CLOCK_50);
        end
    endtask

    initial begin

        // Reset
        resetn = 1'b0;
        space = 1'b0;
        station = ST_NONE;
        stove = 3'd0;
        done = 1'b0;
        #100;
        resetn = 1'b1;
        @(posedge CLOCK_50);
        // expect held 0, plate 000

        // Space with no station: nothing happens
        press(ST_NONE);
        // expect held 0

        // Grab a bun, put it on the plate
        press(ST_BUN);
        // expect held 1 (bun)
        press(ST_LETTUCE);
        // expect still held 1, hands are full
        press(ST_PLATE);
        // expect held 0, plate 001

        // Second bun: plate already has one, so it stays in hand
        press(ST_BUN);
        press(ST_PLATE);
        // expect held 1, plate still 001
        press(ST_TRASH);
        // expect held 0

        // Lettuce onto the plate
        press(ST_LETTUCE);
        press(ST_PLATE);
        // expect held 0, plate 101

        // Raw patty can't go on the plate
        press(ST_PATTY);
        // expect held 3 (raw)
        press(ST_PLATE);
        // expect still held 3, plate 101

        // Stove takes the raw patty (stove gives back EMPTY)
        stove = 3'd0;
        press(ST_STOVE);
        // expect held 0

        // Later the stove hands back a cooked patty
        stove = 3'd4;
        press(ST_STOVE);
        // expect held 4 (cooked)
        press(ST_PLATE);
        // expect held 0, plate 111

        // Empty hands at a full plate: serve pulses for one clock
        press(ST_PLATE);
        // expect serve pulse, plate still 111

        // Order checked: done clears the plate
        @(posedge CLOCK_50) done <= 1'b1;
        @(posedge CLOCK_50) done <= 1'b0;
        @(posedge CLOCK_50);
        // expect plate 000

        // Empty hands at an empty plate: no serve
        press(ST_PLATE);
        // expect no serve pulse

        // Burnt patty from the stove goes in the trash
        stove = 3'd5;
        press(ST_STOVE);
        // expect held 5 (burnt)
        press(ST_PLATE);
        // expect still held 5, plate 000
        press(ST_TRASH);
        // expect held 0

        // Reset clears hands and plate
        press(ST_BUN);
        press(ST_PLATE);
        press(ST_LETTUCE);
        resetn = 1'b0;
        @(posedge CLOCK_50);
        resetn = 1'b1;
        @(posedge CLOCK_50);
        // expect held 0, plate 000

        $stop;
    end

    interactions DUT (
        .clk(CLOCK_50),
        .resetn(resetn),
        .space(space),
        .station(station),
        .stove(stove),
        .done(done),
        .held(held),
        .plate(plate),
        .serve(serve)
    );

endmodule
