module helditem(clk, resetn, enable, held, stove, plate, VGAx, VGAy, VGAcolor, VGAwrite);
input clk, resetn;
input enable;              
input [2:0] held;           
input [1:0] stove;          
input [2:0] plate;          
output reg [8:0] VGAx;      // pixel x, 0-319
output reg [7:0] VGAy;      // pixel y, 0-239
output reg [5:0] VGAcolor;  // 6-bit colour 
output VGAwrite;            

`include "defs.vh"

reg [8:0] pixel_count;
wire [2:0] box = pixel_count[8:6];   
wire [2:0] row = pixel_count[5:3];   
wire [2:0] col = pixel_count[2:0];

// which box is being drawn (B_ prefix: BUN, LETTUCE, STOVE already exist in defs.vh)
parameter B_HELD = 3'd0, B_STOVE = 3'd1, B_BUN = 3'd2, B_MEAT = 3'd3, B_LETTUCE = 3'd4;

// redraw 320 pixels
always @(posedge clk)
begin
    if (!resetn)
        pixel_count <= 9'd0;
    else if (enable)
    begin
        if (pixel_count == 9'd319)
            pixel_count <= 9'd0;
        else
            pixel_count <= pixel_count + 1'b1;
    end
end

always @(*)
begin
    VGAx = 9'd0;
    VGAy = 8'd0;
    VGAcolor = 6'b010101;                    // grey = nothing there

    case (box)
    B_HELD:
    begin
        VGAx = 9'd204 + {6'b0, col};
        VGAy = 8'd12  + {5'b0, row};
        case (held)
        H_BUN:     VGAcolor = 6'b111000;     // orange
        H_LETTUCE: VGAcolor = 6'b001100;     // green
        H_RAW:     VGAcolor = 6'b110101;     // pink
        H_COOKED:  VGAcolor = 6'b100000;     // red
        H_BURNT:   VGAcolor = 6'b000000;     // black
        endcase                             
    end

    B_STOVE:
    begin
        VGAx = 9'd228 + {6'b0, col};
        VGAy = 8'd52  + {5'b0, row};
        case (stove)
        S_COOKING: VGAcolor = 6'b110101;     // pink
        S_COOKED:  VGAcolor = 6'b100000;     // red
        S_BURNT:   VGAcolor = 6'b000000;     // black
        endcase                              // S_EMPTY stays grey
    end

    B_BUN:
    begin
        VGAx = 9'd228 + {6'b0, col};
        VGAy = 8'd24  + {5'b0, row};
        if (plate[0]) VGAcolor = 6'b111000;  // bun
    end

    B_MEAT:
    begin
        VGAx = 9'd252 + {6'b0, col};
        VGAy = 8'd24  + {5'b0, row};
        if (plate[1]) VGAcolor = 6'b100000;  // meat
    end

    B_LETTUCE:
    begin
        VGAx = 9'd276 + {6'b0, col};
        VGAy = 8'd24  + {5'b0, row};
        if (plate[2]) VGAcolor = 6'b001100;  // lettuce
    end
    endcase
end

assign VGAwrite = enable && resetn;

endmodule
