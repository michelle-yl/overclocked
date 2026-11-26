
module order_display(
    input wire CLOCK_50,
    input wire resetn,
    input wire enable,
    input wire [1:0] order_id,
    input wire [2:0] required_ingredients,

    output reg [8:0] VGA_x, //position of pixel
    output reg [7:0] VGA_y,
    output reg [5:0] VGA_color, //color of pixel 6-bit
    output wire VGA_write //whether to write pixel into memory 
);

    // Three ingredient boxes, each 16x16 pixels
    // Total pixels = 3 * 256 = 768 for three boxes 
    reg [9:0] pixel_count; // counts 0 to 767 pixels, bits are divided into three sections Box, row, column

    // Remember which order was last displayed
    reg [1:0] displayed_order;

    // Indicates whether the order is currently being drawn
    reg drawing;

    // NEW: Remember whether drawing was previously allowed
    // This helps detect when the chef finishes drawing
    reg previous_enable;

    // Identify the ingredient box and pixel position
    wire [1:0] ingredient;
    wire [3:0] column;
    wire [3:0] row;

    assign ingredient = pixel_count[9:8];
    assign row = pixel_count[7:4];
    assign column = pixel_count[3:0];

    // Control when the order display needs to be drawn
    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            pixel_count <= 0;
            displayed_order <= 0;
            drawing <= 1;
            previous_enable <= 0;
        end
        else begin
            // Remember whether drawing is currently allowed
            previous_enable <= enable;

            // Redraw when a new burger order appears
            if (order_id != displayed_order) begin //if order changes the module restarts drawing at pixel 0 to display new recipe
                displayed_order <= order_id;
                pixel_count <= 0;
                drawing <= 1;
            end

            // Redraw after the chef finishes using VGA //for when chef renderer is restoring background pizels which could erase order graphics
            else if (enable && !previous_enable) begin //detects when VGA drawing is avaiable again and redraws boxes 
                pixel_count <= 0; //starts at pixel 0 
                drawing <= 1; //draws 
            end

            // Draw the order one pixel at a time
            else if (drawing && enable) begin //module is allowed to draw 
                if (pixel_count == 10'd767) begin //counter increases till all pixels are processed 
                    pixel_count <= 0;
                    drawing <= 0;
                end
                else begin
                    pixel_count <= pixel_count + 1'b1; //increase pixels
                end
            end
        end
    end

    // Calculate the position and colour of each pixel
    always @(*) begin
        VGA_x = 9'd224; //bun starts at x = 224 y = 8
        VGA_y = 8'd8 + {4'b0000, row}; //y = 8 + current row number vga y is 8 bits row is 4 bits 

        // Grey represents an ingredient that is not required
        VGA_color = 6'b010101; 

        // First box: bun
        if (ingredient == 2'd0) begin //when ingredient = 0
            VGA_x = 9'd224 + {5'b00000, column}; // box is x = 224, y = 8, determines horizontal pixel location 

            if (required_ingredients[0]) //checks whether a bun is required 
                VGA_color = 6'b111000;
        end

        // Second box: meat
        else if (ingredient == 2'd1) begin
            VGA_x = 9'd248 + {5'b00000, column}; //box is x = 248 y = 8
 
            if (required_ingredients[1]) //is meat required? //if not default is gray
                VGA_color = 6'b100000; 
        end

        // Third box: lettuce 
        else if (ingredient == 2'd2) begin 
            VGA_x = 9'd272 + {5'b00000, column}; //box is x = 272 y = 8

            if (required_ingredients[2]) //is lettuce required?
                VGA_color = 6'b001100;
        end
    end

    // Only send pixels when the chef isn't using VGA
    // Also wait until the displayed order matches the current order
    assign VGA_write = drawing && enable && resetn && 
                       (order_id == displayed_order);

endmodule
