# TraceTen — Report Draft

> **Status:** Work in progress. Sections: Introduction, Game Modes, Special Tiles & Power-ups, Scoring System, Analysis & Design, Conclusion.

---

## Writing Notes

### Đã viết
- [x] Section 1 — Introduction (overview, motivation, tech stack) — 2026-05-13
- [x] Section 2 — Game Modes (Classic, Zen, Gravity, Mutation, Challenge + 12-level table) — 2026-05-13
- [x] Section 3 — Special Tiles & Power-up System — 2026-05-13
- [x] Section 4 — Scoring System (calculate_points, density rule, combo, end-game, scan algorithm) — 2026-05-13
- [x] Section 5 — Analysis & Design (Use Case, architecture, class hierarchy, algorithms) — 2026-05-18
- [x] Section 5.6 — Audio & Visual Feedback (AudioManager, SFX, VFX) — 2026-05-20
- [x] Section 6 — Conclusion & Future Work (draft) — 2026-05-18

### Còn thiếu

**Viết được ngay (không phụ thuộc code hay APK):**
- [ ] **Cơ sở lý thuyết** — viết trong T7
  - Godot 4: scene tree, node lifecycle (`_ready`, `_process`), signal system, AutoLoad singleton
  - GDScript: so sánh ngắn với Python/C# — tại sao phù hợp với Godot, dynamic typing, built-in Vector2/Dictionary
  - Mobile game design: touch input model, dynamic layout (tự tính tile_size theo màn hình), local persistence (user://)
  - Puzzle game design: tại sao sum-to-10 (đủ đơn giản để hiểu ngay, đủ sâu để chiến lược), so sánh với 2048/Candy Crush

**Phải đợi T8 (sau khi có APK + test thiết bị thật):**
- [ ] **Kết quả & Đánh giá** — viết sau T8
  - Screenshot gameplay mỗi mode (Classic, Zen, Gravity, Mutation, Challenge) trên thiết bị thật
  - Screenshot achievement screen, highscore screen, tutorial
  - APK build info: target SDK, tested devices, file size
  - Playtest notes: balance có ổn không, bug còn sót, UX trên màn hình nhỏ
  - Bảng so sánh trước/sau nếu có vấn đề đáng ghi nhận

**Công việc format (T9):**
- [ ] Hỏi thầy/khoa về template chính thức trước khi format lại toàn bộ
- [ ] Gộp các section đã viết vào template, chỉnh số chương/mục cho khớp
- [ ] Section 4 (Scoring) + một phần Section 5 (Triển khai) có thể gộp thành chương "Triển khai" tùy template yêu cầu
- [ ] Thêm hình minh họa: class diagram BaseTile hierarchy, sơ đồ chuyển cảnh, Use Case diagram (vẽ bằng draw.io hoặc Mermaid)

### Reminders khi viết tiếp
- Bảng scene/script (main.gd, tile_factory.gd, global.gd...) đã có sẵn trong CLAUDE.md — copy + expand
- Gravity `total_duration` thay đổi động là **intentional** — cần giải thích rõ trong phần triển khai
- `scan_board_for_valid_moves()` O(n⁴) — đã viết ở Section 4.4, tham chiếu lại khi viết phần Thiết kế
- DEBUG_MODE phải `false` trước build APK — nhắc trong phần Kết quả/build
- Smart Board Generator (`zen_board_generator.gd`) đảm bảo 100% solvable — worth highlighting trong Triển khai

---

## 1. Introduction

### 1.1 Overview

TraceTen is a minimalist 2D logic puzzle game developed for the Android platform. The core mechanic is simple: the player drags to select a rectangular region on an 8×12 grid of numbered tiles, and the selection is accepted only when the sum of all tile values inside equals exactly **10**. Every valid selection clears those tiles, earns points, and the grid refills. The challenge lies in finding valid rectangles quickly and chaining them for combo bonuses before time runs out or valid moves disappear.

The game is built with **Godot 4** and written entirely in **GDScript**. It runs as a local-only application — no network connectivity is required — and all progress is stored on the device via JSON save files.

### 1.2 Motivation

Casual puzzle games on mobile tend to cluster around two archetypes: match-3 games (Candy Crush) that rely heavily on luck, and number games (2048, Sudoku) that demand sustained concentration. TraceTen aims for a middle ground — a number puzzle that is immediately understandable (sum to 10) yet rewards spatial thinking and pattern recognition over raw arithmetic.

The project also serves as a practical study of:
- **Game architecture in Godot 4:** scene/script separation, Autoload singletons, signal-driven communication between nodes.
- **Data-driven design:** tile types, level constraints, and gacha probabilities defined as configuration data rather than scattered constants.
- **Mobile UX challenges:** dynamic layout for varying screen sizes, touch input handling, persistent save/load, and a UI that stays readable at small tile sizes.

### 1.3 Technical Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Engine | Godot 4.x | Free, open-source; strong 2D tooling; GDScript is approachable for rapid prototyping |
| Language | GDScript | First-class in Godot; Python-like syntax reduces boilerplate |
| Target platform | Android | Dominant mobile OS; Godot's one-click export pipeline |
| Persistence | Local JSON (`user://`) | No server dependency; readable/debuggable format |
| Version control | Git | Standard; tagged releases per development sprint |

---

## 2. Game Modes

TraceTen ships with five distinct game modes. Each mode reuses the same board and input system but imposes different goals, constraints, and failure conditions. All modes share the combo multiplier system (see Section 4).

### 2.1 Classic Mode

**Goal:** Maximize score before the timer expires.

**Rules:**
- 120-second countdown. The timer runs continuously — it does not pause when the player pauses or minimizes the app.
- No special tiles; the board is filled with normal numbered tiles (values 1–9).
- The board is guaranteed solvable at start: the generator retries up to 5 times until `scan_board_for_valid_moves()` returns `true`.
- When no valid moves remain *and* all power-ups are exhausted, the game ends early (`NO_MOVES`).
- Pressing **Leave** in the pause menu triggers the game-over summary (score is submitted to the highscore table).

**End conditions:** `TIME_UP` (timer hits 0) or `NO_MOVES`.

### 2.2 Zen Mode

**Goal:** Accumulate score indefinitely with no time pressure.

**Rules:**
- Count-up timer (tracks total play time). The timer pauses when the game is paused.
- No failure condition from time. The game ends only if there are no valid moves *and* all power-ups are used up.
- **Power-up refill milestone:** every 100 points accumulated grants **+1 Hint, +1 Shuffle, +1 Remove** (stackable, tracked by `zen_milestone_count`).
- Full save/load support: the board state, score, timer, and power-up counts are saved to `user://save_zen.json` on pause or leave. The player can resume in a future session via a **Continue** prompt.
- Leaving does not trigger a game-over — the save file is preserved.

**End conditions:** `NO_MOVES` only (no time limit).

### 2.3 Gravity Mode

**Goal:** Survive as long as possible against a countdown while tiles fall in a shifting direction.

**Rules:**
- 150-second countdown. The timer pauses when the game is paused.
- After each valid selection, cleared tiles are removed and the remaining tiles "fall" in the current gravity direction. When 70% or more of the board has been cleared, **all** empty cells are refilled with new random tiles.
- Each tile cleared adds **+1 second** to the countdown (intentional design; `total_duration` is mutated dynamically).
- **Lives system:** The player has 3 lives (`shuffle_count = 3`). Each use of the Shuffle power-up costs one life. When lives reach 0, the game ends immediately (`NO_LIVES`).
- **Four gravity levels** based on score thresholds:

  | Level | Score range | Gravity direction |
  |-------|-------------|-------------------|
  | Lv.1  | 0 – 49      | Down              |
  | Lv.2  | 50 – 99     | Right             |
  | Lv.3  | 100 – 149   | Left              |
  | Lv.4  | ≥ 150       | Random (up/down/left/right changes each move) |

- Level transitions are accompanied by a label flash animation.
- Pressing **Leave** submits the score and shows the game-over summary.

**End conditions:** `TIME_UP`, `NO_LIVES`, or `NO_MOVES`.

### 2.4 Mutation Mode

**Goal:** Maximize score in a count-up session using special tiles that provide bonus points.

**Rules:**
- Count-up timer; pauses on game pause.
- The board contains a mix of normal and special tiles (Joker, Virus, Mystery, Negative — described in Section 3).
- Special tiles grant **bonus points** when included in a valid selection (see Section 4.2).
- Board refill: when 70% or more of the board has been cleared, all empty cells are refilled (same trigger as Zen). **No** power-up milestone refill in Mutation.
- Full save/load support via `user://save_mutation.json`.

**End conditions:** `NO_MOVES` only.

### 2.5 Challenge Mode

**Goal:** Progress through 12 thematic levels by accumulating score, with each level adding a **shape constraint** that valid selections must satisfy.

**Rules:**
- Mechanically identical to Zen (count-up, pause-aware timer, refill milestone, save/load).
- Each of the 12 levels defines a **constraint** on the bounding box and/or tile count of a valid selection. A selection that sums to 10 but violates the constraint is rejected with a "Wrong shape!" message and resets the combo.
- Score is **cumulative across levels** — it never resets when switching levels. This allows the player to unlock future levels early by earning bonus score on lower levels.
- **Level unlock:** each level has a score threshold. Once the running total exceeds that threshold, the level is unlocked and becomes accessible via the pause menu or the HUD's level-switch button.
- **No forced progression:** the player decides when to switch levels. Staying on an earlier level is always valid.
- The board is regenerated each time a new level is entered, using the **Smart Board Generator** (Section 3.3) to guarantee at least one valid move satisfying the new constraint.
- Save/load via `user://save_challenge.json`, which additionally stores `current_level` and `unlocked_levels`.

**The 12 Challenge levels:**

| # | Name | Unlock score | Constraint |
|---|------|-------------|------------|
| 1 | Meadow | 0 | `tile_count ≥ 3` |
| 2 | Forest | 50 | `tile_count ≥ 3` AND `bbox_area ≥ 4` |
| 3 | Riverside | 150 | Bounding box must be square (≥ 2×2) AND `tile_count ≥ 3` |
| 4 | Ocean Shore | 300 | `tile_count ≥ 4` AND `bbox_area ≥ 6` |
| 5 | Deep Sea | 500 | `bbox ≥ 2×3` (or 3×2) AND `tile_count ≥ 4` |
| 6 | Coral Reef | 750 | Bounding box must be square ≥ 3×3 AND `tile_count ≥ 5` |
| 7 | Desert | 1000 | `tile_count ≥ 5` AND `bbox_area ≥ 8` |
| 8 | Canyon | 1300 | `bbox ≥ 3×3` (any aspect) AND `tile_count ≥ 5` |
| 9 | Mountain | 1700 | `tile_count ≥ 6` AND `bbox_area ≥ 9` |
| 10 | Snow Peak | 2200 | `bbox_area ≥ 12` AND `tile_count ≥ 6` |
| 11 | Aurora | 2800 | `tile_count ≥ 7` AND `bbox_area ≥ 12` |
| 12 | Cosmos | 3500 | `bbox_area ≥ 16` AND `tile_count ≥ 8` |

**End conditions:** `NO_MOVES` only (same as Zen).

---

## 3. Special Tiles and Power-up System

### 3.1 Special Tiles

Special tiles are the core novelty of Mutation Mode and appear in Challenge Mode depending on level configuration. They are defined as subclasses of `BaseTile` (`tile.gd`) and instantiated by `TileFactory`.

#### 3.1.1 Joker Tile

The Joker tile displays as **0** and contributes a value of 0 toward the running sum while the player is dragging a selection. When the player releases and the selection is evaluated, the game calculates the *needed* value:

```
needed = 10 − (sum of all non-Joker tiles in the selection)
```

If `needed` falls within the range **[−9, 9]**, the selection is treated as valid (sum equals 10). If `needed` is outside this range, the selection is rejected with an "OVERLOAD" message.

This design lets the Joker serve as a flexible bridge between any numbers, without being able to compensate for arbitrarily large or small sums. Including a Joker in a valid selection grants a **+5 bonus** to the base score (Mutation Mode only).

#### 3.1.2 Virus Tile

The Virus tile is displayed in **green-yellow** and a visible countdown. Every **10 seconds**, the tile mutates: its value is re-rolled according to the following probability distribution:

| Outcome | Probability | New value range |
|---------|-------------|-----------------|
| Positive | 65% | 1–9 |
| Mild negative | 30% | −5 to −1 |
| Strong negative | ~4.7% | −9 to −6 |
| Zero (explosion) | ~0.3% | 0 |

If the Virus reaches **0** and the player has not cleared it, the tile **explodes**: it is permanently removed from the grid, leaving a hole. That hole disrupts bounding-box calculations for any selection that would span across it, forcing the player to work around the gap for the rest of the session.

Clearing a Virus tile (before it explodes) grants a **+10 bonus** (Mutation Mode only). The Virus timer respects the game's pause state — it does not tick while the game is paused.

#### 3.1.3 Mystery Tile

The Mystery tile displays a **"?"** instead of its actual value. The value is hidden until the player interacts with the tile — either by tapping it directly or by dragging a selection that passes over it. Once revealed, the tile behaves like a normal numbered tile for the remainder of the session.

This introduces an information asymmetry: the player must "spend" a drag to discover the value, at which point the running sum display updates to reflect the real number. Including a Mystery tile in a valid selection grants a **+2 bonus** (Mutation Mode only).

#### 3.1.4 Negative Tile

The Negative tile carries a **negative integer value** (typically −1 to −5) and is rendered in red. It functions as a normal tile in all mechanical respects — it contributes its (negative) value to the selection sum and participates in bounding-box calculations. Its purpose is to enable valid selections that would otherwise be impossible: a region containing a large positive number (e.g., 8 or 9) can be balanced by pairing it with a negative tile.

Including a Negative tile in a valid selection grants a **+3 bonus** (Mutation Mode only).

#### 3.1.5 Tile Factory and Spawn Rates

Tile types are determined by `TileFactory.roll(mode)`, which selects a type according to per-mode probability weights:

| Mode | Normal | Joker | Virus | Mystery | Negative |
|------|--------|-------|-------|---------|----------|
| Classic / Gravity | 100% | — | — | — | — |
| Zen | ~100% | — | — | — | — |
| Mutation | ~60% | 10% | 15% | 10% | 5% |
| Challenge | Varies by level config | | | | |

Normal tiles use a **weighted distribution** for their numeric value (1–9), biasing toward lower numbers (values 1–5 collectively account for approximately 71% of spawns) to keep the board solvable without requiring large-span selections.

### 3.2 Power-up System

Three power-ups are available across all modes. They are represented as integer counts (stackable) rather than binary flags.

#### Hint

Highlights a valid rectangular region on the board. The hint algorithm (`find_hint_path()`) iterates over all possible rectangle corners in O(n⁴) time with an early exit on the first valid match. In Challenge Mode, the hint only surfaces rectangles that also satisfy the current level's shape constraint.

Starting counts: 3 (Classic/Gravity) / increases each 100-point milestone (Zen/Challenge only: +1 per milestone).

#### Shuffle

Re-randomizes the entire board. In **Gravity Mode**, Shuffle is repurposed as the **lives** mechanic: `shuffle_count` starts at 3, and each Shuffle use decrements it by 1. When `shuffle_count` reaches 0 after a use, the game ends immediately (`NO_LIVES`). In all other modes, Shuffle has no additional penalty.

Starting counts: 1 (Classic/Mutation) / 3 (Gravity, these are lives) / increases each 100-point milestone (Zen/Challenge only: +1 per milestone).

#### Remove

Removes a single tile from the board without scoring. The player activates Remove mode by tapping the Remove button; the next tile they tap is deleted. Tapping the Remove button again while Remove mode is active **cancels** the operation (no tile is removed).

Starting counts: 1 (Classic/Gravity/Mutation) / increases each 100-point milestone (Zen/Challenge only: +1 per milestone).

---

## 4. Scoring System

### 4.1 Score Calculation

Each valid selection calls `calculate_points(sel_tiles)`, which computes the score in three steps.

#### Step 1 — Base score

The base score depends on the game mode:

| Mode | Base formula |
|------|-------------|
| Classic / Gravity | `sel_tiles.size()` — one point per tile in the selection |
| Zen / Mutation / Challenge | Density-adjusted bounding-box area (see below) |

**Density rule (Zen / Mutation / Challenge):**

For these modes, the base score rewards filling the selected region densely:

```
bbox_area  = (max_x − min_x + 1) × (max_y − min_y + 1)
tile_count = number of actual (non-empty) tiles in selection
density    = tile_count / bbox_area

if density < 0.3:
    base = tile_count       # sparse selection — no bounding-box reward
else:
    base = bbox_area        # dense selection — full area rewarded
```

The 0.3 threshold prevents "farming" by selecting a huge rectangle that contains only a few scattered tiles. For example, two tiles at opposite corners of the 8×12 grid would produce a bounding-box area of 96 but a density near 0 — the player earns only 2 points instead of 96.

Empty cells (tiles that were previously cleared or exploded by a Virus) do not count toward `tile_count`, so selections that span holes are automatically penalized by the density calculation.

#### Step 2 — Bonuses (Mutation Mode only)

After calculating the base, bonuses are added for each special tile included in the selection:

| Tile type | Bonus |
|-----------|-------|
| Joker | +5 |
| Negative | +3 |
| Mystery (revealed during this move) | +2 |
| Virus (cleared before explosion) | +10 |

#### Step 3 — Combo multiplier

```
final_score = (base + bonuses) × combo_count
```

where `combo_count` is the current combo streak value (see Section 4.2).

### 4.2 Combo System

The combo system rewards rapid consecutive valid selections.

**Mechanics:**
- `combo_count` starts at 1 (no multiplier).
- Each valid selection increments `combo_count` by 1, provided it occurs within **5 seconds** of the previous valid selection (measured by wall-clock time via `Time.get_unix_time_from_system()`).
- If more than 5 seconds elapse between valid selections, `combo_count` resets to 1.
- An invalid selection (wrong sum, or wrong shape in Challenge Mode) also resets `combo_count` to 1 immediately.

**Display:**
- The HUD shows a combo label ("×N") when `combo_count ≥ 2`. The label disappears on reset.

**Important note on pause:**
The combo timer uses wall-clock time and therefore does **not** pause when the game is paused. This is an accepted design decision: the combo timeout is short (5 seconds) and pauses are typically brief, so the practical impact is minimal.

**Max combo tracking:**
`max_combo` records the highest `combo_count` reached during a session. It is displayed on the game-over screen and stored in the highscore record.

### 4.3 End Game and Score Submission

A game session ends when a trigger condition is met (see table below). At that point, `trigger_end_game(reason)` is called, which:
1. Deletes the save file for the current mode (preventing a stale Continue prompt).
2. Computes `time_played` from the session timer.
3. Calls `Global.submit_score(mode, score, time_played, max_combo)`, which inserts the result into the top-3 highscore table for that mode (`user://highscore.json`).
4. Displays the game-over overlay with the final score, time played, and max combo.

| Reason | Applicable modes | Trigger |
|--------|-----------------|---------|
| `TIME_UP` | Classic, Gravity | Timer reaches 0 |
| `NO_MOVES` | All except Zen | No valid rectangle exists AND all power-up counts are 0 |
| `NO_LIVES` | Gravity | `shuffle_count` reaches 0 after use |
| `LEFT` | Classic, Gravity | Player taps Leave in the pause menu |

For **Zen, Mutation, and Challenge**, pressing Leave saves the game state without triggering a game-over. The score is still submitted to the highscore table at that point, but the save file is preserved for a future Continue session.

### 4.4 Valid Move Detection

`scan_board_for_valid_moves()` determines whether any valid rectangle exists on the current board. It reuses `find_hint_path()`, which iterates over all pairs of corner coordinates:

```
for each top-left (x1, y1) and bottom-right (x2, y2):
    collect all tiles at positions within the rectangle
    if tile_count > 1 and sum_with_joker_rule == 10:
        [Challenge] check constraint — skip if invalid shape
        return true   ← early exit
return false
```

The worst-case complexity is **O(n⁴)** over the grid coordinates (96⁴ ≈ 85 million iterations for an 8×12 board). To keep the frame rate acceptable, this function is **never called inside `_process()`**. It is invoked only after discrete events: a valid selection is cleared, a power-up is used, or the board is refilled.

---

---

## 5. Analysis and Design

### 5.1 Use Case Analysis

The system has a single actor: the **Player**. The primary use cases are:

| Use Case | Description |
|----------|-------------|
| Select game mode | Choose one of five modes from the Mode Select screen |
| Play a game | Drag to select tiles; clear rectangles summing to 10 |
| Use a power-up | Activate Hint, Shuffle, or Remove during a game |
| Pause / Resume | Pause mid-game; resume, restart, or leave |
| View tutorial | Step through the animated How-to-Play guide |
| View highscores | Browse top-3 scores per mode |
| View achievements | Browse 25 achievements with unlock status and progress |
| Continue a saved game | Resume a previously saved Zen, Mutation, or Challenge session |

The gameplay loop — drag, evaluate, score, refill — repeats until an end condition is met (timer, no lives, no moves, or the player leaves). This loop is entirely local; no network interaction exists.

### 5.2 System Architecture

TraceTen follows a **scene-based architecture** native to Godot 4. Each screen is an independent scene; the engine replaces the active scene on navigation. A single `AutoLoad` singleton (`global.gd`) bridges state across scenes without scene coupling.

#### 5.2.1 Scene and Script Map

| File | Role |
|------|------|
| `main_menu.gd/tscn` | Entry point: navigation to all top-level screens |
| `mode_select.gd/tscn` | Mode cards with description; triggers Continue/New Game overlay for persistent modes |
| `main.gd/tscn` | Board coordinator: spawns tiles, handles drag input, evaluates selections, manages timers and HUD |
| `highscore.gd/tscn` | Top-3 per mode; tab bar built programmatically |
| `achievement_screen.gd/tscn` | 25 achievements grouped by category; locked/unlocked state and progress |
| `tutorial.gd/tscn` | 5-panel animated walkthrough with auto-replaying cursor demo |
| `tile.gd` (`BaseTile`) | Base class for all tile types: display, selection state, signal emission |
| `tile_joker/virus/mystery/negative.gd` | Subclasses that override `get_effective_value()` and `_update_type_visuals()` |
| `tile_factory.gd` | `TileFactory.roll(mode)` → type via weighted probability; `make(type)` → Node |
| `global.gd` | AutoLoad singleton: game mode, save/load, highscore, achievements, cross-scene state |
| `data/zen_levels.gd` | Data-only config for 12 Challenge levels (constraints, unlock scores, names) |
| `data/achievements.gd` | Data-only config for 25 achievements (id, name, desc, target) |
| `scripts/zen_level_manager.gd` | `validate_constraint()` — checks bbox and tile count against level rules |
| `scripts/zen_board_generator.gd` | Smart board generation: plants a guaranteed valid solution, fills remainder randomly |
| `achievement_popup.gd/tscn` | Notification popup: `CanvasLayer`, slide-in queue, auto-dismisses after 2.5 s |

#### 5.2.2 Scene Transition Flow

```
main_menu
├── mode_select → main (gameplay)
│                  └── main_menu  (Leave / Game Over → Back)
├── highscore  → main_menu
├── achievements → main_menu
└── tutorial   → main_menu
```

The `Global` singleton carries `selected_mode` and `load_save` between `mode_select` and `main`, eliminating the need for scene parameters.

### 5.3 Tile Class Hierarchy

All tile types share a common interface defined in `BaseTile` (`tile.gd`). Specialised behaviour is isolated to subclasses, keeping `main.gd` free of per-type conditionals in most paths.

```
BaseTile (tile.gd)
├── get_effective_value() → int   # returns value for sum calculation
├── select() / deselect()         # visual state
└── _update_type_visuals()        # colour + label

    ├── TileJoker    — get_effective_value() = 0; "biomorphs" to needed value on evaluate
    ├── TileVirus    — _process() countdown; calls main.kill_tile_from_virus() on value == 0
    ├── TileMystery  — _update_type_visuals() shows "?" until first select()
    └── TileNegative — _update_type_visuals() applies red colour; no other override
```

`TileFactory` decouples instantiation from the rest of the codebase. `roll(mode)` returns a type string via weighted random; `make(type)` instantiates `tile.tscn` and assigns the correct script. Adding a new tile type requires changes only to `TileFactory` and a new script file.

### 5.4 Board Representation

The board is stored as a **Dictionary** `tiles: Dictionary[Vector2, BaseTile]` in `main.gd`.

- **O(1) lookup** by grid position — needed constantly during drag selection and hint search.
- **Sparse by design** — Virus explosions leave permanent holes. An Array representation would require sentinel values or index arithmetic to handle holes; a Dictionary simply has no entry for empty cells.
- **Iteration** over `tiles.keys()` visits only real tiles, which simplifies the O(n⁴) hint scan and density calculation.

The grid is 8 columns × 12 rows (96 cells). Tile screen positions are computed from `start_pos + Vector2(x, y) * tile_size`, where `tile_size` is derived dynamically from the viewport dimensions to support any screen size.

### 5.5 Key Algorithm Decisions

#### Rectangle Selection

When the player drags, a screen-space selection rectangle is computed from the drag start and current touch position. Every position in `tiles` whose screen coordinate falls within this rectangle is added to `selected_tiles`. This is O(tiles) per frame during drag — acceptable because the board has at most 96 tiles.

On release, `evaluate_selection()` sums `get_effective_value()` for each selected tile (Joker contributes 0, then adjusts the total if needed), checks against 10, applies the Challenge constraint if active, scores, removes tiles, and triggers refill or gravity.

#### Valid Move Detection — O(n⁴) with Early Exit

`scan_board_for_valid_moves()` (reused as `find_hint_path()`) iterates over all pairs of corner coordinates (x1, y1) → (x2, y2) forming a rectangle, collects the tiles within, checks the sum, and optionally validates the Challenge constraint. It returns immediately on the first valid rectangle found.

Worst-case complexity is O(n⁴) over grid coordinates — approximately 85 million iterations for a full 8×12 board. This is acceptable because:

1. **Early exit** terminates the search as soon as one valid rectangle is found. In practice the board always contains multiple solutions, so the search rarely approaches worst case.
2. **Never called in `_process()`** — only invoked after discrete, player-triggered events (selection cleared, power-up used, board refilled).

#### Smart Board Generation (Challenge Mode)

Random fill does not guarantee a valid move satisfying the Challenge constraint (especially the strict "3×3 square" constraint at Level 6). `ZenBoardGenerator.generate(level)` addresses this by:

1. **Planting a solution first**: select a rectangle that satisfies the level's shape rules; generate a set of numbers within it that sum to exactly 10.
2. **Filling the remainder** with weighted-random numbers (1–5 weighted higher to keep sums reachable).
3. **Leaving holes** inside the solution rectangle for Levels 10–12, so the bounding box is large (≥ 12 cells) but only the required minimum of tiles are placed — a deliberate design choice that makes high-level selections feel spacious without requiring every cell to be filled.

This guarantees at least one valid move on every generated board without any retry loop.

### 5.6 Audio and Visual Feedback

Game feel ("juice") relies on immediate audio-visual responses to every player action. TraceTen implements this through two lightweight systems that add no gameplay logic.

#### AudioManager (AutoLoad Singleton)

A custom `AudioManager` node (`scripts/audio_manager.gd`) is registered as a Godot AutoLoad singleton so that any script in any scene can call `AudioManager.play_sfx(id, pitch, volume_db)` without holding a reference to a specific node.

Internally, the manager maintains a **pool of eight `AudioStreamPlayer` nodes**. On each `play_sfx` call the next player in the pool is selected (round-robin), its stream, pitch, and volume are set, and playback begins. The pool prevents sounds from cutting each other off during rapid-fire events such as clearing a large selection with combo multiplier active.

Eleven sound effects cover the main interaction events:

| ID | Trigger |
|----|---------|
| `score` | Tile selection cleared successfully |
| `combo` | Combo count increases |
| `wrong` | Wrong sum or wrong shape |
| `powerup_use` | Hint or Remove activated |
| `powerup_gain` | Zen/Challenge milestone refill |
| `shuffle` | Shuffle activated |
| `tile_remove` | Single tile removed via Remove power-up |
| `virus_explode` | Virus spreads and resets |
| `gameover` | Game over triggered |
| `achievement` | Achievement unlocked |
| `level_up` | Gravity level increases |

All sounds were generated with **jsfxr** (an open-source procedural SFX generator) and exported as `.ogg` files. The `score` sound's pitch scales with combo count (`1.0 + (combo − 1) × 0.05`) to provide subtle audio feedback for streaks without requiring separate files.

#### Visual Feedback (VFX)

Three Tween-based effects and one particle system reinforce action outcomes:

- **Tile clear burst**: On successful selection, a `CPUParticles2D` node is spawned at each cleared tile's position. Particles are coloured by tile type (white for normal, red for Negative, green-yellow for Virus, gold for Joker) and auto-freed via the `finished` signal. `CPUParticles2D` is used instead of `GPUParticles2D` for better compatibility with low-end Android hardware.
- **Wrong flash**: On incorrect selection (wrong sum or wrong Challenge shape), each selected tile's `modulate` property is tweened red twice (0.07 s per step) before deselect — a stronger signal than simply resetting selection.
- **Score float**: The floating score label scales from 55 px to 75 px font size as combo increases (`min(55 + (combo − 1) × 5, 75)`), and changes colour from white → yellow → orange-red at combo thresholds of x2 and x4.
- **Combo bounce**: The `ComboLabel` plays a scale tween (1.0 → 1.3 → 1.0 in 160 ms) each time the combo count updates.

---

## 6. Conclusion and Future Work

### 6.1 Summary

TraceTen set out to build a minimalist mobile puzzle game that sits between casual luck-based games and concentration-heavy number puzzles. The finished product delivers:

- **Five distinct game modes** sharing one board engine but imposing different goals, timers, and failure conditions — from the pressure of Classic's 120-second countdown to the open-ended accumulation of Zen.
- **Four special tile types** in Mutation and Challenge modes that introduce risk (Virus explosion), information asymmetry (Mystery), flexibility (Joker), and negative-space strategy (Negative).
- **A progression system** (Challenge Mode, 12 levels) with shape constraints and Smart Board Generation that guarantees solvability at every level.
- **Supporting systems**: combo multiplier, three power-ups, save/load for persistent modes, a highscore table, and 25 achievements covering a range of playstyles from speed-running to exploration.
- **Clean architecture**: tile class hierarchy, data-driven configuration, AutoLoad singleton, and a Dictionary-based sparse board representation that handles holes gracefully.

The project was developed in approximately ten weeks using Godot 4 and GDScript, targeting Android. All gameplay, save data, and achievements are stored locally; no network connectivity is required.

### 6.2 Limitations

- **Performance on low-end devices**: the O(n⁴) scan is called on discrete events and has early exit, but has not been benchmarked on low-end Android hardware. A future optimisation could cache valid-move sets and invalidate incrementally.
- **UI polish**: button sizes and visual theme were intentionally deferred to a later sprint. The current interface is functional but not visually refined.
- **No background music**: SFX is implemented; an ambient BGM loop is planned but not yet added.
- **Single-language UI**: all in-game text is English; localisation was not in scope.

### 6.3 Future Work

Several directions were identified during development but deferred outside the project scope:

| Feature | Notes |
|---------|-------|
| Background music | Ambient BGM loop (Pixabay CC0) planned; SFX and particle VFX already implemented |
| UI polish | Custom font (Google Fonts), consistent colour theme per mode, responsive HUD using Containers |
| Online leaderboard | Currently local-only; a lightweight backend (e.g. Firebase) would enable global ranking |
| Interactive tutorial | Current tutorial is animated but non-interactive; a guided first-game would lower the learning curve |
| Expanded achievements | The 25-achievement system is extensible; additional quirky or mode-specific achievements are natural additions |
| Tile combo mechanics | Candy Crush-style special tiles generated by clearing large areas, adding a mid-term strategic layer |
| Difficulty settings | Adjustable board size or weighted number distributions to accommodate different skill levels |

---

*End of draft — sections: Introduction, Game Modes, Special Tiles & Power-ups, Scoring System, Analysis & Design, Conclusion & Future Work.*
*Still needed: Theoretical Background (Godot 4, GDScript, mobile game design); Results & Evaluation (screenshots, APK test — write after T8).*
