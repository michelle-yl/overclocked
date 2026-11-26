
module score_manager(
    input wire CLOCK_50,
    input wire resetn,
    input wire correct_order,
    output reg [15:0] score //stored in a 16-bit register 
);

    // Each correct order earns 10 points
    always @(posedge CLOCK_50) begin
        if (!resetn)
            score <= 16'd0; //score resets
        else if (correct_order)
            score <= score + 16'd10; //score + 10 points 
    end

endmodule
