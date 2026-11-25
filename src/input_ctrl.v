module ctrlinput(clk, resetn, interact, gametick, timeup, space);

input clk, resetn, interact, gametick, timeup;
output space;

reg prev, pending;
wire keypressed = interact & ~prev; 
assign space = (pending | keypressed) & (gametick & !timeup);

always @(posedge clk) 
begin
    if (!resetn) 
    begin
        prev <= 0;
        pending <= 0;
    end
    else 
    begin
        prev <= interact;

        if (keypressed)
            pending <= 1;
        if (gametick)
            pending <= 0;
    end
end
endmodule