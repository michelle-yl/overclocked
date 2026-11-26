
module order_manager(
    input wire CLOCK_50, 
    input wire resetn, //active low
    input wire correct_order, //signal that is passed from order_verify.v for proper completion of order
    input wire [1:0] randorder, // random order determined by lfsr
    output reg [1:0] order_id, //tells you which of four recipes is currently active 
    output reg [2:0] required_ingredients //tells you required ingredients for recipe 
);

    // Move through four burger recipes after successful submissions
    always @(posedge CLOCK_50) begin
        if (!resetn) //if reset set current order to 0
            order_id <= randorder; // random now
        else if (correct_order) begin //if player completed previous burger correctly change the order
            order_id <= randorder; // random now
            // if (order_id == 2'd3) //if we are on fourth recipe go back to the first one instead of going beyond avaible recipes
            //     order_id <= 2'd0;
            // else
            //     order_id <= order_id + 1'b1; //move forward one recipe 
        end 
    end

    // Ingredient bits: [2] lettuce, [1] meat, [0] bun
    always @(*) begin //converts current order id into correct recipe 
        case (order_id) // if 1 then 3'b111 if 2 then 3'b101; 
            2'd0: required_ingredients = 3'b111; // Full burger
            2'd1: required_ingredients = 3'b101; // Bun + lettuce
            2'd2: required_ingredients = 3'b011; // Bun + meat
            2'd3: required_ingredients = 3'b110; // Lettuce wrap
            default: required_ingredients = 3'b111;
        endcase
    end

endmodule
