# Overclocked: Project Schedule

Week-by-week tasks from now to the final presentation. Design details are in [PLAN.md](PLAN.md), and file names here match it.

## Overview

| Period | Dates | Goal | Ends with |
|---|---|---|---|
| [Week 8](#week-8-nov-5-to-nov-8) | Nov 5 to 8 | Proposal, setup, confirm provided code | **Proposal, Fri Nov 6, midnight** |
| [Week 9](#week-9-nov-9-to-nov-15) | Nov 9 to 15 | Build and simulate video and input modules | Static kitchen on VGA, keys on HEX |
| [Week 10](#week-10-nov-16-to-nov-19) | Nov 16 to 19 | Integrate chef, keyboard, and video | **Milestone 1, Thu Nov 19** |
| [Week 11](#week-11-nov-19-to-nov-26) | Nov 19 to 26 | Build all game logic | **Milestone 2, Thu Nov 26** |
| [Week 12](#week-12-nov-27-to-dec-3) | Nov 27 to Dec 3 | Polish, tune, slides | **Presentation, Thu Dec 3** |

Three rules apply every week:

- **Simulate before compiling.** Every new module gets `sim/<module>/testbench.v` and `wave.do` before it goes on the board.
- **Save evidence as you go.** Store waveform screenshots in `docs/waves/` and add bugs to `docs/bug_log.md`. The milestone PDFs and slides need both.
- **Aim to finish a day early.** Milestone PDFs must be on Quercus before your lab period, so the target is the night before.

---

## Week 8: Nov 5 to Nov 8

**Goal:** submit the proposal, set up the project, and answer the open questions about the provided code.

### Submit

| ☐ | Task | Due |
|---|---|---|
| ☐ | Fill in names and finalize the draft from PLAN Section 13 | Fri Nov 6 |
| ☐ | Redraw the block diagram; fit everything on 1 page at 11 pt or larger | Fri Nov 6 |
| ☐ | Submit `docs/proposal.pdf` to Quercus | **Fri Nov 6, midnight** |

### Set up

| ☐ | Task |
|---|---|
| ☐ | Download `vga_adapter.zip`, `DE1-SoC.zip`, `MIF_c.zip`, and the DESim `object.zip` from the VGA Adapter page |
| ☐ | Download the PS/2 core and its PDF from the DE1-SoC IP cores page |
| ☐ | Get the memory lab's setup files, including `testbench.tcl` |
| ☐ | Ask the TA about PS/2 keyboard and VGA monitor access in the lab |
| ☐ | Start a git repository, if you are using one |

### Files

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/`, `src/ip/`, `assets/`, `tools/`, `sim/`, `docs/waves/` | Create | Folder structure from PLAN Section 12.2 |
| ☐ | `overclocked.qpf`, `overclocked.qsf` | Create | Quartus project, pins copied from `../DE1_SoC.qsf` |
| ☐ | `overclocked.sdc` | Create | 50 MHz `create_clock` |
| ☐ | `src/ip/` | Add | VGA adapter and PS/2 core |
| ☐ | `src/overclocked_top.v` | Create | Pin-level stub that compiles |
| ☐ | `src/overclocked_defs.vh` | Create | Shared item codes, tile IDs, and screen IDs |
| ☐ | `docs/bug_log.md` | Create | Running bug log for the slides |

### Tests

| ☐ | Run | Confirm |
|---|---|---|
| ☐ | `display_mif_pro` on board at 320×240, 9-bit | Image appears correctly |
| ☐ | Pro version of `object` on board | Keyboard moves an object; note how it handles `plot` and PS/2 data |
| ☐ | Memory lab Part I in ModelSim | `.mif` loads and read data arrives one clock after the address |

### Done when

- ☐ Proposal is submitted
- ☐ Real adapter ports, pixel write rate, and PS/2 signals are recorded in PLAN Section 1
- ☐ `overclocked_top.v` compiles with the provided cores

---

## Week 9: Nov 9 to Nov 15

**Goal:** build the modules for Milestone 1 and prove each one alone.

### Files

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/hex7seg.v` | Create | Single copy, from `lab4/part1.v` |
| ☐ | `src/tick_gen.v` | Create | `tick_60` and `tick_1s`, based on `counter_26b` in `lab4/part3.v` |
| ☐ | `src/kbd_decoder.v` | Create | Sequence detector, scan bytes to held-key flags |
| ☐ | `src/input_ctrl.v` | Create | Synchronizers, input select, press edges, latch until tick |
| ☐ | `src/chef_move.v` | Create | Tile position, direction, Idle and Step states |
| ☐ | `assets/tiles/*.png` | Create | Floor, counter, stations, 4 chef directions |
| ☐ | `assets/map_kitchen.txt` | Create | Kitchen layout from PLAN Section 3.7 |
| ☐ | `tools/make_mifs.py` | Create | PNGs and map text to `.mif` files |
| ☐ | `assets/tile_rom.mif`, `assets/map_rom.mif` | Generate | ROM contents |
| ☐ | `assets/background_320_9.mif` | Generate | Plain adapter background, using `bmp_to_mif` |
| ☐ | `src/ip/tile_rom.v`, `src/ip/map_rom.v` | Generate | IP Catalog ROMs with `q` register off |
| ☐ | `src/renderer.v` | Create | Pixel loop, base tile and chef layers |
| ☐ | `src/game_state_stub.v` | Create | Constant game state to drive the renderer |

### Simulations

| ☐ | Folder | Pass when |
|---|---|---|
| ☐ | `sim/tick_gen/` | Pulses are one clock wide at the right period, using scaled parameters |
| ☐ | `sim/kbd_decoder/` | Arrows, Space, repeats, `E0 F0` releases, and unknown codes all behave |
| ☐ | `sim/input_ctrl/` | One action per press despite key repeat; press between ticks isn't lost |
| ☐ | `sim/chef_move/` | 16 px per tile; turns but doesn't move at a wall; turns only when aligned |
| ☐ | `sim/tile_rom/`, `sim/map_rom/` | Known addresses match the `.mif`; data is valid one clock later |
| ☐ | `sim/renderer/` | First rows have correct x, y, and colour; 76,800 `plot` pulses per frame |

### Board tests

| ☐ | Test | Pass when |
|---|---|---|
| ☐ | Scan codes on HEX | Each key shows its Section 7.1 code |
| ☐ | Hold arrow + Space together | Both register; otherwise switch to WASD |
| ☐ | ROM scroll on HEX (memory lab Part IV idea) | Address and data match the `.mif` |
| ☐ | Renderer with `game_state_stub` | Static kitchen and chef appear with no shifted pixels |

### Done when

- ☐ All six simulation folders pass, with waveforms saved
- ☐ Static kitchen shows on VGA and keys show on HEX

**If behind:** finish `chef_move` and `renderer` first. Use a test-colour tile set and do the art later.

---

## Week 10: Nov 16 to Nov 19

**Goal:** combine video and input into the Milestone 1 demo. This week is only four days, so aim for Tuesday integration and Wednesday write-up.

### Files

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/overclocked_top.v` | Modify | Connect PS/2, `kbd_decoder`, `input_ctrl`, `chef_move`, `tick_gen`, `renderer`, and VGA adapter |
| ☐ | `src/renderer.v` | Modify | Read live chef position and direction |
| ☐ | `src/game_state_stub.v` | Modify | Keep constants only for signals not built yet |
| ☐ | `src/game_timer.v` | Create | BCD m:ss down-counter on HEX |
| ☐ | `overclocked.sdc` | Modify | Only if timing reports show a problem |
| ☐ | `docs/block_diagram.*` | Create | Top-level and sub-block diagrams |
| ☐ | `docs/milestone1.pdf` | Create | Milestone submission |

### Simulations

| ☐ | Folder | Pass when |
|---|---|---|
| ☐ | `sim/game_timer/` | 2:00 to 1:59, 1:00 to 0:59, stops at 0:00 |
| ☐ | `sim/m1_integration/` | Scripted scan bytes move the chef; renderer shows the new position |
| ☐ | Rerun all Week 9 folders | Still pass after the changes |

### Board tests

| ☐ | Test | Pass when |
|---|---|---|
| ☐ | Walk the whole kitchen | Movement is smooth, and the chef stops at every counter |
| ☐ | Face each direction | The correct sprite appears |
| ☐ | Backup controls with `SW[9]` | KEY buttons move the chef |
| ☐ | HEX displays | Timer counts down, last scan byte shows |
| ☐ | Quartus reports | Timing met at 50 MHz; ROMs in M10K blocks |

### Submit: Milestone 1

| ☐ | PDF item |
|---|---|
| ☐ | What each teammate accomplished, with block diagrams |
| ☐ | Demo code with an explanation of how it works |
| ☐ | ModelSim waveforms for `kbd_decoder`, `chef_move`, `tick_gen`, and `renderer` |
| ☐ | Any other in-progress code, with simulations |
| ☐ | Code walkthrough done, so you can each explain every module |
| ☐ | Submitted to Quercus **before your lab period on Thu Nov 19** |

### If you finish early

Start `src/progress_timer.v` and `src/interact_decoder.v`, which have no video dependency.

**If behind:** use the KEY buttons in the demo and keep debugging the keyboard in simulation. The spec allows code that isn't working on the board yet, as long as simulations show progress.

---

## Week 11: Nov 19 to Nov 26

**Goal:** make the full cooking loop playable on the board. This is the heaviest week, so it is split into two stages.

### Stage 1, Nov 19 to 22: build and simulate

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `src/progress_timer.v` | Create | Prescaler + 4-bit step counter, shared by chop, cook, and burn |
| ☐ | `src/interact_decoder.v` | Create | PLAN Section 3.6 table |
| ☐ | `src/kitchen_state.v` | Create | `held_item`, `held_mask`, and `assembly_mask` registers |
| ☐ | `src/board_fsm.v` | Create | Empty, raw, chopped |
| ☐ | `src/stove_fsm.v` | Create | Empty, cooking, cooked, burnt |
| ☐ | `src/lfsr16.v` | Create | Random recipe source |
| ☐ | `src/recipe_rom.v` | Create | Recipe to mask and patience |
| ☐ | `src/order_mgr.v` | Create | 3 slots, spawn, expiry, match |
| ☐ | `src/score_bcd.v` | Create | BCD score, built from the Lab 2 correction idea |
| ☐ | `src/game_fsm.v` | Create | Title, play, game over |

| ☐ | Simulation folder | Pass when |
|---|---|---|
| ☐ | `sim/progress_timer/` | Pauses when disabled, keeps progress, signals done once |
| ☐ | `sim/interact_decoder/` | Every Section 3.6 row works; unlisted combinations do nothing |
| ☐ | `sim/kitchen_state/` | Registers update only on tick with a valid action |
| ☐ | `sim/board_fsm/` | Chopping pauses on release; chopped item can be collected |
| ☐ | `sim/stove_fsm/` | Cooks then burns in order; removal works at each stage |
| ☐ | `sim/lfsr16/` | Never sticks at 0; sequence varies |
| ☐ | `sim/order_mgr/` | Spawn, full slots, expiry, match, lowest-slot priority, no match |
| ☐ | `sim/score_bcd/` | 900 + 100 carries; saturates at 9900 |
| ☐ | `sim/game_fsm/` | Start, timeout, restart clears all state |

### Stage 2, Nov 23 to 25: integrate on the board

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `assets/tiles/*.png` | Modify | Add items, digits, and ticket icons |
| ☐ | `assets/tile_rom.mif` | Regenerate | New tiles |
| ☐ | `src/hud_mux.v` | Create | Digits, tickets, and bars to tile IDs |
| ☐ | `src/renderer.v` | Modify | Add dynamic tile, held item, and bar layers |
| ☐ | `src/overclocked_top.v` | Modify | Connect all game logic |
| ☐ | `src/game_state_stub.v` | Delete | Replaced by real signals |
| ☐ | `docs/milestone2.pdf` | Create | Milestone submission |

| ☐ | Simulation folder | Pass when |
|---|---|---|
| ☐ | `sim/hud_mux/` | Correct tile IDs for digits and tickets |
| ☐ | `sim/renderer/` (rerun) | Layer order and transparency are correct; bar widths match progress |
| ☐ | `sim/integration/` | Scripted keys cook and serve a Burger, and score reaches 100 |

Bring features up on the board in this order, and keep a working `.sof` at each step:

| ☐ | Target date | Feature | Plan tier |
|---|---|---|---|
| ☐ | Nov 23 | Pickup, one station, one fixed recipe, serve, score | Tier 2 |
| ☐ | Nov 24 | Chop, cook, burn, game timer | Tier 3 |
| ☐ | Nov 25 | 3 slots, random orders, patience, game ends at 0:00 | Tier 4 |

### Submit: Milestone 2

| ☐ | PDF item |
|---|---|
| ☐ | What each teammate accomplished, with updated block diagrams |
| ☐ | Demo code with an explanation of how it works |
| ☐ | ModelSim waveforms for `interact_decoder`, `stove_fsm`, and `order_mgr`, plus other internals |
| ☐ | Any other in-progress code, with simulations |
| ☐ | Code walkthrough done |
| ☐ | Submitted to Quercus **before your lab period on Thu Nov 26** |

**If behind:** demo Tier 3 with a fixed order instead of random orders, and show `order_mgr` in simulation.

---

## Week 12: Nov 27 to Dec 3

**Goal:** finish the game, freeze it, and prepare the presentation.

### Nov 27 to 30: finish and tune

| ☐ | File | Action | Purpose |
|---|---|---|---|
| ☐ | `assets/map_title.txt`, `assets/map_gameover.txt` | Create | Title and game over layouts |
| ☐ | `assets/tiles/*.png` | Modify | Font letters, final art |
| ☐ | `assets/map_rom.mif`, `assets/tile_rom.mif` | Regenerate | Add screens and art |
| ☐ | `src/renderer.v`, `src/hud_mux.v` | Modify | Screen select, final score on game over |
| ☐ | `src/overclocked_defs.vh` | Modify | Tuned timing constants |
| ☐ | `src/streak_detector.v`, `src/code_detector.v` | Create (optional) | Only if everything else works |

| ☐ | Simulation or test | Pass when |
|---|---|---|
| ☐ | `sim/game_fsm/` (rerun) | Title, play, game over, and restart show the right `screen` |
| ☐ | `sim/integration/` (rerun) | Still passes after tuning |
| ☐ | `sim/streak_detector/`, `sim/code_detector/` (if built) | Fires once on a match; overlaps handled |
| ☐ | Playtest 5 or more full games | Good play scores well; the Deluxe is achievable |
| ☐ | Restart test | 3 games in a row work without pressing reset |
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

**If behind:** ship the last working tier. Title and game over screens are the first thing to cut, as long as the game still restarts with reset.
