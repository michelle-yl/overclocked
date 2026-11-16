module movechef(clk, clr, gametick, up, down, left, right, chefx, chefy, tilex, tiley)

input clk, clr, gametick, up, down, left, right;
output reg [8:0] chefx, cheft;
output [4:0] tilex, tiley;

// set starting pos
parameter IDLE = 1'b0, MOVE = 1'b1, UP = 2'd0, DOWN = 2'd1, LEFT = 2'd2, RIGHT = 2'd3
parameter STARTX = 9'd32, STARTY = 8'd80;

wire state;
wire [1:0] stepdir
wire [7:0] stepcount;

assign tilex = chefx[8:4];
assign tiley = chefy[8:4];

// where to next?
wire want = up | down | left | right;
wire [1:0] go = up? UP: down? DOWN: left? LEFT: right? RIGHT;

wire [4:0] nextx = (go == LEFT)? tilex - 1 : (go == RIGHT)? tilex + 1: tilex;
wire [4:0] nexty = (go == UP)? tiley - 1 : (go == DOWN)? tiley + 1: tiley;

// is this tile floor?
wire floor =  (nextx >= 1 && nextx <= 18 && nexty >= 4 && nexty <= 10)
            && !(nexty == 7 && nextx >= 6 && nextx <= 13);

always @(posedge clk)
begin
    if (!clr)
    begin
        chefx <= STARTX;
        chefy <= STARTY;
        state <= IDLE;
        stepcount <= 0;
    end
    else if (gemetick)
    begin
        case (state)
        IDLE: 
        begin
            if (want && floor)
            begin
                state <= MOVE;
                stepdir <= go;
                stepcount <= 0;
            end
        end
        MOVE:
end 
endmodule

/*
1. what does the layout look like right now
*/