module tickgen(clk, clr, overclk, gametick, tick1s, tick);
	input clk, clr, overclk;

	reg boost;
	reg [19:0] Q;
	output reg gametick;

	parameter TICK60HZ = 20'd833332, TICK90HZ = 20'd555555;
	wire [19:0] limit = boost ? TICK90HZ : TICK60HZ;

	always @(posedge clk) begin
		if (!clr) 
		begin
			Q <= 20'b0;
			gametick <= 1'b0;
			boost <=1'b0;
		end
		else if (Q == limit)
		begin
			boost <= overclk;
			Q <= 20'b0;
			gametick <= 1'b1;
		end
		else begin
			gametick <= 1'b0;
			Q <= Q + 1;
		end
	end
endmodule


module tick1s(clk, clr, onesec);
	input clk, clr;
	output onesec;
	wire [25:0] Q;

	parameter TICK1S = 26'd49999999;
	always @(posedge Clk) 
	begin
		if (!Clr) 
		begin
			Q <= 26'b0;
			onesec <= 1'b0;
		end
		else if (Q == TICK1S)	
		begin
			Q <= 26'b0;
			onesec <= 1'b1;
		end
		else
		begin 
			onesec <= 1'b0;
			Q <= Q + 1;
		end
	end
endmodule