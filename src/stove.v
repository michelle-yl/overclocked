module stove(clk, resetn, gametick, space, held, state, progress, give);
input clk, resetn, gametick, space;
input [2:0] held;
output reg [1:0] state;
output reg [3:0] progress;
output [2:0] give;
reg [4:0] tickcount;

`include "defs.vh"
parameter TICKS = 19;

wire place = (held == H_RAW) && (state == S_EMPTY);
wire take = (held == H_EMPTY) && (state == S_COOKED || state == S_BURNT);

assign give =   place   ? H_EMPTY:
                take    ? (state == S_COOKED? H_COOKED: H_BURNT):
                held;
                                            
always @(posedge clk)
begin
    if (!resetn)
    begin
        state <= S_EMPTY;
        tickcount <= 5'd0;
        progress <= 4'd0;
    end
    else if (space && place)
    begin
        state <= S_COOKING;
        tickcount <= 5'd0;
        progress <= 4'd0;
    end
    else if (space && take)
    begin
        state <= S_EMPTY;
        tickcount <= 5'd0;
        progress <= 4'd0;
    end
    else if (gametick && (state == S_COOKING || state == S_COOKED))
    begin
        if (tickcount == TICKS-1)
        begin
            tickcount <= 5'd0;
            if (progress == 15)
            begin
                progress <= 4'd0;
                state <= (state == S_COOKING) ? S_COOKED: S_BURNT;
            end
            else
            progress <= progress +1;
        end
        else
            tickcount <= tickcount+1;
    end
end                                           
endmodule