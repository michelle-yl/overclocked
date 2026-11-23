
module order_verify(
    input wire CLOCK_50,
    input wire resetn,
    input wire submit,
    input wire [2:0] submitted_ingredients,
    input wire [2:0] required_ingredients,
    output reg correct_order,
    output reg incorrect_order
);

    reg submit_prev;

    // Verify once when submit changes from 0 to 1
    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            correct_order <= 0;
            incorrect_order <= 0;
            submit_prev <= 0;
        end
        else begin
            correct_order <= 0;
            incorrect_order <= 0;

            if (submit && !submit_prev) begin
                if (submitted_ingredients == required_ingredients)
                    correct_order <= 1;
                else
                    incorrect_order <= 1;
            end

            submit_prev <= submit;
        end
    end

endmodule
