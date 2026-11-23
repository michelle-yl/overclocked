module tickgen(clk, clr, overclk, gametick, tick1s);
	input clk, clr, overclk;

	reg boost;
	reg [19:0] Q1;
	reg [25:0] Q2;
	output reg gametick;
	output reg tick1s;

	parameter TICK60HZ = 20'd833332, TICK90HZ = 20'd555555; //determine how many clock cycles occur between game ticks
	wire [19:0] limit = boost ? TICK90HZ : TICK60HZ; //if boost more ticks, else normal
	parameter TICK1S = 26'd49999999;

	always @(posedge clk) begin //movement tick counter
		if (!clr)  //if reset
		begin
			Q1 <= 20'b0; //20 bit to limit
			gametick <= 1'b0;
			boost <=1'b0;
		end
		else if (Q1 == limit) //if at limit turn on boost, produce a pulse
		begin
			boost <= overclk;
			Q1 <= 20'b0; 
			gametick <= 1'b1;
		end
		else begin
			gametick <= 1'b0;
			Q1 <= Q1 + 1;
		end
	end
	
	always @(posedge clk) //one second counter
	begin
		if (!clr) 
		begin
			Q2 <= 26'b0; //counts from 26bit 0 to 49 999 999
			tick1s <= 1'b0;
		end
		else if (Q2 == TICK1S)	
		begin
			Q2 <= 26'b0;
			tick1s <= 1'b1;
		end
		else
		begin 
			tick1s <= 1'b0;
			Q2 <= Q2 + 1;
		end
	end
endmodule