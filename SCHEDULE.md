# Overclocked: Project Schedule

Week-by-week tasks to the final presentation, for the final scope: overclock in, chopping and order patience cut. Design details are in [PLAN.md](PLAN.md), and file names here match it. Earlier drafts are in [archive/](archive/).

Updated Sat Nov 14, at the end of Week 9.

## Overview

| Period | Dates | Goal | Ends with |
|---|---|---|---|
| [Week 8](#week-8-nov-5-to-nov-8-carry-over) | Nov 5 to 8 | Proposal, setup, confirm provided code | Proposal submitted Nov 6 |
| [Week 9](#week-9-nov-9-to-nov-15) | Nov 9 to 15 | Build and simulate video and input modules | Static kitchen on VGA, keys on HEX |
| [Week 10](#week-10-nov-16-to-nov-19) | Nov 16 to 19 | Integrate chef, keyboard, boost, and video | **Milestone 1, Thu Nov 19** |
| [Week 11](#week-11-nov-19-to-nov-26) | Nov 19 to 26 | Build all game logic, including `heat_ctrl` | **Milestone 2, Thu Nov 26** |
| [Week 12](#week-12-nov-27-to-dec-3) | Nov 27 to Dec 3 | Finish overclock, polish, tune, slides | **Presentation, Thu Dec 3** |

Three rules apply every week:

- **Simulate before compiling.** Every new module gets `sim/<module>/testbench.v` and `wave.do` before it goes on the board. Trivial modules such as `hex7seg` and `hud_mux` can rely on integration simulation.
- **Save evidence as you go.** Store waveform screenshots in `docs/waves/` and add bugs to `docs/bug_log.md`. The milestone PDFs and slides need both.
- **Aim to finish a day early.** Milestone PDFs must be on Quercus before your lab period, so the target is the night before.

**What the rescope changes in this schedule.** `board_fsm` and its simulation are gone. Item art drops to six items, and the map loses the board tile. The stove and progress timer move to Member B, and the game timer moves to Member A (PLAN Section 9). The time saved goes to putting `heat_ctrl` on the board in Week 11 instead of Week 12.

---

## Week 8: Nov 5 to Nov 8 (carry over)

The proposal is in. Finish anything below that isn't done before starting Week 10 integration.

### Set up

| ☐ | Task |
|---|---|
| ☐ | Download `vga_adapter.zip`, `DE1-SoC.zip`, `MIF_c.zip`, and the DESim `object.zip` from the VGA Adapter page |
| ☐ | Download the PS/2 core and its PDF from the DE1-SoC IP cores page |
| ☐ | Get the memory lab's setup files, including `testbench.tcl` |
| ☐ | Ask the TA about PS/2 keyboard and VGA monitor access in the lab |
| ☐ | Start a git repository |

### Files

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/`, `src/ip/`, `assets/`, `tools/`, `sim/`, `docs/waves/` | Create | Folder structure from PLAN Section 12.2 |
| ☐ | `overclocked.qpf`, `overclocked.qsf` | Create | Quartus project, pins copied from `../DE1_SoC.qsf` |
| ☐ | `overclocked.sdc` | Create | 50 MHz `create_clock` |
| ☐ | `src/ip/` | Add | VGA adapter and PS/2 core |
| ☐ | `src/overclocked_top.v` | Create | Pin-level stub that compiles |
| ☐ | `src/overclocked_defs.vh` | Create | Shared item codes (PLAN Section 3.5) and tile IDs |
| ☐ | `docs/bug_log.md` | Create | Running bug log for the slides |

### Tests

| ☐ | Run | Confirm |
|---|---|---|
| ☐ | `display_mif_pro` on board at 320×240, 9-bit | Image appears correctly |
| ☐ | Pro version of `object` on board | Keyboard moves an object; note how it handles `plot` and PS/2 data |
| ☐ | Memory lab Part I in ModelSim | `.mif` loads and read data arrives one clock after the address |

### Done when

- ☐ Real adapter ports, pixel write rate, and PS/2 signals are recorded in PLAN Section 1
- ☐ `overclocked_top.v` compiles with the provided cores
- ☐ Game state bus (PLAN Section 6.1) agreed by both members

---

## Week 9: Nov 9 to Nov 15

**Goal:** build the modules for Milestone 1 and prove each one alone. Anything unfinished by Sunday night carries into Monday Nov 16.

### Files

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/hex7seg.v` | Create | Single copy, from `lab4/part1.v` |
| ☐ | `src/tick_gen.v` | Create | `game_tick` (60 or 90 Hz), `frame_60`, `tick_1s`, and `tick_4hz`, based on `counter_26b` in `lab4/part3.v` |
| ☐ | `src/kbd_decoder.v` | Create | Sequence detector, scan bytes to held-key flags for arrows, Space, and `Z` |
| ☐ | `src/input_ctrl.v` | Create | Synchronizers, input select, Space press edge, latch until tick, held overclock flag |
| ☐ | `src/chef_move.v` | Create | Tile position, direction, walk frame, Idle and Step states |
| ☐ | `assets/tiles/*.png` | Create | Floor, counter, crates, stove, assembly, trash, 8 chef sprites (4 directions × 2 walk frames) |
| ☐ | `assets/map_kitchen.txt` | Create | Kitchen layout from PLAN Section 3.7 (no board tile) |
| ☐ | `tools/make_mifs.py` | Create | PNGs and map text to `.mif` files |
| ☐ | `assets/tile_rom.mif`, `assets/map_rom.mif` | Generate | ROM contents |
| ☐ | `assets/background_320_9.mif` | Generate | Plain adapter background, using `bmp_to_mif` |
| ☐ | `src/ip/tile_rom.v`, `src/ip/map_rom.v` | Generate | IP Catalog ROMs with `q` register off |
| ☐ | `src/renderer.v` | Create | Pixel loop, base tile and chef layers |
| ☐ | `src/game_state_stub.v` | Create | Constant game state to drive the renderer |

### Simulations

| ☐ | Folder | Pass when |
|---|---|---|
| ☐ | `sim/tick_gen/` | Pulses are one clock wide at the right period, using scaled parameters; `game_tick` changes rate only at a wrap; other pulses ignore `boost` |
| ☐ | `sim/kbd_decoder/` | Arrows, Space, `Z`, repeats, `E0 F0` releases, and unknown codes all behave |
| ☐ | `sim/input_ctrl/` | One action per press despite key repeat; press between ticks isn't lost; overclock stays active while held |
| ☐ | `sim/chef_move/` | 16 px per tile; turns but doesn't move at a wall; turns only when aligned; walk frame toggles while stepping |
| ☐ | `sim/tile_rom/`, `sim/map_rom/` | Known addresses match the `.mif`; data is valid one clock later |
| ☐ | `sim/renderer/` | First rows have correct x, y, and colour; 76,800 `plot` pulses per frame |

### Board tests

| ☐ | Test | Pass when |
|---|---|---|
| ☐ | Scan codes on HEX | Each key shows its PLAN Section 7.1 code |
| ☐ | Hold arrow + Space + `Z` together | All three register; otherwise switch to WASD and `M` |
| ☐ | ROM scroll on HEX (memory lab Part IV idea) | Address and data match the `.mif` |
| ☐ | Renderer with `game_state_stub` | Static kitchen and chef appear with no shifted pixels |

### Done when

- ☐ All six simulation folders pass, with waveforms saved
- ☐ Static kitchen shows on VGA and keys show on HEX

**If behind:** finish `chef_move` and `renderer` first. Use a test-colour tile set and do the art later.

---

## Week 10: Nov 16 to Nov 19

**Goal:** combine video, input, and boost into the Milestone 1 demo. This week is only four days, so aim for Tuesday integration and Wednesday write-up.

### Files

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/overclocked_top.v` | Modify | Connect PS/2, `kbd_decoder`, `input_ctrl`, `chef_move`, `tick_gen`, `renderer`, and VGA adapter; wire the held overclock flag straight to `boost` for now |
| ☐ | `src/renderer.v` | Modify | Read live chef position and direction |
| ☐ | `src/game_state_stub.v` | Modify | Keep constants only for signals not built yet |
| ☐ | `src/game_timer.v` | Create | BCD m:ss down-counter on HEX |
| ☐ | `overclocked.sdc` | Modify | Only if timing reports show a problem |
| ☐ | `docs/block_diagram.*` | Create | Top-level and sub-block diagrams, from PLAN Section 13 |
| ☐ | `docs/milestone1.pdf` | Create | Milestone submission |

### Simulations

| ☐ | Folder | Pass when |
|---|---|---|
| ☐ | `sim/game_timer/` | 2:00 to 1:59, 1:00 to 0:59, stops at 0:00 |
| ☐ | `sim/m1_integration/` | Scripted scan bytes move the chef; renderer shows the new position; holding `Z` raises `game_tick` to 90 Hz |
| ☐ | Rerun all Week 9 folders | Still pass after the changes |

### Board tests

| ☐ | Test | Pass when |
|---|---|---|
| ☐ | Walk the whole kitchen | Movement is smooth, and the chef stops at every counter |
| ☐ | Face and walk each direction | The correct sprite and walk animation appear |
| ☐ | Hold `Z` while walking | Chef moves 1.5× faster; speed returns on release; picture stays stable |
| ☐ | Backup controls with `SW[9]` | KEY buttons move the chef; `SW[8]` boosts |
| ☐ | HEX displays | Timer counts down, last scan byte shows |
| ☐ | Quartus reports | Timing met at 50 MHz; ROMs in M10K blocks |

### Submit: Milestone 1

| ☐ | PDF item |
|---|---|
| ☐ | What each teammate accomplished, with block diagrams |
| ☐ | Note on the scope change since the proposal (PLAN Section 13) |
| ☐ | Demo code with an explanation of how it works |
| ☐ | ModelSim waveforms for `kbd_decoder`, `chef_move`, `tick_gen`, and `renderer` |
| ☐ | Any other in-progress code, with simulations |
| ☐ | Code walkthrough done, so you can each explain every module |
| ☐ | Submitted to Quercus **before your lab period on Thu Nov 19** |

### If you finish early

Start `src/progress_timer.v`, `src/interact_decoder.v`, and `src/heat_ctrl.v`, which have no video dependency.

**If behind:** use the KEY buttons in the demo and keep debugging the keyboard in simulation. The spec allows code that isn't working on the board yet, as long as simulations show progress.

---

## Week 11: Nov 19 to Nov 26

**Goal:** make the full cooking loop playable on the board, with `heat_ctrl` on the board if time allows. This is the heaviest week, so it is split into two stages.

### Stage 1, Nov 19 to 22: build and simulate

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/progress_timer.v` | Create | Prescaler + 4-bit step counter, used for cook and burn |
| ☐ | `src/interact_decoder.v` | Create | PLAN Section 3.6 table |
| ☐ | `src/kitchen_state.v` | Create | `held_item` and `assembly_mask` registers |
| ☐ | `src/stove_fsm.v` | Create | Empty, cooking, cooked, burnt |
| ☐ | `src/heat_ctrl.v` | Create | Normal and boost states, heat counter, warning, meltdown |
| ☐ | `src/lfsr16.v` | Create | Random recipe source |
| ☐ | `src/recipe_rom.v` | Create | Recipe to mask, PLAN Section 3.4 |
| ☐ | `src/order_mgr.v` | Create | Current order, match, load next |
| ☐ | `src/score_bcd.v` | Create | BCD score, built from the Lab 2 correction idea |
| ☐ | `src/game_fsm.v` | Create | Play, time up, meltdown |

| ☐ | Simulation folder | Pass when |
|---|---|---|
| ☐ | `sim/progress_timer/` | Counts only when enabled, signals done once, clears on reset |
| ☐ | `sim/interact_decoder/` | Every PLAN Section 3.6 row works; unlisted combinations do nothing |
| ☐ | `sim/kitchen_state/` | Registers update only on tick with a valid action |
| ☐ | `sim/stove_fsm/` | Cooks then burns in order; removal works at each stage; faster at 90 Hz |
| ☐ | `sim/heat_ctrl/` | Rise and fall rates correct; stops at 0; `heat_warn` from 24; one `meltdown` pulse at 31; key ignored once frozen |
| ☐ | `sim/lfsr16/` | Never sticks at 0; sequence varies |
| ☐ | `sim/order_mgr/` | Match loads next order; no match keeps it; no changes after game over |
| ☐ | `sim/score_bcd/` | 90 + 10 carries; saturates at 990 |
| ☐ | `sim/game_fsm/` | Timeout and meltdown both stop play; Time Up wins on the same clock; reset clears all state |

### Stage 2, Nov 23 to 25: integrate on the board

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `assets/tiles/*.png` | Modify | Add the six items and four order icons |
| ☐ | `assets/tile_rom.mif` | Regenerate | New tiles |
| ☐ | `src/hud_mux.v` | Create | Current order to icon tile ID |
| ☐ | `src/renderer.v` | Modify | Add dynamic tile, held item, and cook, burn, and heat bar layers |
| ☐ | `src/overclocked_top.v` | Modify | Connect all game logic |
| ☐ | `src/game_state_stub.v` | Delete | Replaced by real signals |
| ☐ | `docs/milestone2.pdf` | Create | Milestone submission |

| ☐ | Simulation folder | Pass when |
|---|---|---|
| ☐ | `sim/renderer/` (rerun) | Layer order and transparency are correct; bar widths match progress and heat |
| ☐ | `sim/integration/` | Scripted keys cook and serve a Burger, and score reaches 10 |

Bring features up on the board in this order, and keep a working `.sof` at each step:

| ☐ | Target date | Feature | Plan tier |
|---|---|---|---|
| ☐ | Nov 23 | Pickup, assembly, one fixed recipe, serve, score | Tier 2 |
| ☐ | Nov 24 | Stove with cook and burn, game timer | Tier 3 |
| ☐ | Nov 25 | Random orders, game ends at 0:00 | Tier 4 |
| ☐ | Nov 25, if time | `heat_ctrl` replaces the direct `boost` wire; heat bar; meltdown | Tier 5 |

If Tier 5 slips, `heat_ctrl` appears in Milestone 2 as simulation only and goes on the board first thing in Week 12.

### Submit: Milestone 2

| ☐ | PDF item |
|---|---|
| ☐ | What each teammate accomplished, with updated block diagrams |
| ☐ | Demo code with an explanation of how it works |
| ☐ | ModelSim waveforms for `interact_decoder`, `stove_fsm`, `order_mgr`, and `heat_ctrl`, plus other internals |
| ☐ | Any other in-progress code, with simulations |
| ☐ | Code walkthrough done |
| ☐ | Submitted to Quercus **before your lab period on Thu Nov 26** |

**If behind:** demo Tier 3 with a fixed order instead of random orders, and show `order_mgr` and `heat_ctrl` in simulation.

---

## Week 12: Nov 27 to Dec 3

**Goal:** finish overclock on the board, tune the game, freeze it, and prepare the presentation.

### Nov 27 to 30: finish and tune

If Tier 5 isn't on the board yet, do it first, on Nov 27. It is what sets this game apart.

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/overclocked_top.v` | Modify | Connect `heat_ctrl` to `tick_gen` and `game_fsm`, if not done in Week 11 |
| ☐ | `src/renderer.v` | Modify | Flashing heat warning, if not done in Week 11 |
| ☐ | `assets/tiles/*.png` | Modify | Final art |
| ☐ | `assets/tile_rom.mif` | Regenerate | Add final art |
| ☐ | `src/overclocked_defs.vh` | Modify | Tuned cook, burn, and heat constants |
| ☐ | Stretch goals from PLAN Section 8.1 | Create (optional) | Only if everything else works; second stove first |

| ☐ | Simulation or test | Pass when |
|---|---|---|
| ☐ | `sim/game_fsm/` (rerun) | Timeout and meltdown freeze the game; reset starts a clean game |
| ☐ | `sim/integration/` (rerun) | Still passes after tuning; holding `Z` reaches meltdown and keeps the score |
| ☐ | Playtest 5 or more full games | Good play scores well; burn timing feels fair; waiting at the stove doesn't feel dead |
| ☐ | Overclock playtest | Boosting through a cook feels worthwhile; holding too long causes a meltdown; the warning gives time to react |
| ☐ | Restart test | 3 games in a row restart cleanly with reset, including after a meltdown; heat starts at 0 |
| ☐ | Quartus reports | Timing still met; no unexpected warnings |

**Feature freeze: Mon Nov 30.** After this date, fix bugs only.

### Dec 1 to 3: present

| ☐ | Task | Target |
|---|---|---|
| ☐ | Tag or back up the final code and `.sof` | Dec 1 |
| ☐ | Take photos and record a backup demo video | Dec 1 |
| ☐ | Finish `docs/slides` using the list below | Dec 1 |
| ☐ | Rehearse with a timer, splitting speaking time equally | Dec 2 |
| ☐ | Practice answering TA questions on each other's code | Dec 2 |
| ☐ | Upload slides and backup video to Quercus | **Before your lab period, Thu Dec 3** |
| ☐ | Bring the keyboard and a copy of the `.sof` | Dec 3 |

### Slide contents

| ☐ | Slide item |
|---|---|
| ☐ | Complete project description, crediting Overcooked |
| ☐ | High-level block diagram: inputs, datapath, outputs |
| ☐ | Detailed block diagrams, including FSM state diagrams |
| ☐ | Photos of the project working |
| ☐ | Bugs and fixes, from `docs/bug_log.md` |
| ☐ | Future work |
| ☐ | Final work distribution |
| ☐ | Citations for the VGA adapter, examples, PS/2 core, and `bmp_to_mif` |

**If behind:** ship the last working tier. Finish overclock before polish, since it is what sets this game apart.

---

## Task distribution

Member A leads video, orders, score, and game flow. Member B leads input, interactions, cooking, and overclock. Both members draw art, and each member simulates the code they write.

### Week 8

- **Member A:** set up the Quartus project; test the provided VGA code and memory lab on the board
- **Member B:** set up the project folders and starter code; test the provided keyboard code on the board
- **Both:** agree on an art style and the game state bus

### Week 9

- **Member A:** code the renderer and ROMs; draw the floor and counter tiles
- **Member B:** code the keyboard input, game ticks with boost, and chef movement; draw the chef sprites and station tiles

### Week 10

- **Member A:** show the moving chef on screen; code the game timer; draw the block diagrams
- **Member B:** connect the keyboard to chef movement; add the overclock key
- **Both:** integrate and test the Milestone 1 demo; write the milestone PDF

### Week 11

- **Member A:** code the order system, scoring, order display, and game flow; add the new renderer layers, including the heat bar; draw the order icons
- **Member B:** code the interactions, kitchen state, progress timer, stove, and heat controller; connect the game logic; draw the food items
- **Both:** integrate and test the full cooking loop; write the milestone PDF

### Week 12

- **Member A:** add the heat warning flash if needed; polish the kitchen and item art; fix video bugs; take project photos
- **Member B:** finish overclock on the board; tune cook, burn, and heat; test restarts; polish the chef and station art; record the backup demo
- **Both:** playtest; fix bugs; make the slides; rehearse the presentation
