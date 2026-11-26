module stations(tilex, tiley, idle, station);
input [4:0] tilex;
input [3:0] tiley;
input idle;
output reg [2:0] station;

`include "defs.vh"    // station codes from header file

always @(*)
begin
    station = NONE;
    if (idle)
    begin
        if (tilex == 5'd2  && tiley == 4'd4)  station = BUN;
        else if (tilex == 5'd4  && tiley == 4'd4)  station = LETTUCE;
        else if (tilex == 5'd6  && tiley == 4'd4)  station = PATTY;
        else if (tilex == 5'd14 && tiley == 4'd4)  station = STOVE;
        else if (tilex == 5'd10 && (tiley == 4'd7 || tiley == 4'd9))
                                                   station = PLATE;
        else if (tilex == 5'd3  && tiley == 4'd10) station = TRASH;
    end
end
endmodule