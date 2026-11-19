module timer(clk, clr, tick1s, min, tens, ones, timeup);
input clk, clr, tick1s;
output reg [3:0] min, tens, ones;
output timeup;

always@(posedge clk)
begin
    if (!clr)
    begin
        min <= 4'd2;
        tens <= 4'd0;
        ones <= 4'd0;
    end
    else if (tick1s)
    begin
        if (ones > 4'd0)
            ones <=ones - 4'd1;
        else if (tens > 4'd0)
            begin
                tens <= tens - 4'd1;
                ones <= 4'd9;
            end
        else if (min > 4'd0)
            begin
                min <= min - 4'd1;
                tens <= 4'd5;
                ones <=4'd9;
            end
    end
end
assign timeup = (min == 4'd0 && tens == 4'd0 && ones == 4'd0);
endmodule