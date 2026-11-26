
module order_verify(
    input wire CLOCK_50,
    input wire resetn,
    input wire submit, //tells the module if a player has submitted a burger
    input wire [2:0] submitted_ingredients, //ingredients the player used 
    input wire [2:0] required_ingredients, //recipe from order_manager.v
    output reg correct_order, //goes high if order matches
    output reg incorrect_order //goes high if order does not match
);

    reg submit_prev; //stores whether submit was high or low in the previous cycle 

    // Verify once when submit changes from 0 to 1
    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            correct_order <= 0;
            incorrect_order <= 0;
            submit_prev <= 0;
        end
        else begin
            correct_order <= 0; //clears outputs every clock cycle, should only stay high for one cycle not indefineltly
            incorrect_order <= 0;

            if (submit && !submit_prev) begin //checks if submit went from 0 to 1, to prevent player from recieving points by just holding the submit button
                if (submitted_ingredients == required_ingredients) //compares ingredient bits 
                    correct_order <= 1; //match is 1 
                else
                    incorrect_order <= 1; //incorrect is 1
            end

            submit_prev <= submit; //stores new submission state
        end
    end

endmodule
