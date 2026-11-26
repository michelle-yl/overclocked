
module score_manager(
    input wire CLOCK_50,
    input wire resetn,
    input wire correct_order,
    output [11:0] score //BCD score {hundreds, tens, ones}, reads 000 to 990
);
    reg [3:0] hundreds, tens;

    // Score only goes up by 10, so the ones digit is always 0
    assign score = {hundreds, tens, 4'd0};

    // Each correct order earns 10 points: tens counts 0-9 and carries into hundreds
    always @(posedge CLOCK_50) begin
        if (!resetn)
        begin
            hundreds <= 0;
            tens <= 0;
        end
        else if (correct_order && !(hundreds == 4'd9 && tens == 4'd9)) //stop at 990, won't get up there anyway
        begin
            if (tens == 4'd9)
            begin
                tens <= 0;
                hundreds <= hundreds + 1; // increment at _90
            end
            else
                tens <= tens + 1; // increment 10 for 1 order
        end
    end

endmodule
