`timescale 1ns / 1ps

// Testbench for stations (stations.v)
// Purely combinational: set a tile, wait, read station.
// Station codes (defs.vh): NONE 0, BUN 1, LETTUCE 2, PATTY 3,
//                          STOVE 4, PLATE 5, TRASH 6

module stations_tb();

    // Inputs to stations
    reg [4:0] tilex;
    reg [3:0] tiley;
    reg idle;

    // Outputs from stations
    wire [2:0] station;

    // Move the chef to tile (x, y) and let the logic settle
    task goto(input [4:0] x, input [3:0] y);
        begin
            tilex = x;
            tiley = y;
            #20;
        end
    endtask

    initial begin

        // Start somewhere empty, standing still
        idle = 1'b1;
        goto(5'd0, 4'd0);
        // expect NONE (0)

        // Every station tile
        goto(5'd2, 4'd4);
        // expect BUN (1)
        goto(5'd4, 4'd4);
        // expect LETTUCE (2)
        goto(5'd6, 4'd4);
        // expect PATTY (3)
        goto(5'd14, 4'd4);
        // expect STOVE (4)
        goto(5'd10, 4'd7);
        // expect PLATE (5)
        goto(5'd10, 4'd9);
        // expect PLATE (5), second plate tile
        goto(5'd3, 4'd10);
        // expect TRASH (6)

        // Tiles next to stations: should be NONE
        goto(5'd3, 4'd4);
        // expect NONE (between bun and lettuce)
        goto(5'd10, 4'd8);
        // expect NONE (between the two plate tiles)
        goto(5'd14, 4'd5);
        // expect NONE (below stove)

        // Right tile, but chef is moving: should be NONE
        goto(5'd14, 4'd4);
        idle = 1'b0;
        #20;
        // expect NONE (not idle)
        idle = 1'b1;
        #20;
        // expect STOVE (4) again once idle

        $stop;
    end

    stations DUT (
        .tilex(tilex),
        .tiley(tiley),
        .idle(idle),
        .station(station)
    );

endmodule
