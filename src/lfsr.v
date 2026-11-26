module lfsr16b(clk, q);
input clk;
output reg [15:0] q = 16'hABCD;

wire fb = q[15] ^ q[13] ^ q[12] ^ q[10];

always @(posedge clk)
    q <= {q[14:0], fb};
endmodule