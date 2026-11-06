# Overclocked: Project Plan

A single-player kitchen game on the DE1-SoC, inspired by Overcooked. Its main twist is an overclock key: the player can run the whole kitchen 1.5× faster, but the heat this builds ends the game if it reaches the limit.

This is version 2 of the plan, and Section 3.8 describes the new mechanic. [PLAN.md](PLAN.md) is the original without overclock.

Course: ECE241H1 F, Digital Systems. Target board: DE1-SoC (Cyclone V, `5CSEMA5F31C6`).

Reference files in this folder: the project spec and VGA Adapter page (`.html`), and the Memory Blocks lab (`mem_lab_Verilog.pdf`).

## Contents

1. [Read this first](#1-read-this-first)
2. [Spec requirements](#2-spec-requirements-and-how-the-plan-meets-them)
3. [Game design](#3-game-design)
4. [System architecture](#4-system-architecture)
5. [Video design](#5-video-design)
6. [Interfaces and module list](#6-interfaces-and-module-list)
7. [Input and movement design](#7-input-and-movement-design)
8. [Schedule and milestones](#8-schedule-and-milestones)
9. [Division of work](#9-division-of-work)
10. [Verification](#10-verification)
11. [Concepts](#11-concepts)
12. [Components and deliverables](#12-components-and-deliverables)
13. [Proposal draft](#13-proposal-draft)
14. [Risks](#14-risks)

---

## 1. Read this first

**The proposal is due at midnight on Friday, November 6.** Section 13 has the required content in draft form. It still needs your names, your edits, and a redrawn block diagram.

**Write the Verilog yourselves.** The spec says your grade depends heavily on explaining your code, and the TA will question you on it. For that reason this plan defines behaviour, interfaces, and tests, and contains no RTL. Check the syllabus AI policy to see how it treats AI help with planning too, since I only have the project page's summary of it.

**Things I could not confirm:**

| Item | Why it matters | Action |
|---|---|---|
| VGA adapter ports | The VGA Adapter page confirms 320×240, 9-bit colour, and an on-chip video memory, but the Verilog is in `vga_adapter.zip`, which I don't have. The plan assumes `(x, y, colour, plot)` pixel writes, up to one every few clocks. | Check `vga_demo.v` in the `object` or `animate` example this week. |
| PS/2 interface | I confirmed the core exists on the DE1-SoC IP cores page, but its one-clock data-valid signal is from memory. | Check the core's PDF and the `object` example, which already reads a PS/2 keyboard. |
| Lab 5 | The spec refers to it, but only labs 1 to 4 are in this directory. | FSMs and sequence detectors are lecture material, so the plan uses them freely (Section 11.2). If Lab 5 has reusable FSM code, start from it. |
| Team | The spec bans groups of 1. I don't have your partner's name. | Replace "Member A/B" in Sections 9 and 13. |

---

## 2. Spec requirements and how the plan meets them

| Requirement | How it is met | Section |
|---|---|---|
| At least 3 labs of work (Lab 5 × 3) | Three blocks: video, input and movement, game logic | 4, 9 |
| Most functionality on the FPGA | Everything runs on the FPGA. Python is only an offline asset converter. | 4 |
| Builds on lecture and lab material | Counters, registers, BCD, muxes, and 7-segment decoders are reused directly | 11 |
| Own work, others' code cited | Only the VGA adapter and PS/2 core are external. They count as "less work", so the plan's scope sits in your own modules on top of them. | 6.3 |
| Team of 2, at least 1.5 labs each, both working every milestone | Split by module with work in every phase | 9 |
| Proposal: summary, block diagram, schedule, division of work, 1 page, 11 pt or larger | Draft provided | 13 |
| M1 (Week 10): part working on board, plus simulations | Kitchen on VGA, chef moved by keyboard, with collision | 8 |
| M2 (Week 11): most of it on board, plus simulations of internals | Full cooking loop with score and timer | 8 |
| Milestone PDF: who did what, code, explanation, ModelSim | Testbench per module, PDF checklist | 10, 12 |
| Presentation: 10 minutes, equal speaking time, detailed slides | Slide checklist | 12 |
| Something must work by the presentation | Ordered fallback tiers | 8.1 |

---

## 3. Game design

### 3.1 Player experience

The player has 2 minutes to complete as many food orders as possible. Orders appear in up to 3 ticket slots, each with a patience bar. The player grabs ingredients, chops or cooks them, assembles them on a plate, and delivers the plate to the serving hatch. Food left on the stove too long burns.

The player can hold the overclock key to speed up the whole kitchen, including burning. Boosting builds heat, and if heat reaches its limit the game ends in a meltdown.

### 3.2 Changes to your feature table

| Feature | Your idea | Plan | Reason |
|---|---|---|---|
| Movement | Arrow keys, X/Y registers | Same, but locked to the tile grid with smooth 2 px steps | Collision becomes one tile lookup instead of box overlap maths |
| Pickup | Space near a station | Space acts on the tile the chef **faces** | "Near" is ambiguous when two stations are close. Facing needs only a direction register. |
| Chopping | Wait 3 s | **Hold Space** at the board for about 3 s; the timer pauses if you let go or leave | Chopping ties up the player while the stove runs, which is what makes burning a real threat |
| Cooking | Wait 5 s | Runs in the background, about 5 s | Same as yours |
| Burning | 5 s later | Same; a burnt patty must go in the trash | Adds a recovery action |
| Orders | ROM + order register | ROM holds a 4-bit ingredient mask per recipe; 3 slots; a random generator picks recipes | A delivery check becomes one equality comparison |
| Patience | 25 s | Same as the default, stored per recipe in the ROM | Lets you tune hard recipes without changing logic |
| Scoring | +100 | Same, stored directly in BCD | HUD and HEX digits need no binary-to-decimal conversion |
| Game timer | 2 minutes | Same, as a BCD m:ss down-counter | Direct extension of Lab 4 |
| Game over | Show score | Title, Play, Time Up, and Meltdown screens | Needed for a restartable demo, and shows why the game ended |
| Overclock | None | Hold a key to run the kitchen at 1.5× speed; full heat ends the game (Section 3.8) | Sets the game apart from Overcooked and gives the title a meaning |

### 3.3 Timing constants

All are parameters, so playtesting can change them. Chop, cook, and burn run as 16 progress steps so the 4-bit count is directly the width of a 16 px bar, which avoids a multiplier.

| Constant | Value | Actual time |
|---|---|---|
| Game tick | 60 Hz | 833,333 clocks |
| Game tick, boosted | 90 Hz | 555,556 clocks |
| Chef speed | 2 px per tick | 8 ticks per tile, 7.5 tiles/s |
| Chop | 16 steps × 11 ticks | 2.93 s |
| Cook | 16 steps × 19 ticks | 5.07 s |
| Burn | 16 steps × 19 ticks | 5.07 s |
| Order patience | 25 s | 25 s |
| Spawn interval | 12 s, if a slot is free | 12 s |
| Game length | 120 s | 120 s |
| Heat rise while boosting | +1 every 0.25 s | 7.75 s from 0 to 31 |
| Heat fall otherwise | −1 every 0.5 s | 15.5 s from 31 to 0 |
| Heat warning | 24 of 31 | About 1.75 s of boost left |

The chop and cook times are slightly off 3 s and 5 s because the step count has to be a whole number of ticks. This difference isn't noticeable in play. Chef, chop, cook, and burn values are for normal speed; Section 3.8 lists the boosted times.

### 3.4 Recipes

Each plate is a 4-bit mask, `{patty, tomato, lettuce, bun}`.

| ID | Recipe | Mask | Prep work |
|---|---|---|---|
| 0 | Salad | `0110` | Chop lettuce, chop tomato |
| 1 | Burger | `1001` | Cook patty, take bun |
| 2 | Lettuce burger | `1011` | Cook patty, chop lettuce, take bun |
| 3 | Deluxe burger | `1111` | Cook patty, chop both, take bun |

A rough estimate for the Deluxe is 18 to 19 s with the patty cooking in the background, so 25 s is achievable but tight. With 3 slots and a 12 s spawn interval, the player will probably miss some orders. That is the intended pressure, but tune it during Week 11 playtesting.

### 3.5 Items held by the chef

`held_item` is a 4-bit enum. `held_mask` is a separate 4-bit register, used only when the chef holds a plate.

| Code | Item | Code | Item |
|---|---|---|---|
| 0 | Empty | 5 | Tomato, chopped |
| 1 | Bun | 6 | Patty, raw |
| 2 | Lettuce, raw | 7 | Patty, cooked |
| 3 | Lettuce, chopped | 8 | Patty, burnt |
| 4 | Tomato, raw | 9 | Plate |

### 3.6 Interaction table

This table is the core of the game logic. It should become a single combinational decoder, tested row by row. Any combination not listed does nothing.

| Facing | Holding | Condition | Result |
|---|---|---|---|
| Crate (bun, lettuce, tomato, patty) | Empty | | Holding = that ingredient |
| Board | Lettuce or tomato, raw | Board empty | Item moves to board |
| Board | Empty | Raw item on board, Space **held** | Chop progress advances |
| Board | Empty | Chopped item on board | Item moves to chef |
| Stove | Patty, raw | Stove empty | Starts cooking |
| Stove | Empty | Cooked or burnt | Patty moves to chef, stove resets |
| Assembly | Bun, chopped veg, or cooked patty | That mask bit is clear | Sets bit, hands empty |
| Assembly | Empty | Mask not zero | Holding = plate, `held_mask` = mask, assembly cleared |
| Trash | Anything | | Hands empty, `held_mask` cleared |
| Hatch | Plate | `held_mask` matches an active slot | Slot cleared, score +100, hands empty |
| Hatch | Plate | No match | Nothing happens; flash an LED |

If two slots match, the lowest-numbered slot wins.

### 3.7 Screen layout

The screen is 320×240, made of 16×16 tiles, giving a grid of 20×15.

```
r0-1   HUD: time m:ss, score, heat bar
r2     ####################
r3     ##B#L#T#P###C###S###
r4     #..................#
r5     #..................#
r6     #..................#
r7     #.....####A###.....#
r8     #..................#
r9     #..................#
r10    #..................#
r11    ###X########H#######
r12-14 Three order tickets: recipe icon + patience bar
```

Key: `#` solid counter or wall, `.` floor, `B` bun, `L` lettuce, `T` tomato, `P` patty, `C` chopping board, `S` stove, `A` assembly, `X` trash, `H` hatch.

### 3.8 Overclock

Holding the overclock key (`Z`) raises the game tick from 60 to 90 Hz, so the whole kitchen runs at 1.5× speed. Everything driven by `game_tick` speeds up, including burning. The game timer, order patience, and order spawns stay on real time, so boosting gets more work done before orders expire.

| Action | Normal, 60 Hz | Boosted, 90 Hz |
|---|---|---|
| Chef speed | 7.5 tiles/s | 11.25 tiles/s |
| Chop | 2.93 s | 1.96 s |
| Cook | 5.07 s | 3.38 s |
| Burn | 5.07 s | 3.38 s |

**Heat.** `heat` is a 5-bit saturating up/down counter, from 0 to 31, updated on real-time pulses so its rate never depends on the game tick.

- **Boosting:** +1 on every `tick_4hz` pulse, so 0 to 31 takes 7.75 s.
- **Not boosting:** −1 on every second `tick_4hz` pulse, stopping at 0, so 31 to 0 takes 15.5 s.
- **Warning, 24 or more:** the heat bar flashes and `LEDR[9]` blinks, with about 1.75 s of boost left. The check is only `heat[4:3] == 2'b11`.
- **Meltdown, 31:** the game ends at once. The score stands, and the Meltdown screen replaces the Time Up screen.

**Control.** `heat_ctrl` is a two-state Moore FSM, `NORMAL` and `BOOST`, plus the heat counter. It enters `BOOST` while the key is held during play and returns to `NORMAL` on release. Its `boost` output selects the divider count in `tick_gen`, and its one-cycle `meltdown` pulse moves `game_fsm` to the Meltdown state.

**Balance.** Heat rises twice as fast as it falls, so a player can boost about a third of the time. Over a full game the limit is about 45 s of boost, worth about 22 s of extra kitchen time. Tune these rates in playtesting so that short bursts feel safe and worthwhile.

**Edge cases:**

- The key does nothing outside play, and restarting clears `heat`.
- If meltdown and 0:00 land on the same clock, Time Up wins.
- `tick_gen` applies a new period only when its counter wraps. Changing the limit mid-count could leave the counter above the new limit, so it would miss the match and run on.
- `game_tick` and `tick_1s` are no longer aligned, so a serve and an expiry can hit the same slot on the same clock. The serve wins.

---

## 4. System architecture

```
                         +-------------------- CLOCK_50 (everything) ------------------+
                         |                                                             |
 PS/2 keyboard           v                                                             v
 ---------> [PS/2 core*] -> [kbd_decoder] -> [input_ctrl] -> [chef_move] <-> [map_rom A]
                                                 ^               |
 KEY/SW (backup) --------------------------------+               | tile x/y, facing
                                                                 v
 [tick_gen] ticks ----------> all game blocks          [interact_decoder] <-> [map_rom A]
                                                         |    |     |
                                       +-----------------+    |     +---------------+
                                       v                      v                     v
                                  [board_fsm]            [stove_fsm]         [order_mgr] <- [lfsr]
                                  [assembly reg]         held_item reg       [recipe_rom]
                                       |                      |                     |
                                       |                      |               [score_bcd]
                                       |    [game_fsm] <-> [game_timer]             |
                                       v          v           v                     v
                                  +---------- game state bus (Section 6.1) ----------+
                                                  |
                                                  v
                                      [renderer FSM] <-> [map_rom B], [tile_rom]
                                                  |
                                     x, y, colour, plot
                                                  v
                                           [VGA adapter*] ---> VGA monitor
                                                  
                        score, time, debug ---> HEX0-5, LEDR

 * = provided IP, must be cited
```

The overclock path connects to the blocks above like this:

```
 overclock key -> [input_ctrl] -> [heat_ctrl] -- boost --> [tick_gen] -> game_tick, 60 or 90 Hz
                                       ^   |
                 tick_4hz, playing ----+   +-- heat, heat_warn --> HUD, LEDR
                                           +-- meltdown -------> [game_fsm]
```

Four design rules keep this manageable, and they are worth stating on your slides.

1. **One clock.** Everything runs on `CLOCK_50`. Slow events are one-cycle enable pulses, the same way `onesec` works in `lab4/part3.v`.
2. **Game-speed state changes only on `game_tick`.** Chef movement, stations, and interactions advance on this pulse, at 60 or 90 Hz. Real-time state (game timer, patience, spawns, and heat) advances on the fixed `tick_1s` and `tick_4hz` pulses, so overclock can't stretch it. Key presses are latched until the next `game_tick`, so the game runs in deterministic steps and is easy to simulate.
3. **The renderer only reads game state.** It never changes it, so the two halves can be built in parallel against the bus in Section 6.1.
4. **Repaint every pixel, every frame.** There is no erase-and-redraw step (Section 5.2).

---

## 5. Video design

### 5.1 Resolution and memory

| Item | Size | Share of the chip |
|---|---|---|
| Framebuffer, 320×240 at 9-bit colour | 691,200 bits | About 17% of on-chip block memory, more if the adapter pads addresses |
| Tile ROM, 64 tiles × 256 px × 9 bits | 147,456 bits | About 4% |
| Map ROM, 2048 × 6 bits (4 screens of 512), two copies | 24,576 bits | Under 1% |

Each M10K block holds 10,240 bits. The memory lab says the chip has 446 blocks, but I recall Intel listing 397 for this device, so the percentages above use the lower number. Memory is comfortable either way, and the Quartus fitter report will show the true total.

**Adapter settings.** The `_pro` examples on the VGA Adapter page have parameters for 640×480, 320×240, or 160×120, and for 3, 6, or 9-bit colour. Start from one of those and set 320×240 at 9 bits. The basic examples are fixed at 640×480, which would need 2.76 Mbit of video memory, about 68% of the chip.

The adapter's background MIF must match the chosen resolution and colour depth, and the default `rainbow_640_9.mif` does not. Generate a plain 320×240, 9-bit image for it. The renderer overwrites this image on its first pass, so its content doesn't matter.

### 5.2 Renderer

Most student projects erase and redraw moving sprites, which requires tracking what was underneath. This design avoids that. For each pixel, the renderer works out the final colour from all layers and writes it once. Pixels that haven't changed are overwritten with the same value, so nothing flickers.

The time budget allows this:

$$
\frac{50{,}000{,}000\ \text{clocks/s}}{60\ \text{frames/s}} = 833{,}333\ \text{clocks per frame}
$$

$$
\frac{833{,}333}{320 \times 240} \approx 10.8\ \text{clocks per pixel}
$$

Allowing 8 clocks per pixel means a full repaint takes 614,400 clocks, or 12.3 ms of the 16.7 ms frame. So the renderer needs no pipelining: a simple multi-cycle FSM with one ROM read port is enough.

The renderer runs from the fixed `frame_60` pulse, not `game_tick`, so overclock doesn't change this budget. At 90 Hz, game state can change during a repaint, which could shift part of the chef by 2 px for one frame. If that is visible, copy `chef_px` and `chef_py` into registers at the start of each frame.

**Layers, back to front:**

1. Base tile from the map ROM, selected by screen (title, kitchen, time up, or meltdown)
2. Dynamic tile: item on a station, HUD digit, or ticket icon
3. Chef sprite
4. Item held by the chef
5. Solid colour bars: chop, cook, burn, patience, and heat

A reserved colour marks transparent pixels in layers 2 to 4.

**Per-pixel sequence:** set the map address, read the tile ID, read each layer from the tile ROM in turn, select the top non-transparent colour, then pulse `plot` and advance x and y. Budget one clock for each ROM read, because M10K inputs are always registered and data returns one cycle late. This is the most likely source of off-by-one image bugs, so simulate it first.

That one-clock figure requires the `q` output register to be off (Section 5.3). With it on, each read takes two clocks, and five reads per pixel would use up the whole budget.

**Avoid multipliers with bit slicing:**

- Tile coordinates are `x[8:4]` and `y[7:4]`. Position inside a tile is `x[3:0]` and `y[3:0]`.
- Map rows are padded to 32 entries, so the map address is `{screen, tile_y, tile_x}` with no multiply by 20.
- The tile ROM address is `{tile_id, y[3:0], x[3:0]}`.
- Chef hit test: `(x - chef_px) < 16` as an unsigned subtraction, likewise for y.
- The heat bar is 32 px wide at full scale, so `heat` is directly its width in pixels.

**Tile budget (at most 64):** about 12 kitchen, 9 items, 10 digits, 18 font letters, 8 chef sprites (4 directions × 2 walk frames), and 1 heat icon gives about 58. The extra letters cover TIME UP and MELTDOWN. The plate's contents can be drawn as four small coloured dots, one per mask bit, which avoids 16 plate tiles.

### 5.3 ROM creation

Draw tiles as PNGs and convert them to `.mif` files with a small Python script, which also generates the map ROMs. Then build each ROM with the IP Catalog, following Part I of `mem_lab_Verilog.pdf`. That lab builds a RAM; a ROM uses the matching **ROM: 1-PORT** entry in the same category. The VGA page's `object` example stores sprites in on-chip ROM the same way, so read it first.

The course's `bmp_to_mif` tool (`MIF_c.zip`) converts 24-bit BMPs to MIF. Use it for the background image in Section 5.1, and compare its output with your script's to confirm the 9-bit colour format.

| Wizard setting | Choice | Reason |
|---|---|---|
| Category | Basic Functions > On Chip Memory | Same place as the lab's RAM |
| Width and depth | Tile ROM 9 × 16384, map ROM 6 × 2048 | Section 5.1 |
| `q` output port registered | **Off** | Gives the one-clock read the renderer budget needs |
| Memory initialization | Your `.mif` file | Loads the art and maps |
| Output files | Only the `.v` variation file | As in the lab |

**Simulation.** ModelSim only initializes the ROM if the `.mif` is in its working folder. The lab's `testbench.tcl` handles this with copy commands, and DESim's `run_compile.bat` does the same. Those setup files aren't in this directory, so get them from the lab or add your own copy step to each ROM testbench. The simulation also needs the `altera_mf` library.

**Don't use the lab's Part III method for ROMs.** An inferred array with `/* synthesis ram_init_file = ... */` works in Quartus, but ModelSim ignores that comment and leaves the memory uninitialized. The lab's workaround is writing each location from the testbench, which isn't practical for a ROM of 16,384 words.

**Fallback.** If IP ROM simulation gives trouble, an inferred ROM initialized with `$readmemh` works in both tools. The lab doesn't cover it, so you would need a hex output from the script and a check that Quartus still places it in M10K.

Check in the Quartus compile report that the ROMs landed in M10K blocks and not in logic.

---

## 6. Interfaces and module list

### 6.1 Game state bus

Agree on this in Week 8, since it lets both members work independently. A stub `game_state` that drives constant values lets the renderer be developed before the game logic exists.

| Signal | Width | Meaning |
|---|---|---|
| `screen` | 2 | Title, kitchen, time up, or meltdown |
| `chef_px`, `chef_py` | 9, 8 | Chef pixel position |
| `chef_dir` | 2 | Facing direction |
| `held_item`, `held_mask` | 4, 4 | What the chef holds |
| `board_item`, `board_progress` | 4, 4 | Board contents and bar width |
| `stove_state`, `stove_progress` | 2, 4 | Empty, cooking, cooked, or burnt, and bar width |
| `assembly_mask` | 4 | Plate being assembled |
| `slot_active[2:0]` | 3 | Which order slots are live |
| `slot_recipe[0..2]` | 2 each | Recipe in each slot |
| `slot_patience[0..2]` | 5 each | Seconds left; also the bar width in px |
| `score_bcd` | 16 | Four BCD digits |
| `time_bcd` | 12 | m:ss |
| `heat` | 5 | Heat level; also the bar width in px |
| `boost`, `heat_warn` | 1, 1 | Overclock active; heat at 24 or more |

Verilog-2001 can't pass arrays through ports, so pack the slot signals into flat vectors.

### 6.2 Your own modules

| Module | Purpose | Type | Owner |
|---|---|---|---|
| `overclocked_top` | Pin-level top, wiring | Structural | Both |
| `tick_gen` | `game_tick` (60 or 90 Hz), `frame_60`, `tick_1s`, and `tick_4hz` enable pulses | Counters | B |
| `kbd_decoder` | Scan bytes to held-key flags | Sequence detector FSM | B |
| `input_ctrl` | Synchronize KEY/SW, keyboard or KEY/SW select, press edges, latch until tick | Registers | B |
| `chef_move` | Position, direction, tile-step logic | FSM + datapath | B |
| `interact_decoder` | Section 3.6 table | Combinational | B |
| `kitchen_state` | `held_item`, `held_mask`, and `assembly_mask` registers | Registers | B |
| `progress_timer` | Reusable prescaler + 4-bit step counter | Counter | B |
| `board_fsm` | Empty, raw, chopped | FSM | B |
| `stove_fsm` | Empty, cooking, cooked, burnt | FSM | B |
| `game_fsm` | Title, play, time up, meltdown | FSM | B |
| `game_timer` | BCD m:ss down-counter | Counters | B |
| `renderer` | Pixel loop and layer compositor | FSM + datapath | A |
| `map_rom`, `tile_rom` | Layouts and art | Memory | A |
| `hud_mux` | Digits, tickets, and bars to tile IDs | Combinational | A |
| `heat_ctrl` | Normal and boost states, heat counter, warning, meltdown | FSM + counter | A |
| `lfsr16` | Random recipe source | Shift register | A |
| `recipe_rom` | Recipe to mask and patience | ROM | A |
| `order_mgr` | 3 slots, spawn, expiry, match | FSM + comparators | A |
| `score_bcd` | BCD accumulator | Datapath | A |
| `hex7seg` | HEX debug displays | Reused from Lab 4 | Either |

### 6.3 External code to cite

| Code | Source | Used for |
|---|---|---|
| VGA adapter | Course VGA Adapter page | Sync timing, framebuffer, DAC signals |
| VGA examples (`object`, `animate`, `_pro` versions) | Course VGA Adapter page | Starter code only; cite anything you keep |
| `bmp_to_mif` | Course VGA Adapter page (`MIF_c.zip`) | Background MIF |
| PS/2 controller | DE1-SoC IP cores page | Raw byte reception |
| ROM wrappers | Generated by the Quartus IP Catalog | `tile_rom`, `map_rom`, and `recipe_rom` if you use a memory for it |

Your Python asset converter is an offline tool. Mention it in the slides. If you draw on outside sprite art, cite that too.

---

## 7. Input and movement design

### 7.1 Keyboard decoder

PS/2 Set 2 scan codes:

| Key | Press | Release |
|---|---|---|
| Up | `E0 75` | `E0 F0 75` |
| Down | `E0 72` | `E0 F0 72` |
| Left | `E0 6B` | `E0 F0 6B` |
| Right | `E0 74` | `E0 F0 74` |
| Space | `29` | `F0 29` |
| Enter | `5A` | `F0 5A` |
| Z (overclock) | `1A` | `F0 1A` |

This is a sequence detector, with bytes as its input symbols instead of single bits. It needs four states: idle, seen `E0`, seen `F0`, and seen `E0 F0`. It advances only when the core's data-valid pulse is high, sets a held flag on a completed press, and clears it on a completed release, ignoring anything else.

Overclock uses the held flag directly, with no edge detector, because it stays active for as long as the key is down. It uses `Z` rather than Shift because keyboards can insert extra `E0 12` bytes around arrow keys while Shift is held.

Three pitfalls to design for:

- **Key repeat.** A held key resends its press code, so Space cannot be treated as an event per byte, or the chef will pick up and drop repeatedly. Use a rising-edge detector on the held flag.
- **Short pulses.** The core's data-valid signal lasts one clock while game logic runs at 60 or 90 Hz, so press events must be latched until the next tick consumes them.
- **Key rollover.** Some keyboards drop certain arrow + Space + `Z` combinations. Test holding keys together in Week 9. If it fails, use WASD (`1D`, `1C`, `1B`, `23`) for movement and `M` (`3A`) for overclock.

### 7.2 Movement

The chef holds a tile position plus a pixel offset.

- **Idle (aligned to a tile):** on a tick with an arrow held, turn to face that way and look up the next tile in the map ROM. If it is floor, enter Step. If it is solid, stay put, which is how the player faces a station.
- **Step:** move 2 px per tick. After 8 ticks, update the tile position and return to Idle.

If two arrows are held, a fixed priority picks one. The target for interaction is the tile one step ahead in the facing direction.

### 7.3 Board I/O

| Resource | Use |
|---|---|
| `KEY[0]` | Reset, active low, as in your labs |
| `KEY[3:1]`, `SW[7:1]` | Backup controls when `SW[9]` is on; finalize once you know how many you need |
| `SW[8]` | Backup overclock control when `SW[9]` is on |
| `SW[9]` | Input select: keyboard or backup |
| `HEX5-3` | Time (m ss) |
| `HEX2-0` | Score, or last scan byte in debug mode |
| `LEDR[9]` | Heat warning, blinking |
| `LEDR[8]` | Overclock active |
| `LEDR[7:0]` | FSM states, missed orders, rejected delivery |
| `VGA_*` | Video out |
| `PS2_CLK`, `PS2_DAT` | Keyboard |

Top-level port names must match `DE1_SoC.qsf` so the pin assignments apply, as in your labs.

KEY and SW change independently of `CLOCK_50`, so pass them through a two-flip-flop synchronizer before use. Memory lab Part IV asks for the same thing with its slide switches. That lab's Part II uses `KEY0` as a manual clock, which is fine there but breaks the one-clock rule here.

---

## 8. Schedule and milestones

Key dates: proposal Nov 6, Milestone 1 Nov 19, Milestone 2 Nov 26, presentation Dec 3. The table below shows who does what. [SCHEDULE_v2.md](SCHEDULE_v2.md) has the full weekly task list, including files, simulations, and board tests.

| Week | Member A (video, orders) | Member B (input, game logic) | Output |
|---|---|---|---|
| **8** (Nov 5 to 8) | Run `display_mif_pro` and `object` on board, set to 320×240 at 9 bits; do memory lab Part I | Read the PS/2 code in `object`, confirm scan codes on HEX | **Proposal by Nov 6**, game state bus agreed |
| **9** (Nov 9 to 15) | `tile_rom`, `map_rom`, asset script, `renderer` with stub state | `tick_gen` with both rates, `kbd_decoder`, `input_ctrl`, `chef_move` | Simulations of all modules |
| **10** (Nov 16 to 19) | Integrate chef sprite | Integrate input and boost key; `game_timer` | **Milestone 1, Nov 19** |
| **11** (Nov 19 to 26) | `lfsr16`, `recipe_rom`, `order_mgr`, `score_bcd`, `heat_ctrl`, `hud_mux`, renderer layers | `progress_timer`, `interact_decoder`, `kitchen_state`, `board_fsm`, `stove_fsm`, `game_fsm` | **Milestone 2, Nov 26** |
| **12** (Nov 27 to Dec 3) | Overclock on board, heat bar, Title, Time Up, and Meltdown screens, art polish, slides | Playtest tuning, bug fixes, slides, backup video | Feature freeze Nov 30; **Presentation, Dec 3** |

**Milestone 1 demo (Week 10).** The kitchen renders from ROM on VGA. The chef walks with the arrow keys, stops at counters, and faces the correct way. Holding `Z` speeds the chef up 1.5×, with no heat limit yet. HEX shows the last scan byte and a running timer. Simulations cover `kbd_decoder`, `chef_move`, `tick_gen`, and the renderer's first rows of pixels.

**Milestone 2 demo (Week 11).** The whole loop runs on the board: pick up, chop, cook, burn, assemble, serve, score, expire, time out. Simulations show the internals that are hard to see on the board, namely `interact_decoder`, `stove_fsm`, `order_mgr`, and `heat_ctrl`. `heat_ctrl` goes on the board in Week 12 unless Tier 4 finishes early.

### 8.1 Fallback tiers

Each tier is a complete demo. If you fall behind, stop at the last working tier and cut anything above it. The boost key works from Tier 1, since it only needs the `tick_gen` rate select.

| Tier | Contents | Roughly equals |
|---|---|---|
| 1 | VGA kitchen with a chef moved by keyboard or KEY buttons | Milestone 1 |
| 2 | Add pickup, one station, one fixed recipe, serve, score | Minimum game |
| 3 | Add chop, cook, burn, and game timer | Most of Milestone 2 |
| 4 | Add 3 slots, random orders, patience | Full design |
| 5 | Add heat, heat bar, and meltdown ending | Overclock complete |
| 6 | Add title and end screens, polish | Final target |
| 7 | Stretch goals | Bonus |

**Stretch goals, by value for effort:**

1. **Streak bonus (`streak_detector`).** Treat each order outcome as one bit, served = 1 and expired = 0. A sequence detector for `111` awards +50 and shows a streak indicator. It is small, and it is the textbook detector applied to gameplay.
2. **Demo code (`code_detector`).** A sequence detector on the title screen watches arrow presses. Up, Up, Down, Down starts a demo mode with a longer game timer, which helps show burning and game over during the 10-minute presentation. A wrong key must fall back to the correct partial-match state, not always to the start: after Up, Up, Up, the last two presses still count. The overlap handling is a good TA talking point.
3. Tip of +50 when more than half the patience remains
4. Second stove or board (`board_fsm` and `stove_fsm` are already separate modules)
5. Placing items on any counter
6. Difficulty ramp with shorter spawn intervals over time
7. High score register that survives between games

Sound is out of scope, so the audio core and codec pins are not used.

---

## 9. Division of work

| | Member A | Member B |
|---|---|---|
| Focus | Video and order system | Input, movement, station logic |
| Roughly | 1.5 labs | 1.5 labs |
| Milestone 1 | Renderer, ROMs, asset script | Keyboard decoder, chef movement, ticks |
| Milestone 2 | Order manager, score, heat controller, HUD | Interaction decoder, station FSMs, game FSM |
| Final | Screens and art | Tuning and debug |

Swap modules if your interests differ, but keep work in each milestone for both. **Each of you should be able to explain the other's modules**, since the TA can ask either of you. A short code walkthrough before each milestone covers this.

---

## 10. Verification

Follow your lab flow: `testbench.v` and `wave.do` in a ModelSim folder per module.

**Improve on the labs in one way.** In `lab4/part3.v:27-28` you swapped a commented-out line to shorten the 1-second count for simulation. Use a `parameter` instead, overridden by the testbench, so the simulated code is the same code that goes on the board. At real speed, a single simulated second is 50 million clocks.

| Module | Key test cases |
|---|---|
| `tick_gen` | Pulses are exactly one clock wide, at the correct period; `game_tick` changes between 60 and 90 Hz only at a wrap, with no missed or double pulse; `frame_60`, `tick_1s`, and `tick_4hz` don't change with `boost` |
| `kbd_decoder` | Arrow press and release, Space, `Z`, repeated press bytes, unknown codes ignored, `E0 F0` sequences, idle gaps between bytes |
| `streak_detector`, `code_detector` (if built) | Exact match fires once; overlapping input such as `1111` or Up, Up, Up, Down, Down; a wrong input resets correctly |
| `input_ctrl` | One action per press despite key repeat; press between ticks isn't lost; overclock stays active while held |
| `chef_move` | Moves 16 px per tile step; blocked at wall but still turns; direction change only when aligned |
| `progress_timer` | Pauses when not enabled, keeps progress, signals done once |
| `interact_decoder` | Every row of Section 3.6, plus sample unlisted combinations doing nothing |
| `board_fsm` | Chopping pauses on release; chopped item is collectable |
| `stove_fsm` | Empty, cooking, cooked, burnt in order; removal at each stage |
| `order_mgr` | Spawn into a free slot, no spawn when full, expiry, match, lowest-slot priority, no match, serve beats expiry on the same clock |
| `score_bcd` | Carry at 900 + 100, saturates at 9900 |
| `game_timer` | 2:00 to 1:59, 1:00 to 0:59, stops at 0:00 |
| `heat_ctrl` | Rises every `tick_4hz` while boosting; falls every second pulse otherwise; stops at 0; `heat_warn` from 24; one `meltdown` pulse at 31; ignores the key outside play |
| `game_fsm` | Start, timeout, meltdown, Time Up wins on the same clock, restart clears all state including `heat` |
| `tile_rom`, `map_rom` | Known addresses return the `.mif` values; data is valid exactly one clock after the address |
| `renderer` | Correct `plot` count per frame (76,800); first rows have expected x, y, colour; chef overrides background; transparency works |
| Integration | Scripted keypresses cook and serve a Burger, score reaches 100; holding `Z` reaches meltdown and keeps the score |

For the milestone PDFs, capture waveforms with radix and labels set in `wave.do` as you did in earlier labs, and add `$display` checks where a waveform is hard to read.

**DESim:** the VGA Adapter page has DESim versions of all four examples, with a simulated VGA Display window and PS/2 Keyboard window. Starting from the DESim `object` example lets you see the game and test keys without a board, which helps when lab time is short. Set the VGA window to 320×240 to match your parameters. DESim runs on ModelSim, so ROM `.mif` files need the same copy step.

**Board debugging:** reserve LEDs for FSM states and a HEX pair for the last scan code. To check a ROM on the board, reuse the memory lab Part IV idea: a counter steps the read address about once a second while HEX shows the address and data. Build a `.sdc` with a 50 MHz `create_clock` so the timing report is meaningful, and check Fmax after each integration.

---

## 11. Concepts

### 11.1 From your labs

| Lab | Concept | File | Use in project |
|---|---|---|---|
| 1 | Multiplexers | `lab1/part5.v` (`mux_2bit_3to1`) | Layer select, input source, tile select |
| 1 | Pin-level I/O with the DE1-SoC `.qsf` | `DE1_SoC.qsf` | Same flow, with VGA and PS/2 pins added |
| 2 | Comparators | `lab2/part4.v:16` (`z`) | Digit-over-9 detect, BCD carry |
| 2 | Adders | `lab2/part3.v` (`adder4b`) | Score add |
| 2 | BCD correction | `lab2/part4.v` | `score_bcd`; the same +6 idea at each digit |
| 2 | Binary-to-7-segment decoders | `lab2/part4.v` (`num7seg`) | HEX display |
| 3 | D flip-flops and registers | `lab3/part4.v`, `lab3/part5.v` | All state: position, held item, score |
| 3 | Reset | `lab3/part5.v` | Use synchronous reset as in Lab 4 |
| 3 | Register plus adder datapath | `lab3/part5.v` | Score accumulator, position update |
| 4 | Counters with enable and clear | `lab4/part2.v` (`counter_16b`) | Pixel x/y, progress timer |
| 4 | Clock dividers, one-cycle enable | `lab4/part3.v:17` (`counter_26b`) | `tick_gen` |
| 4 | Modulo-N counters | `lab4/part3.v:40` (`counter_0to9`), `lab4/part4.v` (`counter_0to5`) | m:ss game timer, as a down-counter |
| 4 | Enable-chained counters | `lab4/part3.v` | Tick to second to timer |
| 4 | Hex decoder | `lab4/part1.v:14` (`hex7seg`) | Debug displays |
| All | ModelSim testbench and `wave.do` | `lab4/designFiles/part3/ModelSim/` | Template for every module |

**Pattern to avoid.** `lab3/part5.v:12` clocks a register directly from `KEY[1]`. That was correct for that lab, but in the project nothing should be clocked by anything except `CLOCK_50`. Buttons and slow timers become enables.

### 11.2 From lectures

These are ECE241 material even though your labs so far haven't used them.

| Concept | Use in project |
|---|---|
| Moore FSMs | `game_fsm`, `board_fsm`, `stove_fsm`, `heat_ctrl`, `chef_move`, renderer. Outputs depend only on state, which keeps them glitch-free and easy to read in waveforms. Use this as the default. |
| Mealy outputs | One-cycle pulses that depend on the current input, such as a press event in `kbd_decoder`. Use only where a Moore output would arrive a cycle late. |
| Sequence detectors | `kbd_decoder` (byte sequences); optional `streak_detector` and `code_detector` (Section 8.1) |
| State diagrams and state tables | Draw one per FSM before coding, then reuse them as slide block diagrams |
| Datapath and control separation | Renderer, `order_mgr`, `chef_move` |
| Shift registers | `lfsr16`, edge detector |
| Priority encoders | Lowest matching order slot, arrow key priority |
| Decoders | Station type from tile ID, recipe ID to mask |
| Comparators | Plate mask against each order, chef hit test, timer limits, heat warning and meltdown |

### 11.3 New concepts to learn

| Concept | Used in | Where to learn |
|---|---|---|
| M10K blocks, synchronous reads, and read latency | `tile_rom`, `map_rom` | `mem_lab_Verilog.pdf`, intro and Part I |
| IP Catalog memories and `.mif` initialization | Asset pipeline | `mem_lab_Verilog.pdf`, Part I |
| Memory simulation setup | ROM testbenches | `mem_lab_Verilog.pdf`, Parts I and III |
| Reading memory with a counter | Renderer, ROM board test | `mem_lab_Verilog.pdf`, Part IV |
| Input synchronization | `input_ctrl` | `mem_lab_Verilog.pdf`, Part IV |
| VGA and framebuffers | Renderer | VGA Adapter page; `object` and `animate` examples |
| PS/2 protocol and scan codes | `kbd_decoder` | IP cores page; `object` example |
| Edge detection | `input_ctrl` | Two-flip-flop pattern, extends Lab 3 |
| LFSR randomness | `lfsr16` | Shift register with XOR feedback; for 16 bits use taps 16, 14, 13, 11. Keep it running on the title screen so human timing seeds it. |
| Parameterized modules | `progress_timer`, `tick_gen` | Verilog `parameter` and instance overrides |
| Packed vectors for ports | Game state bus | Verilog-2001 limitation |
| Selectable-period dividers | `tick_gen` | Extends Lab 4's divider: a mux picks the count limit, applied at wrap |
| Saturating up/down counters | `heat_ctrl` | Extends Lab 4's counters with direction and limits |
| Timing analysis | Whole design | Quartus TimeQuest report |

---

## 12. Components and deliverables

### 12.1 Hardware and software

| Item | Notes |
|---|---|
| DE1-SoC board, power, USB-Blaster cable | Same as labs |
| VGA monitor and cable | Check that lab stations have these |
| **PS/2 keyboard** | Must plug into the board's PS/2 port. A USB keyboard needs an adapter and only works if the keyboard itself supports PS/2. Confirm with your TA this week. |
| Quartus Prime Lite 18.1 | Already installed |
| ModelSim | Already used |
| DESim | Optional, for testing VGA and keyboard without a board |
| Course downloads from the VGA Adapter page | `vga_adapter.zip`, `DE1-SoC.zip` (board examples), `MIF_c.zip`, and the DESim `object.zip` |
| Python with Pillow | For the asset converter |

### 12.2 Suggested folder structure

```
project/
  PLAN_v2.md
  overclocked.qpf, overclocked.qsf     (start from ../DE1_SoC.qsf)
  overclocked.sdc
  SCHEDULE_v2.md
  src/          overclocked_top.v, overclocked_defs.vh, one file per module
  src/ip/       VGA adapter, PS/2 core, generated ROM wrappers, kept separate for citation
  assets/       PNG tiles, generated .mif files
  tools/        Python converter
  sim/<module>/ testbench.v, wave.do
  docs/         Milestone PDFs, diagrams, slides
```

Keep `hex7seg` in one file. Your labs copied it into each part, which causes duplicate-module errors once everything is in a single project. Use git if you can, since two people will edit this at once.

### 12.3 Milestone PDF checklist

- [ ] What each teammate accomplished
- [ ] Block diagrams
- [ ] Code being demoed, with an explanation
- [ ] ModelSim simulations of that code
- [ ] Any other code in progress, with simulations showing debug work
- [ ] Submitted to Quercus before your lab period

### 12.4 Slide checklist

- [ ] Complete project description, including credit to Overcooked as inspiration
- [ ] High-level block diagram: inputs, datapath, outputs
- [ ] Detailed block diagram for each sub-component
- [ ] Photos of the project working
- [ ] Bugs and fixes (keep a running log from Week 9)
- [ ] Future work
- [ ] Final work distribution
- [ ] Citations for the VGA adapter and PS/2 core
- [ ] Equal presenting time, fits 10 minutes with demo
- [ ] Backup video uploaded to Quercus

---

## 13. Proposal draft

The proposal must fit one single-sided page, single-spaced, 11 pt or larger, including figures. Redraw the diagram below in a drawing tool.

**Summary.** Overclocked is a single-player cooking game on the DE1-SoC, inspired by Overcooked. The player uses a PS/2 keyboard to move a chef around a kitchen shown on a VGA monitor, preparing ingredients and delivering randomly generated orders before they expire, to score as many points as possible in two minutes. Holding an overclock key runs the whole kitchen 1.5× faster, including how quickly food burns, but builds heat. If heat reaches its limit, the game ends in a meltdown.

**Block diagram.**

```
 PS/2 keyboard -> PS/2 core* -> Key decoder -> Chef movement -----+
 KEY, SW ------------------------------------> + collision        |
                                                                  v
 CLOCK_50 -> Tick generator (60 or 90 Hz) -> GAME LOGIC: interaction decoder,
                  ^ boost                    chop and stove FSMs, order manager,
 LFSR, Recipe ROM -------------------------> heat controller, score, timer, game FSM
                                                      |
                                                 game state
                                                      v
 Map ROM, Tile ROM -------------------------> Renderer FSM -> VGA adapter* -> Monitor
                                                      |
                                                      +-> HEX, LEDR    (* provided IP)
```

**Schedule.**

| Week | Goal |
|---|---|
| 8 | Proposal; VGA and PS/2 demos running on board |
| 9 | Renderer, ROMs, keyboard decoder, movement built and simulated |
| 10 | **Milestone 1:** chef moves around the kitchen on VGA with keyboard control and collision |
| 11 | **Milestone 2:** full cooking loop with orders, score, and timer on board; internal simulations |
| 12 | Overclock and meltdown on board, debugging, final polish, **Presentation** |

**Division of work.**

| | Member A | Member B |
|---|---|---|
| Milestone 1 | VGA integration, tile and map ROMs, renderer FSM | Keyboard decoder, tick generator, chef movement and collision |
| Milestone 2 | Order manager, LFSR, recipe ROM, score, heat controller, HUD | Interaction logic, chopping and stove FSMs, game FSM, game timer |
| Final | Overclock integration, title and end screens, art | Playtest tuning, integration debug |

---

## 14. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Keyboard unavailable or unreliable | Medium | High | KEY/SW backup input from day one; `SW[9]` selects |
| Adapter ports differ from assumptions | Low | Medium | Check `vga_demo.v` and run `object` in Week 8; the renderer's write interface is small and easy to change |
| Background MIF doesn't match resolution | Medium | Low | Generate a 320×240, 9-bit MIF (Section 5.1) |
| ROM latency errors garble tiles | High | Medium | Simulate a small tile first; use a test pattern with a unique colour per corner |
| ROM reads as X or zero in ModelSim | High | Low | Copy the `.mif` into the simulation folder (Section 5.3) |
| Integration bugs at the end | Medium | High | Agree on the bus in Week 8; integrate at each milestone, not only at the end |
| Long Quartus compiles | Medium | Low | Debug in ModelSim first, compile less often |
| Game too hard or too easy | Medium | Low | All timing constants are parameters |
| Players avoid overclock because meltdown ends the run | Medium | Medium | Clear warning at heat 24; tune heat rates so short bursts feel safe |
| Tick rate change causes a missed or double pulse | Medium | Medium | Apply the new period only at a wrap; test in `sim/tick_gen/` |
| Chef tears during repaint at 90 Hz | Low | Low | Copy the chef position into registers at the start of each frame |
| Scope too large | Medium | High | Fallback tiers in Section 8.1; ask your TA "is this complex enough?" at proposal time |
| TA questions on unfamiliar code | Medium | High | Write your own code; do a walkthrough before every milestone |
