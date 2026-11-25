// Shared codes for Overclocked.
// `include this file INSIDE a module body so the parameters belong to that module.
// Every module that compares stations, held items, or stove states must use these,
// so the numbers can never disagree between files.

// Station the chef is standing at (from stations.v)
parameter NONE = 3'd0, BUN = 3'd1, LETTUCE = 3'd2, PATTY = 3'd3,
          STOVE = 3'd4, PLATE = 3'd5, TRASH = 3'd6;

// Item in the chef's hands
parameter H_EMPTY = 3'd0, H_BUN = 3'd1, H_LETTUCE = 3'd2,
          H_RAW = 3'd3, H_COOKED = 3'd4, H_BURNT = 3'd5;

// Stove state
parameter S_EMPTY = 2'd0, S_COOKING = 2'd1, S_COOKED = 2'd2, S_BURNT = 2'd3;
