module movechef(clk, clr, gametick, up, down, left, right, chefx, chefy, tilex, tiley);

input clk, clr, gametick, up, down, left, right;
output reg [8:0] chefx;
output reg [7:0] chefy;
output [4:0] tilex;
output [3:0] tiley;

// set starting pos
parameter IDLE = 1'b0, MOVE = 1'b1, UP = 2'd0, DOWN = 2'd1, LEFT = 2'd2, RIGHT = 2'd3;
parameter STARTX = 9'd32, STARTY = 8'd80;

reg state;
reg [1:0] stepdir;
reg [2:0] stepcount;

assign tilex = chefx[8:4]; //converts pixels into tiles, each tile is 16 pixels each
assign tiley = chefy[7:4];

// where to next?
wire want = up | down | left | right;
wire [1:0] go = up? UP: down? DOWN: left? LEFT: RIGHT; //direction priority, if both are pressed up occurs first 

wire [4:0] nextx = (go == LEFT)? tilex - 1 : (go == RIGHT)? tilex + 1: tilex; //where chef wants to move based on w a s d
wire [3:0] nexty = (go == UP)? tiley - 1 : (go == DOWN)? tiley + 1: tiley;

// is this next tile floor?
wire floor =  (nextx >= 1 && nextx <= 18 && nexty >= 4 && nexty <= 10) && !(nexty == 7 && nextx >= 6 && nextx <= 13); //defines whihc tiles the chef can enter 

always @(posedge clk) //movement FSM
begin
    // reset
    if (!clr)
    begin
        chefx <= STARTX;
        chefy <= STARTY;
        state <= IDLE;
        stepcount <= 0;
    end
    else if (gametick)
    begin
        case (state)
        // move if we want to and the next tile is floor
        IDLE: 
        begin
            if (want && floor)
            begin
                state <= MOVE; 
                stepdir <= go; //direction
                stepcount <= 0;
            end
        end
        MOVE:
        begin
            // move 2 pixels per tick
            case (stepdir) 
            UP: chefy <= chefy - 2; 
            DOWN: chefy <= chefy + 2;
            LEFT: chefx <= chefx - 2;
            RIGHT: chefx <= chefx + 2;
            endcase
            // if moved one tile, go back to idle
            if (stepcount == 3'd7)
                state <= IDLE;
            stepcount <= stepcount + 1;
        end
        endcase
    end
end 
endmodule

