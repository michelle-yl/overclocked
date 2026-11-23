
module heat_bar(
    input wire CLOCK_50,
    input wire resetn,

    // Heat value supplied by the cooking logic (0 to 63)
    input wire [5:0] heat_level,

    // The chef renderer gets priority over heat graphics
    input wire chef_busy,
    input wire enable,

    // Pixel information sent to the VGA adapter
    output reg [8:0] VGA_x,
    output reg [7:0] VGA_y,
    output reg [5:0] VGA_color,
    output wire VGA_write
);

    // The heat bar is 64 pixels wide and 8 pixels tall
    // It is positioned below the burger order display
    parameter BAR_X = 224;
    parameter BAR_Y = 32;

    // Track the 512 pixels in the heat bar
    reg [8:0] pixel_count;

    // Remember the heat value being displayed
    reg [5:0] displayed_heat;

    // Indicates whether the bar needs to be drawn
    reg drawing;

    // Remember if the chef was previously drawing
    reg previous_chef_busy;

    // Position inside the heat bar
    wire [5:0] column;
    wire [2:0] row;

    assign column = pixel_count[5:0];
    assign row = pixel_count[8:6];

    // Control when the heat bar is drawn
    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            pixel_count <= 0;
            displayed_heat <= 0;
            drawing <= 1;
            previous_chef_busy <= 0;
        end
        else begin
            previous_chef_busy <= chef_busy;

            // Redraw whenever the heat value changes
            if (heat_level != displayed_heat) begin
                displayed_heat <= heat_level;
                pixel_count <= 0;
                drawing <= 1;
            end

            // Redraw after the chef finishes clearing or drawing
            else if (!chef_busy && previous_chef_busy) begin
                pixel_count <= 0;
                drawing <= 1;
            end

            // Draw one pixel whenever VGA is available
            else if (drawing && enable) begin
                if (pixel_count == 9'd511) begin
                    pixel_count <= 0;
                    drawing <= 0;
                end
                else begin
                    pixel_count <= pixel_count + 1'b1;
                end
            end
        end
    end

    // Calculate the pixel location and colour
    always @(*) begin
        VGA_x = BAR_X + {3'b000, column};
        VGA_y = BAR_Y + {5'b00000, row};

        // Dark grey represents the empty part of the bar
        VGA_color = 6'b010101;

        // Fill the bar up to the current heat value
        if (column < displayed_heat) begin

            // Low heat: green
            if (displayed_heat <= 6'd20)
                VGA_color = 6'b001100;

            // Medium heat: yellow
            else if (displayed_heat <= 6'd42)
                VGA_color = 6'b111100;

            // High heat: red
            else
                VGA_color = 6'b110000;
        end
    end

    // Write only when this renderer has permission
    // Also wait until the current heat value is captured
    assign VGA_write = drawing && enable && resetn &&
                       (heat_level == displayed_heat);

endmodule
