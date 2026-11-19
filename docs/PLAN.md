# Overclocked: Project Plan

A single-player kitchen game on the DE1-SoC, inspired by Overcooked. Its main twist is an overclock key: the player can run the whole kitchen 1.5× faster, but the heat this builds ends the game if it reaches the limit.

This is the final plan. It merges the earlier versions. The older drafts are in [archive/](archive/) for reference only. [SCHEDULE.md](SCHEDULE.md) has the weekly task list.

Course: ECE241H1 F, Digital Systems. Target board: DE1-SoC (Cyclone V, `5CSEMA5F31C6`).

Reference files in `../../project/` (the `labs/project` folder): the project spec and VGA Adapter page (`.html`), and the Memory Blocks lab (`mem_lab_Verilog.pdf`).

## Contents

1. [Read this first](#1-read-this-first)
2. [Spec requirements](#2-spec-requirements-and-how-the-plan-meets-them)
3. [Game design](#3-game-design)
4. [System architecture](#4-system-architecture)
5. [Video design](#5-video-design)
6. [Interfaces and module list](#6-interfaces-and-module-list)
7. [Input and movement design](#7-input-and-movement-design)
8. [Milestones and fallback tiers](#8-milestones-and-fallback-tiers)
9. [Division of work](#9-division-of-work)
10. [Verification](#10-verification)
11. [Concepts](#11-concepts)
12. [Components and deliverables](#12-components-and-deliverables)
13. [Summary block diagram](#13-summary-block-diagram)
14. [Risks](#14-risks)

---

## 1. Read this first

**Write the Verilog yourselves.** The spec says your grade depends heavily on explaining your code, and the TA will question you on it. For that reason this plan defines behaviour, interfaces, and tests, and contains no RTL. Check the syllabus AI policy to see how it treats AI help with planning too, since I only have the project page's summary of it.

**Open questions.** Week 8 was meant to settle these. Record the answers here once you have them.

| Item | Why it matters | Action |
|---|---|---|
| VGA adapter ports | The VGA Adapter page confirms 320×240, 9-bit colour, and an on-chip video memory, but the Verilog is in `vga_adapter.zip`, which I don't have. The plan assumes `(x, y, colour, plot)` pixel writes, up to one every few clocks. | Check `vga_demo.v` in the `object` or `animate` example. |
| PS/2 interface | I confirmed the core exists on the DE1-SoC IP cores page, but its one-clock data-valid signal is from memory. | Check the core's PDF and the `object` example, which already reads a PS/2 keyboard. |
| Lab 5 | The spec refers to it, but only labs 1 to 4 are in this directory. | FSMs and sequence detectors are lecture material, so the plan uses them freely (Section 11.2). If Lab 5 has reusable FSM code, start from it. |
| Team | The spec bans groups of 1. I don't have your partner's name. | Replace "Member A/B" in Section 9. |

---

## 2. Spec requirements and how the plan meets them

| Requirement | How it is met | Section |
|---|---|---|
| At least 3 labs of work (Lab 5 × 3) | Three blocks: video, input and movement, game logic with overclock | 4, 9 |
| Most functionality on the FPGA | Everything runs on the FPGA. Python is only an offline asset converter. | 4 |
| Builds on lecture and lab material | Counters, registers, BCD, muxes, and 7-segment decoders are reused directly | 11 |
| Own work, others' code cited | Only the VGA adapter and PS/2 core are external. They count as "less work", so the plan's scope sits in your own modules on top of them. | 6.3 |
| Team of 2, at least 1.5 labs each, both working every milestone | Split by module with work in every phase | 9 |
| Proposal | Submitted Nov 6 | |
| M1 (Week 10): part working on board, plus simulations | Kitchen on VGA, chef moved by keyboard, with collision and boost | 8 |
| M2 (Week 11): most of it on board, plus simulations of internals | Full cooking loop with score and timer; `heat_ctrl` simulated | 8 |
| Milestone PDF: who did what, code, explanation, ModelSim | Testbench per module, PDF checklist | 10, 12 |
| Presentation: 10 minutes, equal speaking time, detailed slides | Slide checklist | 12 |
| Something must work by the presentation | Ordered fallback tiers | 8.1 |

---

## 3. Game design

### 3.1 Player experience

The player has 2 minutes to complete as many food orders as possible. One random burger order is active at a time, and the next appears as soon as it is served. The player grabs ingredients from crates, cooks the patty, carries each part to the assembly station, and presses Space there to serve. Food left on the stove too long burns. At 0:00 the game freezes with the final score on HEX, and reset starts a new game.

The player can hold the overclock key to speed up the whole kitchen, including cooking and burning. Boosting builds heat, and if heat reaches its limit the game ends early in a meltdown.

The stove is the bottleneck in every order. Overclock is the main way to cut that wait, so when to boost becomes the core decision of the game.

### 3.2 Changes to your feature table

| Feature | Your idea | Plan | Reason |
|---|---|---|---|
| Movement | Arrow keys, X/Y registers | Same, but locked to the tile grid with smooth 2 px steps | Collision becomes one tile lookup instead of box overlap maths |
| Pickup | Space near a station | Space acts on the station next to the chef's tile; the layout guarantees at most one | No direction register; the target is a small decoder on the chef's tile |
| Cooking | Wait 5 s | Runs in the background, about 5 s | Same as yours |
| Burning | 5 s later | Same; a burnt patty must go in the trash | Adds a recovery action |
| Orders | ROM + order register | ROM holds a 4-bit ingredient mask per recipe; 1 active order; a random generator picks recipes | A serve check becomes one equality comparison |
| Scoring | +100 | +10 per order, stored directly in BCD | HEX digits need no binary-to-decimal conversion |
| Game timer | 2 minutes | Same, as a BCD m:ss down-counter | Direct extension of Lab 4 |
| Game over | Show score | Freeze at 0:00 or on meltdown with the final score on HEX; reset restarts | Avoids extra screens and font art |
| Overclock | None | Hold a key to run the kitchen at 1.5× speed; full heat ends the game (Section 3.8) | Sets the game apart from Overcooked and gives the title a meaning |

### 3.3 Timing constants

All are parameters, so playtesting can change them. Cook and burn run as 16 progress steps so the 4-bit count is directly the width of a 16 px bar, which avoids a multiplier.

| Constant | Value | Actual time |
|---|---|---|
| Game tick | 60 Hz | 833,333 clocks |
| Game tick, boosted | 90 Hz | 555,556 clocks |
| Chef speed | 2 px per tick | 8 ticks per tile, 7.5 tiles/s |
| Cook | 16 steps × 19 ticks | 5.07 s |
| Burn | 16 steps × 19 ticks | 5.07 s |
| Game length | 120 s | 120 s |
| Heat rise while boosting | +1 every 0.25 s | 7.75 s from 0 to 31 |
| Heat fall otherwise | −1 every 0.5 s | 15.5 s from 31 to 0 |
| Heat warning | 24 of 31 | About 1.75 s of boost left |

Cook and burn are slightly off 5 s because the step count has to be a whole number of ticks. Chef, cook, and burn values are for normal speed; Section 3.8 lists the boosted times.

### 3.4 Recipes

Each order is a 4-bit mask, `{patty, tomato, lettuce, bun}`. Every recipe needs a cooked patty and a bun, so every order goes through the stove.

| ID | Recipe | Mask | Parts to carry to assembly |
|---|---|---|---|
| 0 | Burger | `1001` | Bun, cooked patty |
| 1 | Lettuce burger | `1011` | Bun, lettuce, cooked patty |
| 2 | Tomato burger | `1101` | Bun, tomato, cooked patty |
| 3 | Deluxe burger | `1111` | Bun, lettuce, tomato, cooked patty |

The chef carries one item at a time, so each part is its own trip. A rough estimate is 8 to 10 s for a Deluxe, with the patty cooking during the bun and veg trips. A plain Burger has fewer trips to fill the cook time, so the player either waits or boosts. Orders never expire, so pressure comes from the burn timer, the 2-minute limit, and the choice of when to overclock. If the game feels too easy, raise the cook time first.

### 3.5 Items held by the chef

`held_item` is a 3-bit enum.

| Code | Item | Code | Item |
|---|---|---|---|
| 0 | Empty | 4 | Patty, raw |
| 1 | Bun | 5 | Patty, cooked |
| 2 | Lettuce | 6 | Patty, burnt |
| 3 | Tomato | | |

### 3.6 Interaction table

This table is the core of the game logic. It should become a single combinational decoder, tested row by row. Every action is one Space press. The station is found from the chef's tile alone (Section 3.7). Any combination not listed does nothing. A wrong order clears the assembly because ingredients can't be removed one at a time, so it would otherwise block every later order.

| Station | Holding | Condition | Result |
|---|---|---|---|
| Crate (bun, lettuce, tomato, patty) | Empty | | Holding = that ingredient |
| Stove | Patty, raw | Stove empty | Starts cooking |
| Stove | Empty | Cooked or burnt | Patty moves to chef, stove resets |
| Assembly | Bun, lettuce, tomato, or cooked patty | That mask bit is clear | Sets bit, hands empty |
| Assembly | Empty | Mask matches the current order | Next order loads, score +10, assembly cleared |
| Assembly | Empty | Mask not zero, no match | Assembly cleared, flash an LED |
| Trash | Anything | | Hands empty |

### 3.7 Screen layout

The screen is 320×240, made of 16×16 tiles, giving a grid of 20×15.

```
r0-1   Heat bar; time and score are on HEX
r2     ####################
r3     ##B#L#T#P#####S#####
r4     #..................#
r5     #..................#
r6     #..................#
r7     #.....####A###.....#
r8     #..................#
r9     #..................#
r10    #..................#
r11    ###X################
r12-14 Current order icon
```

Key: `#` solid counter or wall, `.` floor, `B` bun, `L` lettuce, `T` tomato, `P` patty, `S` stove, `A` assembly, `X` trash.

**Layout rule: no floor tile may be next to two stations.** Keep at least one counter tile between any two stations. Then the chef's tile alone decides the interaction target:

| Chef tile (x, y) | Station |
|---|---|
| (2, 4) | Bun crate |
| (4, 4) | Lettuce crate |
| (6, 4) | Tomato crate |
| (8, 4) | Patty crate |
| (14, 4) | Stove |
| (10, 6) or (10, 8) | Assembly |
| (3, 10) | Trash |
| Anything else | None |

If you change the layout, update this table and check the rule again.

### 3.8 Overclock

Holding the overclock key (`Z`) raises the game tick from 60 to 90 Hz, so the whole kitchen runs at 1.5× speed. Everything driven by `game_tick` speeds up, including burning. The game timer stays on real time, so boosting lets the player finish more orders before 0:00.

| Action | Normal, 60 Hz | Boosted, 90 Hz |
|---|---|---|
| Chef speed | 7.5 tiles/s | 11.25 tiles/s |
| Cook | 5.07 s | 3.38 s |
| Burn | 5.07 s | 3.38 s |

**Heat.** `heat` is a 5-bit saturating up/down counter, from 0 to 31, updated on real-time pulses so its rate never depends on the game tick.

- **Boosting:** +1 on every `tick_4hz` pulse, so 0 to 31 takes 7.75 s.
- **Not boosting:** −1 on every second `tick_4hz` pulse, stopping at 0, so 31 to 0 takes 15.5 s.
- **Warning, 24 or more:** the heat bar flashes and `LEDR[9]` blinks, with about 1.75 s of boost left. The check is only that the top two bits of `heat` are both 1.
- **Meltdown, 31:** the game freezes at once, the same way it does at 0:00. The score stands, and reset starts a new game.

There are no end screens, so a meltdown is shown by three things: the heat bar stays full, `LEDR[9]` stays on, and HEX5-3 stops above 0:00.

**Control.** `heat_ctrl` is a two-state Moore FSM, `NORMAL` and `BOOST`, plus the heat counter. It enters `BOOST` while the key is held during play and returns to `NORMAL` on release. Its `boost` output selects the divider count in `tick_gen`, and its one-cycle `meltdown` pulse moves `game_fsm` to the Meltdown state.

**Balance.** Heat rises twice as fast as it falls, so a player can boost about a third of the time. Over a full game the limit is about 45 s of boost, worth about 22 s of extra kitchen time. A full boost through one cook saves about 1.7 s. Tune these rates in playtesting so that short bursts feel safe and worthwhile.

**Edge cases:**

- The key does nothing once the game has frozen, and reset clears `heat`.
- If meltdown and 0:00 land on the same clock, Time Up wins.
- `tick_gen` applies a new period only when its counter wraps. Changing the limit mid-count could leave the counter above the new limit, so it would miss the match and run on.

---

## 4. System architecture

```
                         +-------------------- CLOCK_50 (everything) ------------------+
                         |                                                             |
 PS/2 keyboard           v                                                             v
 ---------> [PS/2 core*] -> [kbd_decoder] -> [input_ctrl] -> [chef_move] <-> [map_rom A]
                                                 ^               |
 KEY/SW (backup) --------------------------------+               | tile x/y        
                                                                 v
 [tick_gen] ticks ----------> all game blocks          [interact_decoder] <-> [map_rom A]
                                                         |          |
                                       +-----------------+          +---------------+
                                       v                                            v
                                  [stove_fsm]                               [order_mgr] <- [lfsr]
                                  [kitchen_state]                           [recipe_rom]
                                  held_item, assembly                               |
                                       |                                      [score_bcd]
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
                 tick_4hz, playing ----+   +-- heat, heat_warn --> renderer, LEDR
                                           +-- meltdown -------> [game_fsm]
```

Four design rules keep this manageable, and they are worth stating on your slides.

1. **One clock.** Everything runs on `CLOCK_50`. Slow events are one-cycle enable pulses, the same way `onesec` works in `lab4/part3.v`.
2. **Game-speed state changes only on `game_tick`.** Chef movement, the stove, and interactions advance on this pulse, at 60 or 90 Hz. The game timer and heat advance on the fixed `tick_1s` and `tick_4hz` pulses, so overclock can't stretch them. Key presses are latched until the next `game_tick`, so the game runs in deterministic steps and is easy to simulate.
3. **The renderer only reads game state.** It never changes it, so the two halves can be built in parallel against the bus in Section 6.1.
4. **Repaint every pixel, every frame.** There is no erase-and-redraw step (Section 5.2).

---

## 5. Video design

### 5.1 Resolution and memory

| Item | Size | Share of the chip |
|---|---|---|
| Framebuffer, 320×240 at 9-bit colour | 691,200 bits | About 17% of on-chip block memory, more if the adapter pads addresses |
| Tile ROM, 64 tiles × 256 px × 9 bits | 147,456 bits | About 4% |
| Map ROM, 512 × 6 bits (one screen, rows padded to 32 entries), two copies | 6,144 bits | Under 1% |

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

1. Base tile from the map ROM
2. Dynamic tile: patty on the stove, or the current order icon
3. Chef sprite
4. Item held by the chef
5. Solid colour bars: cook, burn, and heat

A reserved colour marks transparent pixels in layers 2 to 4.

**Per-pixel sequence:** set the map address, read the tile ID, read each layer from the tile ROM in turn, select the top non-transparent colour, then pulse `plot` and advance x and y. Budget one clock for each ROM read, because M10K inputs are always registered and data returns one cycle late. This is the most likely source of off-by-one image bugs, so simulate it first.

That one-clock figure requires the `q` output register to be off (Section 5.3). With it on, each read takes two clocks, and four or five reads per pixel would use up the whole budget.

**Avoid multipliers with bit slicing:**

- Tile coordinates are `x[8:4]` and `y[7:4]`. Position inside a tile is `x[3:0]` and `y[3:0]`.
- Map rows are padded to 32 entries, so the map address is `{tile_y, tile_x}` with no multiply by 20.
- The tile ROM address is `{tile_id, y[3:0], x[3:0]}`.
- Chef hit test: `(x - chef_px) < 16` as an unsigned subtraction, likewise for y.
- The heat bar is 32 px wide at full scale, so `heat` is directly its width in pixels. It is a solid colour, so it needs no tiles.

**Tile budget (at most 64):** about 10 kitchen, 6 items (bun, lettuce, tomato, and three patty states), 4 order icons, and 1 chef sprite gives about 21. The assembly's contents can be drawn as four small coloured dots, one per mask bit, which avoids 16 assembly tiles.

### 5.3 ROM creation

Draw tiles as PNGs and convert them to `.mif` files with a small Python script, which also generates the map ROMs. Then build each ROM with the IP Catalog, following Part I of `mem_lab_Verilog.pdf`. That lab builds a RAM; a ROM uses the matching **ROM: 1-PORT** entry in the same category. The VGA page's `object` example stores sprites in on-chip ROM the same way, so read it first.

The course's `bmp_to_mif` tool (`MIF_c.zip`) converts 24-bit BMPs to MIF. Use it for the background image in Section 5.1, and compare its output with your script's to confirm the 9-bit colour format.

| Wizard setting | Choice | Reason |
|---|---|---|
| Category | Basic Functions > On Chip Memory | Same place as the lab's RAM |
| Width and depth | Tile ROM 9 × 16384, map ROM 6 × 512 | Section 5.1 |
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

Agree on this before building the renderer layers, since it lets both members work independently. A stub `game_state` that drives constant values lets the renderer be developed before the game logic exists.

| Signal | Width | Meaning |
|---|---|---|
| `chef_px`, `chef_py` | 9, 8 | Chef pixel position |
| `held_item` | 3 | What the chef holds |
| `stove_state`, `stove_progress` | 2, 4 | Empty, cooking, cooked, or burnt, and bar width |
| `assembly_mask` | 4 | Ingredients at the assembly station |
| `order_recipe` | 2 | Recipe of the current order |
| `heat` | 5 | Heat level; also the bar width in px |
| `heat_warn` | 1 | Blinks at heat 24 or more; stays on after a meltdown |

Score and time go straight to the HEX displays, so they aren't on this bus.

### 6.2 Your own modules

| Module | Purpose | Type | Owner |
|---|---|---|---|
| `overclocked_top` | Pin-level top, wiring | Structural | Both |
| `tick_gen` | `game_tick` (60 or 90 Hz), `frame_60`, `tick_1s`, and `tick_4hz` enable pulses | Counters | B |
| `kbd_decoder` | Scan bytes to held-key flags | Sequence detector FSM | B |
| `input_ctrl` | Synchronize KEY/SW, keyboard or KEY/SW select, press edges, latch until tick | Registers | B |
| `chef_move` | Position, tile-step logic | FSM + datapath | B |
| `interact_decoder` | Section 3.6 table | Combinational | B |
| `kitchen_state` | `held_item` and `assembly_mask` registers | Registers | B |
| `progress_timer` | Reusable prescaler + 4-bit step counter, used for cook and burn | Counter | B |
| `stove_fsm` | Empty, cooking, cooked, burnt | FSM | B |
| `heat_ctrl` | Normal and boost states, heat counter, warning, meltdown | FSM + counter | B |
| `game_timer` | BCD m:ss down-counter | Counters | A |
| `game_fsm` | Play, time up, meltdown | FSM | A |
| `renderer` | Pixel loop and layer compositor | FSM + datapath | A |
| `map_rom`, `tile_rom` | Layouts and art | Memory | A |
| `hud_mux` | Current order to icon tile ID | Combinational | A |
| `lfsr16` | Random recipe source | Shift register | A |
| `recipe_rom` | Recipe to mask | ROM | A |
| `order_mgr` | Current order, match, load next | Register + comparator | A |
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
| Z (overclock) | `1A` | `F0 1A` |

This is a sequence detector, with bytes as its input symbols instead of single bits. It needs four states: idle, seen `E0`, seen `F0`, and seen `E0 F0`. It advances only when the core's data-valid pulse is high, sets a held flag on a completed press, and clears it on a completed release, ignoring anything else.

Space is only ever used as a press event, through an edge detector. Overclock uses the held flag directly, with no edge detector, because it stays active for as long as the key is down. It uses `Z` rather than Shift because keyboards can insert extra `E0 12` bytes around arrow keys while Shift is held.

Three pitfalls to design for:

- **Key repeat.** A held key resends its press code, so Space cannot be treated as an event per byte, or the chef will pick up and drop repeatedly. Use a rising-edge detector on the held flag.
- **Short pulses.** The core's data-valid signal lasts one clock while game logic runs at 60 or 90 Hz, so press events must be latched until the next tick consumes them.
- **Key rollover.** Some keyboards drop certain arrow + Space + `Z` combinations. Test holding keys together. If it fails, use WASD (`1D`, `1C`, `1B`, `23`) for movement and `M` (`3A`) for overclock.

### 7.2 Movement

The chef holds a tile position plus a pixel offset.

- **Idle (aligned to a tile):** on a tick with a movement key held, look up the next tile in that direction in the map ROM. If it is floor, enter Step. If it is solid, stay put.
- **Step:** move 2 px per tick. After 8 ticks, update the tile position and return to Idle.

If two movement keys are held, a fixed priority picks one. There is no facing direction: the interaction target comes from the chef's tile (Section 3.7).

### 7.3 Board I/O

| Resource | Use |
|---|---|
| `KEY[0]` | Reset, active low, as in your labs |
| `KEY[3:1]`, `SW[7:1]` | Backup controls when `SW[9]` is on; finalize once you know how many you need |
| `SW[8]` | Backup overclock control when `SW[9]` is on |
| `SW[9]` | Input select: keyboard or backup |
| `HEX5-3` | Time (m ss) |
| `HEX2-0` | Score, or last scan byte in debug mode |
| `LEDR[9]` | Heat warning, blinking; stays on after a meltdown |
| `LEDR[8]` | Overclock active |
| `LEDR[7:0]` | FSM states, rejected order |
| `VGA_*` | Video out |
| `PS2_CLK`, `PS2_DAT` | Keyboard |

Top-level port names must match `DE1_SoC.qsf` so the pin assignments apply, as in your labs.

KEY and SW change independently of `CLOCK_50`, so pass them through a two-flip-flop synchronizer before use. Memory lab Part IV asks for the same thing with its slide switches. That lab's Part II uses `KEY0` as a manual clock, which is fine there but breaks the one-clock rule here.

---

## 8. Milestones and fallback tiers

Key dates: Milestone 1 Thu Nov 19, Milestone 2 Thu Nov 26, presentation Thu Dec 3. [SCHEDULE.md](SCHEDULE.md) has the weekly task list, including files, simulations, and board tests.

**Milestone 1 demo (Week 10).** The kitchen renders from ROM on VGA. The chef walks with the arrow keys, and stops at counters. Holding `Z` speeds the chef up 1.5×, with no heat limit yet. HEX shows the last scan byte and a running timer. Simulations cover `kbd_decoder`, `chef_move`, `tick_gen`, and the renderer's first rows of pixels.

**Milestone 2 demo (Week 11).** The whole loop runs on the board: pick up, cook, burn, assemble, serve, score, time out. Simulations show the internals that are hard to see on the board, namely `interact_decoder`, `stove_fsm`, `order_mgr`, and `heat_ctrl`. `heat_ctrl` goes on the board in Week 11 if time allows, otherwise in Week 12.

### 8.1 Fallback tiers

Each tier is a complete demo. If you fall behind, stop at the last working tier and cut anything above it. The boost key works from Tier 1, since it only needs the `tick_gen` rate select.

| Tier | Contents | Roughly equals |
|---|---|---|
| 1 | VGA kitchen with a chef moved by keyboard or KEY buttons, boost key | Milestone 1 |
| 2 | Add pickup, assembly, one fixed recipe, serve, score | Minimum game |
| 3 | Add stove with cook and burn, and the game timer | Most of Milestone 2 |
| 4 | Add random orders and game end at 0:00 | Milestone 2 |
| 5 | Add heat, heat bar, and meltdown ending | Overclock complete |
| 6 | Add polish and tuning | Final target |
| 7 | Stretch goals | Bonus |

**Stretch goals, by value for effort:**

1. Second stove, which makes boosting through two cooks at once worthwhile (`stove_fsm` is already a separate module)
2. Title and game over screens, including a distinct meltdown screen
3. Score and time on VGA
4. Three order slots
5. Placing items on any counter
6. High score register that survives between games

Sound is out of scope, so the audio core and codec pins are not used.

---

## 9. Division of work

| | Member A | Member B |
|---|---|---|
| Focus | Video, orders, score, and game flow | Input, movement, interactions, cooking, and overclock |
| Roughly | 1.5 labs | 1.5 labs |
| Milestone 1 | Renderer, ROMs, asset script, game timer | Keyboard decoder, input control, chef movement, ticks with boost |
| Milestone 2 | Order manager, LFSR, recipe ROM, score, order display, game FSM, renderer layers | Interaction decoder, kitchen state, progress timer, stove FSM, heat controller, integration |
| Final | Heat bar, art polish, and debug | Overclock tuning and debug |

Both members draw art. Swap modules if your interests differ, but keep work in each milestone for both. **Each of you should be able to explain the other's modules**, since the TA can ask either of you. A short code walkthrough before each milestone covers this.

---

## 10. Verification

Follow your lab flow: `testbench.v` and `wave.do` in a ModelSim folder per module. Trivial modules such as `hex7seg` and `hud_mux` can rely on integration simulation instead.

**Improve on the labs in one way.** In `lab4/part3.v:27-28` you swapped a commented-out line to shorten the 1-second count for simulation. Use a `parameter` instead, overridden by the testbench, so the simulated code is the same code that goes on the board. At real speed, a single simulated second is 50 million clocks.

| Module | Key test cases |
|---|---|
| `tick_gen` | Pulses are exactly one clock wide, at the correct period; `game_tick` changes between 60 and 90 Hz only at a wrap, with no missed or double pulse; `frame_60`, `tick_1s`, and `tick_4hz` don't change with `boost` |
| `kbd_decoder` | Arrow press and release, Space, `Z`, repeated press bytes, unknown codes ignored, `E0 F0` sequences, idle gaps between bytes |
| `input_ctrl` | One action per press despite key repeat; press between ticks isn't lost; overclock stays active while held |
| `chef_move` | Moves 16 px per tile step; blocked at walls and counters; new step only starts when aligned |
| `progress_timer` | Counts only when enabled, signals done once, clears on reset |
| `interact_decoder` | Every row of Section 3.6, plus sample unlisted combinations doing nothing; each Section 3.7 chef tile maps to the right station, all others to none |
| `stove_fsm` | Empty, cooking, cooked, burnt in order; removal at each stage; runs faster at 90 Hz |
| `order_mgr` | Match loads the next order, no match keeps the current order, no changes after game over |
| `score_bcd` | Carry at 90 + 10, saturates at 990 |
| `game_timer` | 2:00 to 1:59, 1:00 to 0:59, stops at 0:00 |
| `heat_ctrl` | Rises every `tick_4hz` while boosting; falls every second pulse otherwise; stops at 0; `heat_warn` from 24; one `meltdown` pulse at 31; ignores the key once frozen |
| `game_fsm` | Timeout and meltdown both stop play; Time Up wins on the same clock; reset clears all state, including `heat` |
| `tile_rom`, `map_rom` | Known addresses return the `.mif` values; data is valid exactly one clock after the address |
| `renderer` | Correct `plot` count per frame (76,800); first rows have expected x, y, colour; chef overrides background; transparency works |
| Integration | Scripted keypresses cook and serve a Burger, score reaches 10; holding `Z` reaches meltdown and keeps the score |

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
| Moore FSMs | `game_fsm`, `stove_fsm`, `heat_ctrl`, `chef_move`, renderer. Outputs depend only on state, which keeps them glitch-free and easy to read in waveforms. Use this as the default. |
| Mealy outputs | One-cycle pulses that depend on the current input, such as a press event in `kbd_decoder`. Use only where a Moore output would arrive a cycle late. |
| Sequence detectors | `kbd_decoder` (byte sequences) |
| State diagrams and state tables | Draw one per FSM before coding, then reuse them as slide block diagrams |
| Datapath and control separation | Renderer, `order_mgr`, `chef_move` |
| Shift registers | `lfsr16`, edge detector |
| Priority encoders | Arrow key priority |
| Decoders | Station from chef tile, recipe ID to mask |
| Comparators | Assembly mask against the current order, chef hit test, timer limits, heat warning and meltdown |

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
| LFSR randomness | `lfsr16` | Shift register with XOR feedback; for 16 bits use taps 16, 14, 13, 11. Give it a nonzero power-up value and leave it out of reset, so the time of the reset press seeds it. |
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
| **PS/2 keyboard** | Must plug into the board's PS/2 port. A USB keyboard needs an adapter and only works if the keyboard itself supports PS/2. Confirm with your TA. |
| Quartus Prime Lite 18.1 | Already installed |
| ModelSim | Already used |
| DESim | Optional, for testing VGA and keyboard without a board |
| Course downloads from the VGA Adapter page | `vga_adapter.zip`, `DE1-SoC.zip` (board examples), `MIF_c.zip`, and the DESim `object.zip` |
| Python with Pillow | For the asset converter |

### 12.2 Folder structure

```
overclocked/
  overclocked.qpf, overclocked.qsf     (pins from docs/reference/DE1_SoC.qsf)
  overclocked.sdc
  src/          top.v and one file per module
  src/vga_adapter/   Provided VGA adapter, kept separate for citation
  src/testbenches/   <module>_tb.v, one ModelSim testbench per module
  assets/       PNG art and generated .mif files
  tools/        Python converters
  docs/         PLAN.md, SCHEDULE.md, milestone PDFs, diagrams, slides
  docs/waves/   ModelSim waveform screenshots
  docs/reference/  DE1_SoC.qsf, the course pin file
  docs/archive/ Earlier plan and schedule drafts (not in git)
```

Keep `hex7seg` in one file. Your labs copied it into each part, which causes duplicate-module errors once everything is in a single project. Use git, since two people will edit this at once.

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
- [ ] Bugs and fixes (keep a running log)
- [ ] Future work
- [ ] Final work distribution
- [ ] Citations for the VGA adapter and PS/2 core
- [ ] Equal presenting time, fits 10 minutes with demo
- [ ] Backup video uploaded to Quercus

---

## 13. Summary block diagram

For the milestone PDFs and slides:

```
 PS/2 keyboard -> PS/2 core* -> Key decoder -> Chef movement -----+
 KEY, SW ------------------------------------> + collision        |
                                                                  v
 CLOCK_50 -> Tick generator (60 or 90 Hz) -> GAME LOGIC: interaction decoder,
                  ^ boost                    stove FSM, order manager,
 LFSR, Recipe ROM -------------------------> heat controller, score, timer, game FSM
                                                      |
                                                 game state
                                                      v
 Map ROM, Tile ROM -------------------------> Renderer FSM -> VGA adapter* -> Monitor
                                                      |
                                                      +-> HEX, LEDR    (* provided IP)
```

---

## 14. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Keyboard unavailable or unreliable | Medium | High | KEY/SW backup input from day one; `SW[9]` selects |
| Adapter ports differ from assumptions | Low | Medium | Check `vga_demo.v` and run `object`; the renderer's write interface is small and easy to change |
| Background MIF doesn't match resolution | Medium | Low | Generate a 320×240, 9-bit MIF (Section 5.1) |
| ROM latency errors garble tiles | High | Medium | Simulate a small tile first; use a test pattern with a unique colour per corner |
| ROM reads as X or zero in ModelSim | High | Low | Copy the `.mif` into the simulation folder (Section 5.3) |
| Integration bugs at the end | Medium | High | Agree on the bus early; integrate at each milestone, not only at the end |
| Long Quartus compiles | Medium | Low | Debug in ModelSim first, compile less often |
| Game too easy, with idle time at the stove | Medium | Medium | Raise cook time; second stove is the first stretch goal |
| Players avoid overclock because meltdown ends the run | Medium | Medium | Clear warning at heat 24; tune heat rates so short bursts feel safe |
| Tick rate change causes a missed or double pulse | Medium | Medium | Apply the new period only at a wrap; test in `sim/tick_gen/` |
| Chef tears during repaint at 90 Hz | Low | Low | Copy the chef position into registers at the start of each frame |
| Scope too large | Medium | High | Fallback tiers in Section 8.1 |
| Scope too small for the 3-lab minimum | Medium | High | Ask your TA "is this complex enough?" at Milestone 1; overclock carries the custom logic, and a second stove or three order slots are ready stretch goals |
| TA questions on unfamiliar code | Medium | High | Write your own code; do a walkthrough before every milestone |
