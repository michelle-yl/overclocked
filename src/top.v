
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
    wire idle;                  // 1 when chef is standing still on a tile

    // NEW: Milestone 2 - Stations and interactions
    wire space;                 // one-clock Space press, on a gametick
    wire [2:0] station;         // station next to the chef (defs.vh codes)
    wire [2:0] held;            // item in the chef's hands (defs.vh codes)
    wire [2:0] plate;           // {lettuce, meat, bun} on the assembly plate
    wire serve;                 // one-clock pulse: check the plate
    wire done;                  // order_verify has answered

    // NEW: Milestone 2 - Stove
    wire [1:0] stove_state;     // EMPTY, COOKING, COOKED, BURNT
    wire [3:0] stove_progress;  // 0-15 through the current cook or burn
    wire [2:0] stove_give;      // what the chef holds after using the stove

    // Game timer digits (BCD)
    wire [3:0] t_min, t_tens, t_ones;
    wire timeup;                // 1 when timer reaches 0:00

    // NEW: Overclock heat
    wire boost;                 // overclock active (from heat FSM), speeds up gametick
    wire [4:0] heat;            // 0-31
    wire heat_warn;             // heat is 24 or more
    wire meltdown;              // one-clock pulse when heat reaches 31
    wire playing;               // game still running (not time up, not melted)

    // NEW: Milestone 2 - Order management
    wire [1:0] order_id;        // Current burger recipe (0-3)
    wire [2:0] required_ingredients;
    wire [15:0] lfsr_q;         // free-running pseudo-random value

    // NEW: Milestone 2 - Verification and scoring
    wire correct_order;
    wire incorrect_order;
    wire [11:0] score;          // BCD: {hundreds, tens, ones}

    // Shared station / held / stove codes (STOVE is used below)
    `include "defs.vh"

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

    // Game tick (60/90 Hz) and one-second tick.
    // Speed comes from the heat FSM, not the raw key, so heat can cut it off.
    tickgen ticks (
        .clk(CLOCK_50),
        .clr(resetn),
        .overclk(boost),
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
        .tiley(tiley),
        .idle(idle)
    );

    // ---------------- Game timer ----------------

    // 2:00 countdown game timer.
    // Stops counting after a meltdown, so HEX shows the time left.
    timer gtimer (
        .clk(CLOCK_50),
        .clr(resetn),
        .tick1s(tick1s & playing),
        .min(t_min),
        .tens(t_tens),
        .ones(t_ones),
        .timeup(timeup)
    );

    // ---------------- Overclock heat ----------------

    // temp until game_fsm
    reg melted;

    always @(posedge CLOCK_50) begin
        if (!resetn)
            melted <= 0;
        else if (meltdown)
            melted <= 1;
    end

    assign playing = !timeup && !melted;

    // Overclock FSM and heat counter.
    // Heat +4 per second while boosting, -2 per second otherwise.
    trackheat heater (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick1s(tick1s),
        .key(overclock),
        .inplay(playing),
        .overclk(boost),
        .heat(heat),
        .warning(heat_warn),
        .meltdown(meltdown)
    );

    // ---------------- Milestone 2: Space press ----------------

    // Turn the held Space level into one press per keydown,
    // delivered on the next gametick, and none once the game is over.
    ctrlinput spacepress (
        .clk(CLOCK_50),
        .resetn(resetn),
        .interact(interact),
        .gametick(gametick),
        .timeup(!playing),
        .space(space)
    );

    // ---------------- Milestone 2: Stations ----------------

    // Which station the chef is standing at (NONE while mid-step)
    stations stationfind (
        .tilex(tilex),
        .tiley(tiley),
        .idle(idle),
        .station(station)
    );

    // ---------------- Milestone 2: Interactions ----------------

    // Held item and plate. Crates, plate, and trash rules live here;
    // the stove's rules live in the stove module (stove_give).
    assign done = correct_order | incorrect_order;

    interactions kitchen (
        .clk(CLOCK_50),
        .resetn(resetn),
        .space(space),
        .station(station),
        .stove(stove_give),
        .done(done),
        .held(held),
        .plate(plate),
        .serve(serve)
    );

    // ---------------- Milestone 2: Stove ----------------

    // Cooks on gametick, so overclock speeds it up.
    // Only sees presses made while standing at the stove.
    stove cooker (
        .clk(CLOCK_50),
        .resetn(resetn),
        .gametick(gametick),
        .space(space && station == STOVE),
        .held(held),
        .state(stove_state),
        .progress(stove_progress),
        .give(stove_give)
    );

    // ---------------- Milestone 2: Order management ----------------

    // Select the current burger recipe.
    // Pick a new random recipe on reset and after a correct submission.
    //
    // Recipe 0: 111 = bun + meat + lettuce
    // Recipe 1: 101 = bun + lettuce
    // Recipe 2: 011 = bun + meat
    // Recipe 3: 110 = meat + lettuce

    // Free-running random source. Never reset, so the moment the
    // player resets or serves decides which value gets picked.
    lfsr16b rng (
        .clk(CLOCK_50),
        .q(lfsr_q)
    );

    order_manager orders (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .correct_order(correct_order),
        .randorder(lfsr_q[1:0]),        // next recipe, picked at random
        .order_id(order_id),
        .required_ingredients(required_ingredients)
    );

    // ---------------- Milestone 2: Order verification ----------------

    // Compare the plate to the ingredients required by the
    // current order when the chef serves.

    order_verify verification (
        .CLOCK_50(CLOCK_50),
        .resetn(resetn),
        .submit(serve),                     // already blocked after 0:00 by "space"
        .submitted_ingredients(plate),
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
        .heat_level({heat, 1'b0}),  // heat 0-31 doubled for the 64 px bar

        // Item display: held item, stove patty, plate contents
        .held(held),
        .stove_state(stove_state),
        .plate(plate)
    );

    // ---------------- HEX displays ----------------

    // HEX5-3: score, BCD so it reads in decimal (e.g. 120)
    // HEX2-0: game timer (m ss)
    //         SW[9] = 1 swaps in debug: plate bits, stove progress, held item

    wire [3:0] hex5_value = score[11:8];
    wire [3:0] hex4_value = score[7:4];
    wire [3:0] hex3_value = score[3:0];

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

    wire [3:0] hex2_value = SW[9] ? {1'b0, plate}  : t_min;
    wire [3:0] hex1_value = SW[9] ? stove_progress : t_tens;
    wire [3:0] hex0_value = SW[9] ? {1'b0, held}   : t_ones;

    hex7seg hx2 (
        .in(hex2_value),
        .out(HEX2)
    );

    hex7seg hx1 (
        .in(hex1_value),
        .out(HEX1)
    );

    hex7seg hx0 (
        .in(hex0_value),
        .out(HEX0)
    );

    // ---------------- LEDs ----------------

    // NEW: Milestone 2 - kitchen debugging LEDs
    // LEDR[2:0] = held item (defs.vh: 0 empty, 1 bun, 2 lettuce,
    //             3 raw, 4 cooked, 5 burnt)
    // LEDR[4:3] = stove state (0 empty, 1 cooking, 2 cooked, 3 burnt)
    // LEDR[5]   = overclock active (boost)
    // LEDR[6]   = meltdown happened (stays on until reset)
    // LEDR[9]   = heat warning (24+); stays on after a meltdown since heat stays 31
    assign LEDR[2:0] = held;
    assign LEDR[4:3] = stove_state;
    assign LEDR[5] = boost;

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

    assign LEDR[6] = melted;
    assign LEDR[7] = last_incorrect;
    assign LEDR[8] = last_correct;
    assign LEDR[9] = heat_warn;

endmodule
