# TraceTen — Developer Reference

Tài liệu tra cứu nhanh cho các hệ thống phức tạp. Đọc khi cần nhớ lại logic, không cần đọc code.

---

## Mục lục

1. [Hệ thống tính điểm](#1-hệ-thống-tính-điểm)
2. [Evaluate Selection — luồng xử lý nước đi](#2-evaluate-selection--luồng-xử-lý-nước-đi)
3. [Hint & Scan Board — thuật toán O(n⁴)](#3-hint--scan-board--thuật-toán-on4)
4. [Combo System](#4-combo-system)
5. [End Game Logic](#5-end-game-logic)
6. [Gravity Mode — Level & Timer](#6-gravity-mode--level--timer)
7. [Special Tiles](#7-special-tiles)
8. [Power-up System](#8-power-up-system)
9. [Save / Load System](#9-save--load-system)
10. [Highscore System](#10-highscore-system)
11. [Challenge Mode — Constraint System](#11-challenge-mode--constraint-system)
12. [Smart Board Generation](#12-smart-board-generation)
13. [Tile Factory & Gacha](#13-tile-factory--gacha)
14. [Input & Board Layout](#14-input--board-layout)
15. [Gotchas & Quirks](#15-gotchas--quirks)

---

## 1. Hệ thống tính điểm

**Hàm:** `calculate_points(sel_tiles)` — `main.gd:1047`

### Bước 1 — Tính `base`

| Mode | Công thức |
|------|-----------|
| Classic / Gravity | `sel_tiles.size()` — đếm tile thật trong vùng |
| Zen / Mutation / Challenge | Tính **density** trước |

**Density rule (Zen/Mutation/Challenge):**
```
bbox_area = (max_x - min_x + 1) * (max_y - min_y + 1)
tile_count = sel_tiles.size()
density    = tile_count / bbox_area

if density < 0.3:  base = tile_count    ← sparsely placed
else:              base = bbox_area     ← densely packed
```
Threshold 0.3 — tinh chỉnh khi playtest.

### Bước 2 — Bonuses (chỉ Mutation)

| Tile type | Bonus |
|-----------|-------|
| JOKER | +5 |
| NEGATIVE | +3 |
| MYSTERY | +2 |
| VIRUS (dọn sống) | +10 |

### Bước 3 — Nhân combo

```
điểm = (base + bonuses) × combo_count
```

### Lưu ý quan trọng
- `sel_tiles` chỉ chứa vị trí có tile thật (`tiles.has(pos) == true`). Ô trống trong vùng kéo không vào mảng này.
- Bounding box tính từ các tile thật → kéo ra phía ô trống không tăng điểm.
- CHALLENGE: constraint check xảy ra trong `evaluate_selection()` TRƯỚC khi `calculate_points()` được gọi.

---

## 2. Evaluate Selection — luồng xử lý nước đi

**Hàm:** `evaluate_selection()` — `main.gd:341`

```
1. Tính tổng effective_value của selected_tiles
2. Nếu có JOKER:
	 needed = 10 - total
	 if needed trong [-9, 9]: total = 10
	 else: total = 999, show "OVERLOAD"
3. Nếu total == 10:
	 a. [CHALLENGE only] Tính bbox, gọi ZenLevelManager.validate_constraint()
		→ fail: reset combo, show "Wrong shape!", clear selection, return
	 b. calculate_points() → cộng score
	 c. Cập nhật combo (real clock)
	 d. Remove tiles khỏi board
	 e. [GRAVITY] apply gravity + check level up
	 f. [ZEN/CHALLENGE] check milestone refill (100pts)
	 g. scan_board_for_valid_moves() → nếu false + hết power-up → trigger_end_game("NO_MOVES")
4. Nếu total != 10:
	 reset combo
```

---

## 3. Hint & Scan Board — thuật toán O(n⁴)

**Hàm:** `find_hint_path()` — `main.gd:1112`  
**Hàm:** `scan_board_for_valid_moves()` — `main.gd:470`

```gdscript
# Duyệt tất cả cặp (x1,y1)→(x2,y2) tạo thành hình chữ nhật
for x1 in range(min_x, max_x+1):
  for y1 in range(min_y, max_y+1):
	for x2 in range(x1, max_x+1):
	  for y2 in range(y1, max_y+1):
		rect_tiles = [pos trong tiles.keys() mà x1≤x≤x2 và y1≤y≤y2]
		if rect_tiles.size() > 1 and is_valid_sum_10(rect_tiles):
		  [CHALLENGE] validate_constraint → bỏ qua nếu sai shape
		  return rect_tiles  ← early-exit ngay khi tìm được
```

`scan_board_for_valid_moves()` reuse `find_hint_path()`, chỉ kiểm tra có tồn tại hay không.

**⚠ KHÔNG gọi trong `_process()`** — O(n⁴) = tối đa 96⁴ ≈ 85 triệu iterations.  
Chỉ gọi sau: `evaluate_selection`, dùng power-up, refill.

**Joker trong hint:** `is_valid_sum_10()` check `needed` trong [-9, 9] (same logic như evaluate).

---

## 4. Combo System

- Timer: `Time.get_unix_time_from_system()` — **real clock, không dừng khi pause** (chấp nhận)
- Timeout: 5 giây (`COMBO_TIMEOUT = 5.0`)
- Tăng combo: nước đi liên tiếp < 5s → `combo_count += 1`
- Reset combo: kéo sai sum, kéo sai constraint (Challenge), timeout > 5s
- `max_combo` track suốt game, lưu vào highscore khi kết thúc
- UI: ComboLabel hiện "x{n}" khi combo ≥ 2, ẩn khi reset

---

## 5. End Game Logic

**Hàm:** `trigger_end_game(reason)` — `main.gd:481`

| Reason | Khi nào |
|--------|---------|
| `"TIME_UP"` | Hết timer (Classic 120s, Gravity 150s) |
| `"NO_MOVES"` | Hết nước đi + hết power-up |
| `"NO_LIVES"` | Gravity: shuffle_count về 0 |
| `"LEFT"` | Nhấn Leave trong pause (Classic/Gravity) |

```
trigger_end_game(reason):
  → delete_save(mode)          ← xóa save file (tránh Continue vào game đã xong)
  → tính time_played
  → submit_score(mode, score, time, max_combo)   ← lưu highscore
  → hiện GameOverLayer với ResultLabel, FinalScoreLabel, TimePlayedLabel, MaxComboLabel
```

**Zen/Challenge/Mutation khi Leave:**  
`_on_btn_quit_pressed()` → `submit_score()` → `_save_game_state()` → đổi scene  
(Không gọi `trigger_end_game` vì không muốn xóa save)

**Zen:** end game chỉ khi hết nước + hết power-up (không có Time's up, không có Leave → GameOver).

---

## 6. Gravity Mode — Level & Timer

### Levels
| Level | Threshold | Hướng gravity |
|-------|-----------|---------------|
| L1 | 0–49 pts | DOWN |
| L2 | 50–99 pts | RIGHT |
| L3 | 100–149 pts | LEFT |
| L4 | ≥150 pts | RANDOM (UP/DOWN/LEFT/RIGHT mỗi nước) |

Level up tại mỗi 50 điểm. UI: `GravityLevelLabel` hiện "Lv.X" + flash animation.

### Timer
- Start: 150s. Mỗi tile ăn được cộng `+1.0s` vào `total_duration` (không phải bug).
- `shuffle_count = 3` = lives. Dùng Shuffle → tiêu 1 mạng. `shuffle_count == 0` → `trigger_end_game("NO_LIVES")`.
- Timer dừng khi pause (`accumulated_time` style, khác Classic).

### Refill
Sau mỗi lần apply gravity: refill 70% board với tile ngẫu nhiên (random thường, không smart gen).

---

## 7. Special Tiles

Được triển khai đầy đủ trong **Mutation**. Challenge/Zen có thể dùng qua TileFactory.

### JOKER
- `get_effective_value()` trả về 0 khi đang kéo → sum display hiện đúng
- Khi evaluate: `needed = 10 - sum_without_joker`, nếu trong [-9,9] → hợp lệ
- Joker tự "lấy" giá trị `needed` để tổng = 10

### VIRUS (màu xanh)
- `_process()` trong `tile_virus.gd`, đếm thời gian (dừng khi `is_paused`)
- Mỗi 10s: random lại giá trị (65% dương 1-9, 30% âm -5→-1, 4% âm -9→-6, **1% → 0**)
- Virus về 0 → **nổ**: xóa tile, để lại ô trống vĩnh viễn
- Ô trống do Virus nổ = không có entry trong `tiles` dict → cắt đứt bbox

### MYSTERY (❓)
- Hiện "?" cho đến khi player chạm/kéo lướt qua → reveal số thật
- `tile_mystery.gd`: signal khi reveal, main.gd cập nhật display

### NEGATIVE (màu đỏ)
- Giá trị âm (-1 đến -5). Dùng để balance combo với số dương lớn.
- Không có behavior đặc biệt ngoài màu sắc.

---

## 8. Power-up System

| Power-up | Count | Stackable | Đặc biệt |
|----------|-------|-----------|---------|
| Hint | int ≥1 | Zen: +3/100pts | Hiện highlight vùng hợp lệ |
| Shuffle | int ≥1 | Zen: +1/100pts; **Gravity = lives** | Gravity: dùng 1 = mất 1 mạng |
| Remove | int ≥1 | Zen: +2/100pts | Bấm lại để cancel trước khi chọn ô |

**Zen/Challenge refill milestone:** mỗi 100 điểm tích lũy → `hint+3, shuffle+1, remove+2`.  
Tracked bằng `zen_milestone_count` (số milestone đã qua).

**Remove mode:** `is_remove_mode = true` → click tile = xóa tile đó (không kéo vùng).  
Bấm Remove lần 2 khi đang trong remove mode → cancel (tắt is_remove_mode).

---

## 9. Save / Load System

### Files

| Mode | File | Khi nào save |
|------|------|-------------|
| ZEN | `user://save_zen.json` | Pause → Save; Leave |
| MUTATION | `user://save_mutation.json` | Pause → Save; Leave |
| CHALLENGE | `user://save_challenge.json` | Pause → Save; Leave |
| Highscore | `user://highscore.json` | Sau mỗi game over / leave |

Classic và Gravity không có save/load (timer-based, không persistent).

### Cấu trúc save_zen.json / save_challenge.json

```json
{
  "mode": "ZEN",
  "score": 387,
  "accumulated_time": 1840.5,
  "hint_count": 2,
  "shuffle_count": 1,
  "remove_count": 3,
  "zen_milestone_count": 3,
  "current_level": 3,
  "unlocked_levels": [1, 2, 3],
  "tiles": [
    {"x": 0, "y": 0, "value": 5, "type": "NORMAL"},
    {"x": 1, "y": 0, "value": 3, "type": "VIRUS"},
    ...
  ]
}
```

`save_mutation.json` không có `current_level` / `unlocked_levels`.

### Bug đã fix: JSON float → int
`JSON.parse_string()` parse số nguyên thành float. Mọi field số nguyên phải wrap bằng `int()` khi load:
```gdscript
score = int(data.get("score", 0))   # KHÔNG để raw: score = data.get("score", 0)
```
Nếu không fix → score hiện "387.0", power-up count bị tính sai.

### Flow Continue / New Game
Khi vào mode có save file: `Global.has_save(mode)` → hiện overlay 3 nút:
- **Continue** → `Global.load_save = true` → `_load_game_state()`
- **New Game** → `Global.delete_save(mode)` → `spawn_grid()` bình thường
- **Cancel** → về màn hình trước

---

## 10. Highscore System

**File:** `user://highscore.json`  
**Functions:** `Global.submit_score()`, `load_highscore()`, `save_highscore()`

### Cấu trúc

```json
{
  "CLASSIC":   [{"score": 240, "time": 95.0, "max_combo": 5}, ...],
  "GRAVITY":   [...],
  "MUTATION":  [...],
  "ZEN":       [...],
  "CHALLENGE": [...]
}
```

Top 3 per mode, sorted descending by score. `HIGHSCORE_TOP = 3`.

### Khi nào submit

| Tình huống | Hàm gọi |
|-----------|---------|
| Classic/Gravity TIME_UP, NO_MOVES, NO_LIVES, LEFT | `trigger_end_game()` gọi `submit_score()` |
| Zen/Mutation/Challenge NO_MOVES | `trigger_end_game()` gọi `submit_score()` |
| Zen/Mutation/Challenge Leave (pause → quit) | `_on_btn_quit_pressed()` else branch gọi `submit_score()` trước `_save_game_state()` |

### UI Highscore Screen
- Không dùng `TabContainer` native (vì `< >` bé tí khó tap trên mobile)
- Thay bằng: `ScrollContainer` (horizontal) + `HBoxContainer` chứa `Button` per mode
- Swipe ngang tự nhiên trên Android nhờ `ScrollContainer`
- Content area bên dưới: show/hide `VBoxContainer` theo tab được chọn

---

## 11. Challenge Mode — Constraint System

Challenge = Zen nhưng có constraint shape per level. Constraint check trong `evaluate_selection()` và `find_hint_path()`.

### 12 Levels

| Level | Biome | Unlock | Constraint |
|-------|-------|--------|-----------|
| L1 | Meadow | 0 | `tile_count ≥ 3` |
| L2 | Forest | 50 | `tile_count ≥ 3` AND `bbox_area ≥ 4` |
| L3 | Riverside | 150 | `bbox vuông ≥ 2×2` AND `tile_count ≥ 3` |
| L4 | Ocean Shore | 300 | `tile_count ≥ 4` AND `bbox_area ≥ 6` |
| L5 | Deep Sea | 500 | `bbox ≥ 2×3 (hoặc 3×2)` AND `tile_count ≥ 4` |
| L6 | Coral Reef | 750 | `bbox vuông ≥ 3×3` AND `tile_count ≥ 5` |
| L7 | Desert | 1000 | `tile_count ≥ 5` AND `bbox_area ≥ 8` |
| L8 | Canyon | 1300 | `bbox ≥ 3×3 (bất kỳ shape)` AND `tile_count ≥ 5` |
| L9 | Mountain | 1700 | `tile_count ≥ 6` AND `bbox_area ≥ 9` |
| L10 | Snow Peak | 2200 | `bbox_area ≥ 12` AND `tile_count ≥ 6` |
| L11 | Aurora | 2800 | `tile_count ≥ 7` AND `bbox_area ≥ 12` |
| L12 | Cosmos | 3500 | `bbox_area ≥ 16` AND `tile_count ≥ 8` |

### Validate Constraint
**File:** `scripts/zen_level_manager.gd` — `ZenLevelManager.validate_constraint(bbox, tile_count, level)`

```gdscript
rules = ZenLevels.LEVELS[level - 1]["constraints"]
# Checks (theo thứ tự):
# 1. min_tiles
# 2. min_bbox_area
# 3. must_be_square (bbox_w == bbox_h)
# 4. min_square_size (bbox_w == bbox_h AND bbox_w >= N)
# 5. min_bbox_size (bbox_w >= ms.x AND bbox_h >= ms.y, hoặc rotated)
# Returns: {"valid": bool, "reason": String}
```

### Unlock & Level Switch
- Điểm tích lũy mãi (không reset khi chuyển level)
- Chuyển level: qua pause menu "Change Level" hoặc nút "⇄ Levels" trên HUD
- Khi đổi level: gọi `ZenBoardGenerator.generate(new_level)` → regen board
- `Global.zen_current_level` + `Global.zen_unlocked_levels` lưu state
- Constraint sai khi kéo → "Wrong shape!" + reset combo (không bị trừ điểm)

---

## 12. Smart Board Generation

**File:** `scripts/zen_board_generator.gd` — `ZenBoardGenerator.generate(level)`

### Vấn đề cần giải quyết
Random board thông thường không đảm bảo có valid move thỏa constraint. Challenge L6 (3×3 vuông) rất khó ngẫu nhiên ra valid.

### Thuật toán

```
1. _pick_solution_rect(rules, min_tiles)
   → chọn rect có size phù hợp constraint
   → random top-left sao cho không out of bound

2. _pick_spanning_positions(sol_rect, min_tiles)
   → chọn ngẫu nhiên min_tiles vị trí trong rect
   → (L10-L12: để lại holes trong rect, cho phép bbox lớn nhưng chỉ pick đúng min_tiles)

3. _generate_summing_to_10(n)
   → partition: n-1 số random 1..max_val, số cuối = 10 - sum_so_far
   → shuffle kết quả

4. Fill phần còn lại (ngoài sol_rect) bằng random weighted 1-9

5. Vị trí trong sol_rect mà không phải solution positions → để trống (holes)
```

**Kết quả:** Board luôn có ít nhất 1 valid move (solution rect đã planted), không cần retry.

### Weighted random 1-9
```
1-5: xác suất cao (~71% tổng)
6-9: xác suất thấp
```
Tránh board quá nhiều số lớn (8, 9) làm khó tìm tổng = 10.

---

## 13. Tile Factory & Gacha

**File:** `tile_factory.gd` — `TileFactory`

### `roll(mode)` → type

| Mode | Normal | Joker | Virus | Mystery | Negative |
|------|--------|-------|-------|---------|---------|
| CLASSIC | 100% | — | — | — | — |
| GRAVITY | 100% | — | — | — | — |
| ZEN | ~100% | — | — | — | — |
| MUTATION | ~60% | 10% | 15% | 10% | 5% |
| CHALLENGE | theo level config | — | — | — | — |

### `make(type)` → Node
Instantiate `tile.tscn` rồi thay script tương ứng:
- NORMAL: `tile.gd` (BaseTile)
- JOKER: `tile_joker.gd`
- VIRUS: `tile_virus.gd`
- MYSTERY: `tile_mystery.gd`
- NEGATIVE: `tile_negative.gd`

---

## 14. Input & Board Layout

### Board dimensions
```
grid_cols = 8, grid_rows = 12  → 96 ô
tile_size = min(screen_w * 0.90 / 8, (screen_h - 190) / 12, 105)
start_pos.x = (screen_w - 8*tile_size) / 2 + tile_size/2
start_pos.y = 130 + (avail_h - 12*tile_size) / 2 + tile_size/2
ui_top = 130px (reserved cho HUD)
```

### Tile visual vs hitbox
- **Visual:** scale = 90% (`TILE_VISUAL_RATIO = 0.90`) → có gap nhỏ giữa các ô
- **Hitbox:** `CollisionShape2D` trong `tile.tscn` giữ nguyên 100% cell size
- Hậu quả: touch vào khoảng trống giữa tile vẫn có thể trigger tile lân cận — cần verify trên thiết bị thật

### Input model
- `InputEventScreenTouch` / `InputEventMouseButton` → start/end drag
- `InputEventScreenDrag` / `InputEventMouseMotion` → update selection box
- Selection box = rect từ drag_start đến current pos
- `selected_tiles` = tất cả pos trong `tiles` dict mà nằm trong selection box

---

## 15. Gotchas & Quirks

### ⚠ DEBUG_MODE
`DEBUG_MODE = true` trong `main.gd`. **Phải set `false` trước khi build APK.** Nếu quên: app vẫn chạy nhưng in console spam + nút TEST hiện.

### ⚠ Gravity total_duration thay đổi động
Mỗi tile xóa được: `total_duration += 1.0`. Không phải bug — thiết kế có chủ ý.

### ⚠ Combo timer không dừng khi pause
`Time.get_unix_time_from_system()` là wall clock. Nếu pause lâu > 5s thì combo reset sau khi resume. Chấp nhận được — combo timeout ngắn (5s), pause thường ngắn.

### ⚠ Virus timer cũng pause-aware
`tile_virus.gd` đọc `is_paused` từ main scene để dừng đếm. Phải truyền reference đúng.

### ⚠ JSON int/float issue
`JSON.parse_string()` không phân biệt 3 vs 3.0. Luôn wrap bằng `int()` khi đọc field số nguyên. Nếu không: score hiện "100.0", power-up count bị float gây lỗi cộng dồn.

### ⚠ scan_board_for_valid_moves() sau refill
Sau khi refill tiles, phải gọi lại `scan_board_for_valid_moves()`. Nếu quên: game có thể trigger end game sai (board mới có move nhưng vẫn báo NO_MOVES).

### ⚠ delete_save() trong trigger_end_game()
`trigger_end_game()` tự động `Global.delete_save(mode)`. Không gọi thêm ở nơi khác.  
Đặc biệt: Leave trong Zen/Challenge/Mutation KHÔNG gọi `trigger_end_game()` → save file được giữ nguyên (đúng thiết kế — vẫn có thể Continue).

### ⚠ Challenge board holes
L10-L12: `zen_board_generator.gd` để lại ô trống (holes) bên trong solution rect. Đây là intentional design: player kéo bbox lớn nhưng chỉ cần đúng min_tiles có số hợp lệ. Đừng "fix" holes này.

### ⚠ unlocked_levels là Array, không phải Set
Khi check `if level in unlocked_levels` — hoạt động đúng. Nhưng khi append cần kiểm tra trùng: `if not level in unlocked_levels: unlocked_levels.append(level)`.
