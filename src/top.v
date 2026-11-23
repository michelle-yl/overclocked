
module top (
    CLOCK_50, SW, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
    VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N,
    VGA_CLK, PS2_CLK, PS2_DAT
);

    // ---------------- Ports ----------------

    input wire CLOCK_50;        // DE-series 50 MHz clock signal
    input wire [9:0] SW;        // DE-series switches
    input wire [3:0] KEY;       // Pushbuttons, KEY[0] = active-low reset

    input wire PS2_CLK;         // PS/2 keyboard
    input wire PS2_DAT;

    output wire [6:0] HEX0;
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;

    output wire [9:0] LEDR;

    output wire [7:0] VGA_R;
    output wire [7:0] VGA_G;
    output wire [7:0] VGA_B;
    output wire VGA_HS;
    output wire VGA_VS;
    output wire VGA_BLANK_N;
    output wire VGA_SYNC_N;
    output wire VGA_CLK;

    // ---------------- Internal signals ----------------

    // Keyboard to game
    wire move_up, move_down, move_left, move_right;
    wire interact;
    wire overclock;

    // Timing pulses
    wire gametick;              // 60 Hz, or 90 Hz while overclocking
    wire tick1s;                // 1 Hz, for the game timer

    // Chef position
    wire [8:0] chefx;           // Pixel x, 0-319
    wire [7:0] chefy;           // Pixel y, 0-239
    wire [4:0] tilex;           // Tile column
    wire [3:0] tiley;           // Tile row

    // Game timer digits (BCD)
    wire [3:0] t_min, t_tens, t_ones;
    wire timeup;                // 1 when timer reaches 0:00

    // NEW: Milestone 2 - Order management
    wire [1:0] order_id;        // Current burger recipe (0-3)
    wire [2:0] required_ingredients;

    // NEW: Milestone 2 - Verification and scoring
    wire correct_order;
    wire incorrect_order;
    wire [15:0] score;

    // ---------------- Reset ----------------

    // Registers start at 0 when the board is programmed.
    // Hold the design in reset for 15 clock cycles so modules
    // can load their starting values.
    // After startup, KEY[0] resets everything (active low).

    reg [3:0] startup_count = 4'd0;

    always @(posedge CLOCK_50) begin
        if (startup_count != 4'd15)
            startup_count <= startup_count + 1'b1;
    end

    wire resetn = KEY[0] & (startup_count == 4'd15);

    // ---------------- Keyboard ----------------

    // Read keyboard input and track which keys are held down
    keyboard_input keyboard (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .move_up(move_up),
        .move_down(move_down),
        .move_left(move_left),
        .move_right(move_right),
        .interact(interact),
        .overclock(overclock)
    );

    // ---------------- Game timing ----------------

    // Game tick (60/90 Hz) and one-second tick
    tickgen ticks (
        .clk(CLOCK_50),
        .clr(resetn),
        .overclk(overclock),
        .gametick(gametick),
        .tick1s(tick1s)
    );

    // ---------------- Chef movement ----------------

    // Chef movement on the 16 px tile grid
    movechef chef (
        .clk(CLOCK_50),
        .clr(resetn),
        .gametick(gametick),
        .up(move_up),
        .down(move_down),
        .left(move_left),
        .right(move_right),
        .chefx(chefx),
        .chefy(chefy),
        .tilex(tilex),
        .tiley(tiley)
    );

    // ---------------- Game timer ----------------

    // 2:00 countdown game timer
    timer gtimer (
        .clk(CLOCK_50),
        .clr(resetn),
        .tick1s(tick1s),
        .min(t_min),
        .tens(t_tens),
        .ones(t_ones),
        .timeup(timeup)
    );

    // ---------------- Milestone 2: Burger input ----------------

    // Temporary controls for testing burger submissions:
    //
    // SW[0] = bun
    // SW[1] = meat
    // SW[2] = lettuce
    //
    // KEY[1] = submit burger (active low)
    //
    // These controls can later be replaced by the actual
    // ingredient collection and cooking logic.

    // Synchronize the physical inputs to CLOCK_50
    reg submit_meta;
    reg submit_sync;

    reg [2:0] ingredients_meta;
    reg [2:0] ingredients_sync;

    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            submit_meta <= 0;
            submit_sync <= 0;

            ingredients_meta <= 0;
            ingredients_sync <= 0;
        end
        else begin
            // KEY is active low, so invert KEY[1]
            submit_meta <= ~KEY[1];
            submit_sync <= submit_meta;

            // Synchronize the three ingredient switches
            ingredients_meta <= SW[2:0];
            ingredients_sync <= ingredients_meta;
        end
    end

    // ---------------- Submit button debounce ----------------

    // Mechanical buttons can bounce when pressed.
    // Require the input to remain different for about 1 ms
    // before accepting the new button state.

    reg submit_debounced;
    reg [15:0] debounce_count;

    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            submit_debounced <= 0;
            debounce_count <= 0;
        end
        else if (submit_sync == submit_debounced) begin
            debounce_count <= 0;
        end
        else if (debounce_count == 16'd49999) begin
            submit_debounced <= submit_sync;
            debounce_count <= 0;
        end
        else begin
            debounce_count <= debounce_count + 1'b1;
        end
    end

    // ---------------- Milestone 2: Order management ----------------

    // Select the current burger recipe.
    // Advance to the next order after a correct submission.
    //
    // Recipe 0: 111 = bun + meat + lettuce
    // Recipe 1: 101 = bun + lettuce
    // Recipe 2: 011 = bun + meat
    // Recipe 3: 110 = meat + lettuce

    order_manager orders (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .order_id(order_id),
        .required_ingredients(required_ingredients)
    );

    // ---------------- Milestone 2: Order verification ----------------

    // Compare the player's submitted ingredients to the
    // ingredients required by the current order.
    // Do not accept submissions after the timer reaches zero.

    order_verify verification (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .submit(submit_debounced && !timeup),
        .submitted_ingredients(ingredients_sync),
        .required_ingredients(required_ingredients),
        .correct_order(correct_order),
        .incorrect_order(incorrect_order)
    );

    // ---------------- Milestone 2: Scoring ----------------

    // Add 10 points for every correctly completed burger.

    score_manager scoring (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .score(score)
    );

    // ---------------- VGA display ----------------

    // Kitchen background with chef and current order drawn on top.
    // The updated vga_background module handles which renderer
    // gets to send pixels to the VGA adapter.

    vga_background background (
        .CLOCK_50(CLOCK_50),
        .KEY({KEY[3:1], resetn}),
        .LEDR(),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK),

        //NEW:
        .player_x(chefx),
        .player_y(chefy),

        .order_id(order_id),
        .required_ingredients(required_ingredients),

        // NEW: Temporary heat value for testing the graphic
        .heat_level(SW[8:3]) //change to heat signal based on Michelle's heat bar code 
    );

    // ---------------- HEX displays ----------------

    // HEX5-3 normally show the game timer.
    //
    // When SW[9] = 1, they show the score instead.
    // The score is currently displayed in hexadecimal.

    wire [3:0] hex5_value;
    wire [3:0] hex4_value;
    wire [3:0] hex3_value;

    assign hex5_value = SW[9] ? score[11:8] : t_min;
    assign hex4_value = SW[9] ? score[7:4] : t_tens;
    assign hex3_value = SW[9] ? score[3:0] : t_ones;

    hex7seg hx5 (
        .in(hex5_value),
        .out(HEX5)
    );

    hex7seg hx4 (
        .in(hex4_value),
        .out(HEX4)
    );

    hex7seg hx3 (
        .in(hex3_value),
        .out(HEX3)
    );

    // HEX2: chef tile y
    // HEX1-0: chef tile x
    // Keep these for debugging movement.

    hex7seg hx2 (
        .in(tiley),
        .out(HEX2)
    );

    hex7seg hx1 (
        .in({3'b000, tilex[4]}),
        .out(HEX1)
    );

    hex7seg hx0 (
        .in(tilex[3:0]),
        .out(HEX0)
    );

    // ---------------- LEDs ----------------

    // Original keyboard debugging LEDs
    assign LEDR[0] = move_up;
    assign LEDR[1] = move_down;
    assign LEDR[2] = move_left;
    assign LEDR[3] = move_right;
    assign LEDR[4] = interact;
    assign LEDR[5] = overclock;

    // NEW: Milestone 2 - Remember the last submission result
    //
    // LEDR[8] = last burger was correct
    // LEDR[7] = last burger was incorrect
    // These LEDs keep their state until the next submission.

    reg last_correct;
    reg last_incorrect;

    always @(posedge CLOCK_50) begin
        if (!resetn) begin
            last_correct <= 0;
            last_incorrect <= 0;
        end
        else if (correct_order) begin
            last_correct <= 1;
            last_incorrect <= 0;
        end
        else if (incorrect_order) begin
            last_correct <= 0;
            last_incorrect <= 1;
        end
    end

    assign LEDR[6] = 1'b0;
    assign LEDR[7] = last_incorrect;
    assign LEDR[8] = last_correct;
    assign LEDR[9] = timeup;

endmodule
