
module sprite_renderer (
    input wire CLOCK_50,
    input wire resetn,

    // Position of the chef, provided by Michelle's code
    input wire [8:0] player_x,
    input wire [7:0] player_y,

    // Pixel information sent to the VGA adapter
    output wire [8:0] VGA_x,
    output wire [7:0] VGA_y,
    output wire [5:0] VGA_color,
    output wire VGA_write
);

    // The chef image is 32x32 pixels
    parameter SPRITE_SIZE = 32;

    // States for drawing and erasing the chef
    parameter IDLE = 2'b00;
    parameter ERASE = 2'b01;
    parameter DRAW = 2'b10;
    parameter CLEAR = 2'b11;   // repaint the whole background after reset

    reg [1:0] state;

    // Tracks which pixel of the 32x32 image we are drawing
    reg [9:0] pixel_count;

    // Stores the previous position of the chef
    reg [8:0] old_x;
    reg [7:0] old_y;

    // Stores the position we are currently drawing
    reg [8:0] target_x;
    reg [7:0] target_y;

    // Tells us whether the chef has already been drawn
    reg sprite_drawn;

    // Screen position while clearing the whole background
    reg [8:0] clear_x;
    reg [7:0] clear_y;

    // Memories containing the chef image and transparency
    (* ram_init_file = "assets/chef_sprite.mif" *)
    reg [5:0] sprite_memory [0:1023];

    (* ram_init_file = "assets/chef_mask.mif" *)
    reg mask_memory [0:1023];

    // Copy of the kitchen image, used to erase the old sprite
    (* ram_init_file = "assets/kitchen_background.mif" *)
    reg [5:0] background_memory [0:76799];

    reg [5:0] sprite_pixel;
    reg mask_pixel;
    reg [5:0] background_pixel;

    // Choose whether to use the old position or new position
    wire [8:0] base_x;
    wire [7:0] base_y;

    assign base_x = (state == ERASE) ? old_x : target_x;
    assign base_y = (state == ERASE) ? old_y : target_y;

    // Calculate the location of the current pixel on the screen
    wire [9:0] current_x;
    wire [8:0] current_y;

    // While clearing, sweep every pixel of the screen instead
    assign current_x = (state == CLEAR) ? {1'b0, clear_x} :
                       {1'b0, base_x} + {5'b0, pixel_count[4:0]};
    assign current_y = (state == CLEAR) ? {1'b0, clear_y} :
                       {1'b0, base_y} + {4'b0, pixel_count[9:5]};

    // Check that the pixel is inside the 320x240 screen
    wire pixel_on_screen;

    assign pixel_on_screen =
        (current_x < 320) && (current_y < 240);

    // Convert the screen position into a background memory address
    wire [16:0] background_address;

    assign background_address = pixel_on_screen ?
        (current_y * 320 + current_x) : 17'd0;

    // Read the colour and transparency values from memory
    // These memories return their data on the next clock cycle
    always @(posedge CLOCK_50) begin
        sprite_pixel <= sprite_memory[pixel_count];
        mask_pixel <= mask_memory[pixel_count];
        background_pixel <= background_memory[background_address];
    end

    // Delay the pixel coordinates to match the memory outputs
    reg [8:0] pixel_x_reg;
    reg [7:0] pixel_y_reg;
    reg pixel_valid_reg;
    reg drawing_reg;

    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            pixel_x_reg <= 0;
            pixel_y_reg <= 0;
            pixel_valid_reg <= 0;
            drawing_reg <= 0;
        end
        else begin
            pixel_x_reg <= current_x[8:0];
            pixel_y_reg <= current_y[7:0];

            // Only output pixels while drawing, erasing, or clearing
            pixel_valid_reg <=
                (state == ERASE || state == DRAW || state == CLEAR) && pixel_on_screen;

            drawing_reg <= (state == DRAW);
        end
    end

    // Send the correct pixel data to the VGA adapter
    assign VGA_x = pixel_x_reg;
    assign VGA_y = pixel_y_reg;

    // When drawing, use the chef colour
    // When erasing, restore the kitchen colour
    assign VGA_color = drawing_reg ? sprite_pixel : background_pixel;

    // Transparent chef pixels should not overwrite the background
    assign VGA_write = pixel_valid_reg &&
                       (!drawing_reg || mask_pixel);

    // Control when to draw and erase the chef
    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            state <= CLEAR;            // repaint the background first
            pixel_count <= 0;
            clear_x <= 0;
            clear_y <= 0;

            old_x <= 0;
            old_y <= 0;
            target_x <= 0;
            target_y <= 0;

            sprite_drawn <= 0;
        end
        else begin
            if (state == IDLE) begin
                pixel_count <= 0;

                // First time: draw the chef at its starting position
                if (!sprite_drawn) begin
                    target_x <= player_x;
                    target_y <= player_y;
                    state <= DRAW;
                end

                // If the position changes, erase the old chef first
                else if (player_x != old_x || player_y != old_y) begin
                    target_x <= player_x;
                    target_y <= player_y;
                    state <= ERASE;
                end
            end

            else if (state == ERASE) begin
                if (pixel_count == 1023) begin
                    pixel_count <= 0;
                    state <= DRAW;
                end
                else begin
                    pixel_count <= pixel_count + 1'b1;
                end
            end

            else if (state == DRAW) begin
                if (pixel_count == 1023) begin
                    pixel_count <= 0;

                    // Remember the chef's new position
                    old_x <= target_x;
                    old_y <= target_y;
                    sprite_drawn <= 1;

                    state <= IDLE;
                end
                else begin
                    pixel_count <= pixel_count + 1'b1;
                end
            end

            // Repaint every pixel from background_memory, row by row
            else if (state == CLEAR) begin
                if (clear_x == 9'd319) begin
                    clear_x <= 0;
                    if (clear_y == 8'd239)
                        state <= IDLE;     // done; IDLE then draws the chef
                    else
                        clear_y <= clear_y + 1'b1;
                end
                else begin
                    clear_x <= clear_x + 1'b1;
                end
            end
        end
    end

endmodule
