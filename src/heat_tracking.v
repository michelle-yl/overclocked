module trackheat(clk, resetn, tick1s, key, inplay, overclk, heat, warning, meltdown);
input clk, resetn, tick1s, key, inplay;
output overclk, warning;
output reg [4:0] heat;
output reg meltdown;

parameter NORMAL = 1'b0, OVERCLK = 1'b1;
parameter RISE = 5'd4, FALL = 5'd2;
reg state;

assign warning = heat[4] & heat[3];
assign overclk = (state == OVERCLK);

always @(posedge clk)
begin
    meltdown <= 0;
    if (!resetn)
    begin
        state <= NORMAL;
        heat <= 5'd0;
    end
    else
    begin
        if (key && inplay && (heat != 5'd31))
            state <= OVERCLK;            
        else
            state <= NORMAL;
        
        if (tick1s && inplay)
        begin
            if (state == OVERCLK)
            begin
                if (heat > (31-RISE))
                begin
                    heat <= 5'd31;
                    meltdown <= 1;
                end
                else
                    heat <= heat + RISE;
            end
            else
            begin
                if (heat < FALL)
                    heat <= 5'd0;
                else
                    heat <= heat - FALL;
            end
        end
    end
end

endmodule