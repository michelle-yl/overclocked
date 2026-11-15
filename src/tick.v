module counter_26b(En, Q, Clk, Clr, onesec);
	input En, Clk, Clr;
	output reg [25:0] Q;
	output reg onesec;

	always @(posedge Clk) begin
		if (!Clr) begin
			Q <= 20'b0;
			onesec <= 1'b0;
		end
		else if (Q == 20'd833332) begin
//		else if (Q == 26'd4) begin
			Q <= 20'b0;
			onesec <= 1'b1;
		end
		else begin
			onesec <= 1'b0;
			if (En)
				Q <= Q + 1;
		end
	end
endmodule