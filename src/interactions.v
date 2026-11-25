module interactions(clk, resetn, space, station, stove, done, held, plate, serve);
input clk, resetn, space, done;
input [2:0] station, stove;
output reg [2:0] held, plate;
output reg serve;

`include "defs.vh"

wire [2:0] item =   (held == H_BUN)     ? 3'b001:
                    (held == H_COOKED)  ? 3'b010:
                    (held == H_LETTUCE) ? 3'b100:
                                          3'b000;

always @(posedge clk)
begin
    serve <= 0;
    if (!resetn)
    begin
        held <= H_EMPTY;
        plate <= 3'd0;
    end
    else
    begin
        if (done)
            plate <= 3'd0;
        if (space)
        begin
            case (station)
            BUN: if (held == H_EMPTY) held <= H_BUN;
            LETTUCE: if (held == H_EMPTY) held <= H_LETTUCE;
            PATTY: if (held == H_EMPTY) held <= H_RAW;
            STOVE: held <= stove;
            PLATE: 
            begin
                if (item != 3'b000 && ((plate & item) == 3'b000))
                begin
                    plate <= plate | item;
                    held <= H_EMPTY;
                end
                else if (held == H_EMPTY && plate != 3'b000)
                    serve <= 1;
            end
            TRASH: held <= H_EMPTY;
            endcase
        end
    end
end
endmodule