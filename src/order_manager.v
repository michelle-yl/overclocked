
module order_manager(
    input wire CLOCK_50,
    input wire resetn,
    input wire correct_order,
    output reg [1:0] order_id,
    output reg [2:0] required_ingredients
);

    // Move through four burger recipes after successful submissions
    always @(posedge CLOCK_50) begin
        if (!resetn)
            order_id <= 2'd0;
        else if (correct_order) begin //once it gets to last order id it will return to the first for now its a counter
            if (order_id == 2'd3)
                order_id <= 2'd0;
            else
                order_id <= order_id + 1'b1;
        end
    end

    // Ingredient bits: [2] lettuce, [1] meat, [0] bun
    always @(*) begin
        case (order_id)
            2'd0: required_ingredients = 3'b111; // Full burger
            2'd1: required_ingredients = 3'b101; // Bun + lettuce
            2'd2: required_ingredients = 3'b011; // Bun + meat
            2'd3: required_ingredients = 3'b110; // Lettuce wrap
            default: required_ingredients = 3'b111;
        endcase
    end

endmodule
