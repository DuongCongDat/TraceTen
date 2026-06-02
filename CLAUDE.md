# TraceTen

## Giới thiệu

TraceTen là trò chơi giải đố logic 2D tối giản trên Android. Người chơi kéo chọn các vùng hình chữ nhật sao cho tổng giá trị các ô số bên trong bằng đúng **10** để ghi điểm.

## Tech Stack

- **Engine:** Godot 4.x
- **Ngôn ngữ:** GDScript
- **Platform:** Android (local-only, không có online features)
- **Lưu trữ:** Local storage

## Cấu trúc Scene/Script

| File | Vai trò |
|------|---------|
| `main.tscn` / `main.gd` | Board coordinator: sinh bàn cờ, xử lý input kéo vùng, tính tổng điểm |
| `main_menu.tscn` / `main_menu.gd` | Màn hình chính, điều hướng, chọn chế độ |
| `tile.tscn` / `tile.gd` | Base class (`BaseTile`): logic chung của mọi ô (hiển thị, select, signal) |
| `tile_virus.gd` | Subclass: Virus timer, self-destruct, `_process()` |
| `tile_mystery.gd` | Subclass: reveal `?` khi chạm |
| `tile_joker.gd` | Subclass: `get_effective_value()` = 0 |
| `tile_negative.gd` | Subclass: màu đỏ |
| `tile_factory.gd` | `TileFactory`: `roll(mode)` xác suất gacha, `make(type)` tạo node đúng script |
| `global.gd` | Autoload Singleton, lưu trạng thái toàn cục, chuyển dữ liệu giữa scene |

## Game Modes

- **Classic** — countdown 120s (Time's up), timer luôn chạy kể cả khi pause/alt-tab. Leave → show GameOver summary.
- **Zen** — count-up, không giới hạn thời gian, timer dừng khi pause. Mỗi 100 điểm refill toàn bộ power-up (stackable).
- **Gravity** — countdown 150s + 3 lives (mỗi shuffle tiêu 1 mạng). Mỗi ô ăn được +1s time bonus. 4 levels (mỗi 50 điểm): L1 DOWN → L2 RIGHT → L3 LEFT → L4 RANDOM (ngẫu nhiên UP/DOWN/LEFT/RIGHT sau mỗi nước). Timer dừng khi pause. Leave → show GameOver summary.
- **Mutation** — ô đặc biệt, count-up, timer dừng khi pause.

## Power-ups

- **Hint** — gợi ý vùng chữ nhật (int count, stackable trong Zen)
- **Shuffle** — xáo lại bàn cờ (int count; trong Gravity = lives, tiêu 1 mạng khi dùng)
- **Remove** — xóa ô (int count; bấm lại Remove để cancel trước khi chọn ô)

---

## 🎴 Hệ thống Ô Đặc Biệt (Special Tiles)

Đã triển khai trong **Mutation Mode**, có thể trigger trong **Zen Mode** sau mốc điểm.

### 🃏 Ô Joker
- **Cơ chế:** Giá trị gốc = **0** khi kéo chọn. Khi chốt vùng, Joker tự "biến hình" thành con số cần thiết để ép tổng = 10.
- **Giới hạn:** Chỉ bù trừ trong khoảng **-9 đến 9**.

### 🦠 Ô Virus (Màu Xanh)
- **HP:** Mỗi virus sinh ra với HP ngẫu nhiên **1–5** (hiển thị bằng countdown dots ở đáy tile).
- **Cơ chế:** Mỗi **10 giây**, số trên Virus biến đổi ngẫu nhiên (65% dương 1-9, 30% âm -5→-1, 5% âm -9→-6). Mỗi tick tiêu 1 HP.
- **Lan rộng:** Khi hết HP → virus **lan sang 1 ô liền kề ngẫu nhiên** (tạo virus mới tại đó, reset HP), gây phạt -10 điểm. Không còn cơ chế nổ ngẫu nhiên.

### ❓ Ô Ẩn Số
- **Cơ chế:** Hiện dấu `?`. Phải chạm hoặc kéo lướt qua để lộ số thật.

### 🩸 Ô Đột Biến (Số Âm - Màu Đỏ)
- **Cơ chế:** Mang giá trị âm (vd: -2, -5). Hữu ích để dung hòa số dương lớn.

---

## 🏆 Hệ thống điểm

### Combo Multiplier — Tất cả mode
- Ăn liên tiếp trong **5 giây** → x2, x3, x4...
- Reset combo khi ngừng > 5 giây hoặc kéo sai
- UI: ComboLabel hiển thị "x{n}  {t}s" — tự ẩn khi combo reset
- Timer dùng `Time.get_unix_time_from_system()` (real clock) — **không dừng khi pause** (chấp nhận được)

### Công thức điểm (`calculate_points()` trong `main.gd:861`)

**Bước 1 — Tính `base`:**

| Mode | Cách tính base |
|------|---------------|
| Classic / Gravity | `sel_tiles.size()` — đếm số ô **có tile thật** trong vùng kéo |
| Zen / Mutation | `(max_x − min_x + 1) × (max_y − min_y + 1)` — **bounding box của các tile thật** được select (không phải vùng kéo) |

**Bước 2 — Tính `bonuses` (chỉ Mutation):**

| Loại ô | Bonus |
|--------|-------|
| Joker | +5 |
| Negative (số âm) | +3 |
| Mystery (ô ẩn) | +2 |
| Virus (dọn trước khi nổ) | +10 |

**Bước 3 — Nhân combo:**
```
điểm = (base + bonuses) × combo_count
```

**Lưu ý quan trọng về Zen/Mutation:**
- `selected_tiles` chỉ chứa ô có tile thật (`tiles.has(pos)` = true) — ô trống không được tính vào.
- Bounding box tính từ vị trí các tile thật đó → kéo vùng dài ra phía ô trống không làm tăng điểm.
- Nhưng nếu các tile thật nằm **rải rác xa nhau** (vd: góc (0,0) và (7,11)), bounding box có thể rất lớn dù chỉ có vài tile → có thể farming điểm cao. Chấp nhận được ở thời điểm này.

---

## ☠️ End Game Logic

**Trigger:** Hết nước đi (không còn vùng chữ nhật nào tổng = 10) **VÀ** hết power-up.

**Áp dụng cho:**
- ✅ Classic — thêm: Time's up; Leave → GameOver summary
- ✅ Mutation — "No moves left"
- ✅ Gravity — thêm: Time's up (150s); No lives (shuffle=0 sau khi dùng); Leave → GameOver summary
- ❌ Zen — không áp dụng

**Implementation:**
- `scan_board_for_valid_moves()` — O(n⁴) với early-exit (reuse `find_hint_path()`). **KHÔNG gọi trong `_process()`.**
- Trigger check sau mỗi: evaluate_selection, dùng power-up, refill
- `trigger_end_game(reason)` → cập nhật ResultLabel, FinalScoreLabel, TimePlayedLabel, MaxComboLabel → hiện GameOverLayer

---

## Tiến độ

### ✅ Đã hoàn thành

**T1 (2026-04-29)**
- Use Case + kiến trúc hệ thống
- Cơ chế gameplay cốt lõi (Rectangle Selection)
- 4 chế độ chơi
- 3 power-ups: Hint, Shuffle, Remove
- 4 ô đặc biệt trong Mutation
- Hệ thống chuyển cảnh
- **Refactor tile system:** `BaseTile` + 4 subclass + `TileFactory` (tách logic khỏi `main.gd`)
- **Bug #1:** Căn giữa tile trong selection box, thêm padding 20px
- **Bug #2:** Timer Zen/Gravity/Mutation dừng khi pause (`accumulated_time += delta`); Virus timer cũng dừng
- **Bug #3:** Joker hiện 0 trong sum display khi kéo (via `get_effective_value()`)
- **Bug #4:** Refill sinh đúng ô đặc biệt theo mode (via `TileFactory.roll()`)

**T2 (2026-04-30)**
- Board 8×12 (tăng từ 6×8), dynamic `tile_size` tự tính theo screen
- Tile visual gap: scale = 90% cell size (`TILE_VISUAL_RATIO = 0.90`)
- Weighted numbers 1–9 (1-5 chiếm 71%) trong `TileFactory._weighted_normal_val()`
- Guaranteed solvable board cho Classic: retry tối đa 5 lần sau `scan_board_for_valid_moves()`
- `scan_board_for_valid_moves()` — O(n⁴) early-exit, reuse `find_hint_path()`
- End game: `trigger_end_game(reason)` → popup lý do + điểm + thời gian + max_combo
- Power-ups: bool → int counts, stackable; Zen refill toàn bộ mỗi 100 điểm
- Remove cancel: bấm lại Remove để hủy
- Combo multiplier cho **tất cả mode** (timeout 5s, real-clock)
- Gravity: countdown 150s + 3 lives (shuffle = mạng) + +1s/tile time bonus
- Gravity L1–L4: DOWN / RIGHT / LEFT / RANDOM (UP/DOWN/LEFT/RIGHT ngẫu nhiên mỗi nước)
- Level threshold: 50 điểm/level; `GravityLevelLabel` hiển thị "Lv.X"
- New GameOver UI: TimePlayedLabel, MaxComboLabel, LivesLabel (Gravity)
- Leave trên pause menu: Classic/Gravity → `trigger_end_game("LEFT")` thay vì về menu thẳng
- Debug UI toggle: nút "TEST" góc trên phải, expand ra 4 nút debug (ẩn trước APK build)
- Tất cả text in-game bằng tiếng Anh

**T3 (2026-05-02)**
- Main Menu: tên game, nút Play / Highscore / Help / Quit (`main_menu.tscn/gd`)
- Mode Select screen: 4 card với description + nút Play (`mode_select.tscn/gd`)
- Zen + Mutation save/load backend: `Global.save_game()` / `load_game()`, file `user://save_zen.json` / `save_mutation.json`
- Zen + Mutation save/load UI: overlay Continue / New Game / Cancel khi vào mode có save
- Gravity level transition animation: label flash + scale tween khi lên level
- Tutorial animated demo: 5 màn (How to Play, Virus, Negative, Mystery, Joker) — list screen + demo screen với cursor/selection animation tự replay (`tutorial.tscn/gd`)
- `highscore.tscn/gd`: stub (nút Back, chưa có dữ liệu)
- **Bug fix:** Virus tile scale không trở về đúng sau animation; score hiện "12.0" sau Continue; Zen cộng +1 power-up sau Continue (nguyên nhân: JSON parse float → fix bằng `int()`)
- **Decisions:** Zen + Mutation end game khi hết nước + hết power-up (bỏ exception `ZEN`); Gravity có refill 70% sau mỗi gravity apply

**T4 (2026-05-04)**
- Density fix `calculate_points()` Zen/Mutation: threshold 0.3 — nếu tile thật < 30% bbox → `base = tile_count` thay vì `bbox_area`
- `data/zen_levels.gd` — config 12 level (unlock score, constraint, text)
- `scripts/zen_level_manager.gd` — `validate_constraint()` + helper getters
- `Global`: thêm `zen_current_level`, `zen_unlocked_levels`
- Extend save/load Zen: ghi/đọc `current_level` + `unlocked_levels`
- `_check_zen_level_unlock()` trong `main.gd` — unlock level mới khi đủ điểm, hiện badge
- **Decision:** Constraint Zen bị revert — giữ infrastructure cho **Challenge mode** (T5). Zen về lại đơn giản.

**T5 (2026-05-05)**
- Challenge Mode đầy đủ: card trong mode select, save/load qua `user://save_challenge.json`
- `main.gd` xử lý CHALLENGE như ZEN (count-up, pause-aware, refill 100pts, milestone power-up)
- `scripts/zen_board_generator.gd` — Smart Board Gen: guaranteed solution rect + sparse holes L10-L12
- Constraint check trong `evaluate_selection()`: sum=10 nhưng sai shape → "Wrong shape!" + reset combo
- Hint fix: `find_hint_path()` filter constraint → `scan_board_for_valid_moves()` constraint-aware
- HUD: `ChallengeLevelLabel` + `ChallengeConstraintLabel` + nút "⇄ Levels" trực tiếp trên HUD
- Pause menu: nút "Change Level" → panel danh sách 12 level (locked/unlocked) → chọn → regen board
- Debug: nút "Next Lv" trong TEST panel cho CHALLENGE
- **Highscore** (`highscore.gd/tscn`): top 3 per mode (Classic/Gravity/Mutation/Zen/Challenge)
  - `Global.submit_score(mode, score, time, max_combo)` → `user://highscore.json`
  - Gọi trong `trigger_end_game()` (mọi mode) + `_on_btn_quit_pressed()` else branch (Zen/Challenge/Mutation khi Leave)
  - UI: `ScrollContainer` chứa `HBoxContainer` tab buttons (swipe ngang), content area bên dưới

**T7 (2026-05-31) — UI Polish + Adventure Mode rework**

*UI Polish (Phase 1–4):*
- **Theme Foundation:** `theme_tokens.gd` — Mint Cream palette, StyleBox helpers, font helpers (Inter Variable + JetBrains Mono Variable)
- **Gravity Apple Tile:** `apple_draw.gd` — bezier 64-point apple shape, stem animation theo hướng gravity
- **In-game HUD redesign:** score sub-label, mode chip, power-up badges (count pill), combo badge; power-up button size giảm 120→96px cho vừa vặn hơn
- **Selection + Score animations (Phase 4):** dashed border selection rect (4 cạnh `draw_dashed_line`), sum bubble 3 màu (gray/mint/đỏ theo under/exact/over), score chip có pill background màu combo, tự co theo độ dài text

*UI Polish (Phase 5 — Clear animation + VFX):*
- **Staggered tile pop:** tiles biến mất lần lượt (delay 30ms/ô), mỗi ô scale 1.0→1.15→0 thay vì đồng loạt
- **Enhanced particle burst:** 18 hạt chính + 8 white sparkle layer per tile
- **Score chip pop:** chip `+N` xuất hiện từ 1.4× → 1×, rồi bay lên fade
- **Combo badge escalation:** bump scale theo combo: x2=1.2×, x3=1.3×, x4=1.4×, x5+=1.5×

*Tile redesign (cùng commit Phase 5):*
- **Virus:** bỏ 4 corner dots; HP ngẫu nhiên 1–5 ticks; spread khi countdown = 0 (không còn random value=0); fix bug `set_script()` → dùng `TileFactory.make("VIRUS")` khi lây
- **Negative:** bỏ `▾` chevron trang trí
- **Joker:** bỏ white dot 8×8 trang trí
- **Spawn rates Mutation:** MYSTERY 19.5%, VIRUS 6%, JOKER 1%, NORMAL/NEGATIVE ~73.5%

*Bug fixes phát hiện trong quá trình polish:*
- Power-up badge count không hiện lần đầu vào game → `update_power_up_ui()` gọi thiếu sau khi tạo badge node
- 2 dải sáng mép trái/phải board → `BOARD_BG` chỉ vẽ trên rect board, fix bằng vẽ full-width cho toàn game area
- `_update_challenge_hud()` có guard `if gameplay_mode != "CHALLENGE": return` → ZEN mode không bao giờ update label, fix thành `not in ["ZEN", "CHALLENGE"]`
- Hint algorithm dùng loop bounds làm bbox → không khớp với `evaluate_selection` dùng tile-position bbox; fix: tính bbox từ vị trí tile thực trong `find_hint_path()`

*Adventure Mode (đổi tên từ Challenge):*
- Đổi tên display "Challenge" → "Adventure" (internal string `"CHALLENGE"` giữ nguyên)
- **Lý do đổi tên:** các safety net được thêm vào làm mode không còn mang tính "thử thách" theo nghĩa truyền thống; "Adventure" phản ánh đúng hơn trải nghiệm leo 12 biome có constraint
- Milestone refill: 50đ/lần → +3 PU (Zen giữ 100đ → +1); Adventure khó hơn Zen nên cần refill thường và nhiều hơn
- Hết move hợp lệ: auto-shuffle miễn phí (không tiêu shuffle count), thông báo; thay vì gameover ngay
- Shuffle guarantee: thử tối đa 5 lần để tìm hoán vị có nước hợp lệ; nếu vẫn không có → refill board mới bằng ZenBoardGenerator (guaranteed valid) + "Board refreshed!"
- **Lý do thiết kế:** với constraint hình dạng, tập hợp số hiện tại đôi khi không thể tạo tổng 10 thỏa constraint bất kể xáo thế nào → cần fallback sinh board mới thay vì gameover vô lý

*UI Polish (Phase 6 — Main Menu + Mode Select):*
- **`main_menu.gd`:** background APP_BG, logo "trace" + tile "10" (Inter 800 + Mono 800), 5 nút nav (PLAY primary mint 128px, MODES + HIGHSCORE + ACHIEVEMENTS + TUTORIAL + QUIT secondary Inter 600), mode chip cạnh PLAY hiện mode vừa chơi (MINT_DARK), floating bg 6 số + 6 tile đặc biệt + 5 sparkle dots, Settings cog panel góc trên phải
- **`mode_select.gd`:** mini logo top bar, heading "CHOOSE A MODE" (Inter 600 letter-spaced) + "5 ways to play" (Inter 800 bold), 5 hero card (PanelContainer + icon 116×116 + tên bold + tag + BEST score/label cột phải + chevron), click via `gui_input`; PLAY → `Global.last_played_mode`
- **Mode icons:** emoji (⌛ Classic, 🍎 Gravity, ☯ Zen, ⛰ Adventure, 🧠 Mutation)
- **`Global.last_played_mode`**: lưu mode vừa chơi, PLAY button dùng để chơi tiếp không cần vào mode select

*Gameplay balance (cùng session Phase 6):*
- **Combo cap x5:** `COMBO_MAX = 5`, `combo_count = min(combo_count + 1, COMBO_MAX)`
- **Achievement "Unstoppable" (`combo_10`) đổi điều kiện:** thay vì x10 combo → land 5 hits liên tiếp khi đang ở x5; track bằng `_combo_x5_streak` (reset khi combo bị phá)

*UI Polish (Phase 7 — Pause + Game Over + Save Resume overlays):*
- **Approach chung:** `PanelContainer` 600×800px, `VBoxContainer.alignment = CENTER`, backdrop dim, shadow card. Buttons reparented từ .tscn node (signal connections giữ nguyên).
- **Pause overlay** (`_setup_pause_overlay()` trong `main.gd`): icon chip 120px mint soft, ⏸ emoji 52px, "PAUSED" 34px + outline, gap 40px, buttons primary 112px / secondary 100px / ghost 64px, border-radius 28px pill, btn gap 18px
- **Game Over overlay** (`_setup_game_over_overlay()` trong `main.gd`): icon chip 100px với màu theo lý do (TIME_UP=amber, NO_MOVES=purple, NO_LIVES=hồng `#f09898`, LEFT=xanh xám `#a8bcc8`), score 57px Mono + outline, kind label 23px + outline, stat cell 110px (value 43px/label 19px `#546560`), NEW HIGH badge mint dark pill, RESTART primary + LEAVE ghost
- **Save Resume card** (`_style_save_submenu()` trong `mode_select.gd`): icon chip 88px ▶ MINT_DARK, "SAVED GAME" kicker 23px `#546560`, mode name 57px bold + outline, stat cells 110px, CONTINUE/NEW GAME/CANCEL styled riêng
- **Typography:** primary text + outline_size=2 (fake bold), secondary/label text màu `#546560` (darker SUB_TEXT), tất cả button Inter 700
- **Persist `last_played_mode`:** `Global.save_config()` / `load_config()` → `user://config.json`; gọi khi vào game, load khi app khởi động

*UI Polish (Phase 10 — Highscore + Achievement screen redesign):*
- **Highscore** (`highscore.gd`): top bar ← 80px `sb_menu_button()` + title 34px; tab pills pill-shape với `content_margin` 28/12, active=accent solid / inactive=accent text; `StyleBoxEmpty` trên ScrollContainer để tránh hero card corner artifact; Hero card accent màu theo mode, ghost emoji `horizontal_alignment=RIGHT` + `vertical_alignment=TOP` (PanelContainer override anchor); stat boxes 3 cột (GAMES/AVG hoặc BEST PTS/BEST CB); top runs rank badge 34×34; Gravity sort by level desc; `submit_score()` thêm `level_reached` param; `_fmt_score()` comma-separated; debug nút "Reset HS"; combo uncap (track thật, multiplier `min(combo, 5)`)
- **Achievement screen** (`achievement_screen.gd`): badge chip 64×64px, icon 32px, tên 20px, status 17px; GridContainer 3 cột gap 10; scrollbar ẩn bằng `modulate = Color(0,0,0,0)` (không dùng `visible=false` vì bị reset); `SCROLL_MODE_DISABLED` ngang
- **Typography chung:** tất cả font weight ≥ 700; outline same-color (outline_size=2) cho text tối trên nền sáng, outline đen mờ (0.15–0.22 alpha) cho text trắng trên nền màu — trick "fake bold stroke"
- **Hero card shadow bug:** `StyleBoxFlat` shadow render dạng rectangular blur (không follow rounded corners) → thấy halo vuông mờ ở 4 góc; fix bằng xóa shadow khỏi hero card

⚠️ **Lưu ý kỹ thuật overlay:**
- Dùng `PanelContainer` (không phải `Panel`) để MarginContainer bên trong tự fill đúng
- Card width/height cứng 600×800px (không responsive) — đủ cho viewport ~720px
- Emoji icons trong Game Over (⏱ ✕ ♡ ← ◉) có thể render màu hệ thống nếu font fallback về emoji font — nếu cần fix thì vẽ bằng ColorRect/Panel thay thế (như cách đã làm thử cho pause rồi revert)

**T6 (2026-05-18)**
- **Achievement System** — 25 thành tựu, 6 category (Beginner, Score, Combo, Mode, Special Tiles, Quirky)
- `data/achievements.gd` — `AchievementData.LIST` config 25 entry (id, name, desc, target); `get_def(id)`
- `global.gd` — `unlock_achievement(id)`, `update_achievement_progress(id, value)`, `load/save_achievements()`; signal `achievement_unlocked(id)`; `track_mode_played(mode)` cho `all_modes`
- Save: `user://achievements.json` — key `_modes_played` lưu chung trong cùng file
- Per-game tracking: `Global.hints_used_this_game` (reset mỗi game) + `_mutation_types_cleared` (local main.gd)
- Trigger: 25 hook trải đều trong `evaluate_selection()`, `trigger_end_game()`, `check_gravity_level_up()`, `_check_zen_milestone()`, `_check_zen_level_unlock()`, `_on_btn_*_pressed()`, `tile_mystery.gd:select()`, `kill_tile_from_virus()`
- **Notification popup** (`achievement_popup.gd/tscn`): `CanvasLayer` layer=10, queue nhiều unlock liên tiếp, slide-in từ phải 0.3s → đứng 2.5s → fade out; connect signal trong `_ready()`; add vào `main.tscn`
- **Achievement screen** (`achievement_screen.gd/tscn`): danh sách 25 thành tựu chia category, icon ★/○, progress "X/Y" cho target>1, dim 60% khi locked; nút Achievements thêm vào main menu giữa Highscore và Help

---

## ⚠️ Lưu ý kỹ thuật

- **`DEBUG_MODE = true` trong `main.gd`** — **BẮT BUỘC set `false` trước khi build APK**
- **Combo timer dùng real clock** (`Time.get_unix_time_from_system()`) — không dừng khi pause game. Chấp nhận được vì combo timeout 5s và pause thường ngắn.
- **Tile hitbox KHÔNG scale theo `TILE_VISUAL_RATIO`** — chỉ visual (sprite) được scale. CollisionShape2D trong `tile.tscn` giữ nguyên kích thước cell. Cần verify trên thiết bị thật rằng touch vào khoảng trống giữa tiles không trigger nhầm.
- **Tile gap: giữ TILE_VISUAL_RATIO (0.90) thay vì actual gap** — T7 UI handoff đề xuất 4dp gap thật (8px tại 720px viewport) dùng GridContainer. Quyết định: giữ approach hiện tại (visual gap qua scale) vì ít rủi ro hơn. **TODO tiềm năng:** nếu hitbox gap trên thiết bị thật có vấn đề → migrate sang actual gap: đổi positioning sang `x * (tile_size + TILE_GAP)`, thu CollisionShape2D xuống tile_size thật, cập nhật `pixel_to_grid()` math.
- **`total_duration` bị modify động trong Gravity** — mỗi tile ăn được cộng `GRAVITY_TIME_PER_TILE` (1.0s) vào `total_duration`. Không phải bug.
- **`scan_board_for_valid_moves()` là O(n⁴)** — chỉ gọi sau actions (evaluate_selection, power-up, refill). KHÔNG gọi trong `_process()`.
- **Board 8×12 = 96 ô** — `grid_cols=8`, `grid_rows=12`. `tile_size` tự tính: `screen_w * 0.90 / grid_cols`.
- **Gravity `shuffle_count = 3` = lives** — khi `shuffle_count` về 0 sau khi dùng → `trigger_end_game("NO_LIVES")` ngay.

---

## ✅ Feature T5 (DONE 2026-05-05) — Challenge Mode

### Zen Mode Improvements — Level System

**Identity:** Hành trình thiên nhiên qua 12 biome với gameplay constraint riêng. Player agency tuyệt đối — tích điểm tự do, tự quyết khi nào chuyển level. Mỗi level có thử thách hình dạng vùng kéo riêng + theme visual/audio.

#### Nguyên tắc

- **Tích điểm liên tục:** Điểm trong save tích lũy mãi (không reset khi chuyển level). Có thể đủ điểm unlock L4 dù đang ở L2.
- **Chuyển level tuần tự:** Phải lên L2 → L3 → L4. Không skip.
- **Player agency:** Đủ điểm = unlock + có quyền chuyển. KHÔNG tự động chuyển.
- **Đã unlock = luôn vào lại được** qua pause menu.
- **Constraint chỉ áp dụng cho Zen** — Classic/Mutation/Gravity giữ nguyên.

#### Bug fix kèm theo: Farming bounding box

Hiện Zen/Mutation tính `base = bbox_area`, dễ farm bằng kéo lan tràn (5 tile thật rải rác → bbox 8×12 = 96 điểm).

**Fix:** Thêm rule **density** vào `calculate_points()` cho Zen/Mutation:
```gdscript
# main.gd: trong calculate_points() cho Zen/Mutation
var bbox_area = (max_x - min_x + 1) * (max_y - min_y + 1)
var tile_count = sel_tiles.size()
var density = float(tile_count) / float(bbox_area)

if density < 0.4:
    base = tile_count   # Penalize bbox quá thưa
else:
    base = bbox_area    # Reward bbox đủ đầy
```

Threshold 40% là đề xuất ban đầu — tinh chỉnh khi playtest.

#### Bảng 12 Level

Constraint kết hợp 2 metric: **bounding box** + **tile count**. Vuông tuyệt đối chỉ ở L3 và L6.

| # | Level | Biome | Unlock | Constraint | Icon UI |
|---|---|---|---|---|---|
| L1 | **Meadow** | 🌾 | 0 | `tile_count ≥ 3` | `▭▭▭` |
| L2 | **Forest** | 🌲 | 50 | `tile_count ≥ 3` AND `bbox.area ≥ 4` | `▭▭▭` + `□` |
| L3 | **Riverside** | 🏞️ | 150 | `bbox vuông` (≥2×2) AND `tile_count ≥ 3` | `▦` |
| L4 | **Ocean Shore** | 🌊 | 300 | `tile_count ≥ 4` AND `bbox.area ≥ 6` | `▭▭▭▭` |
| L5 | **Deep Sea** | 🐠 | 500 | `bbox.size ≥ 2×3 (or 3×2)` AND `tile_count ≥ 4` | `▦▭` |
| L6 | **Coral Reef** | 🪸 | 750 | `bbox vuông ≥ 3×3` AND `tile_count ≥ 5` | `▦` (lg) |
| L7 | **Desert** | 🏜️ | 1000 | `tile_count ≥ 5` AND `bbox.area ≥ 8` | `▭▭▭▭▭` |
| L8 | **Canyon** | 🏔️ | 1300 | `bbox.size ≥ 3×3` (vuông or chữ nhật) AND `tile_count ≥ 5` | `▦▦` |
| L9 | **Mountain** | ⛰️ | 1700 | `tile_count ≥ 6` AND `bbox.area ≥ 9` | `▭...▭` |
| L10 | **Snow Peak** | 🏔️ | 2200 | `bbox.area ≥ 12` AND `tile_count ≥ 6` | `▦▦` (xl) |
| L11 | **Aurora** | 🌌 | 2800 | `tile_count ≥ 7` AND `bbox.area ≥ 12` | `▭...▭` |
| L12 | **Cosmos** | ✨ | 3500 | `bbox.area ≥ 16` AND `tile_count ≥ 8` | `▦▦▦` glow |

**Logic thiết kế:**
- L1, L2 = warm-up (size dễ)
- L3 = vuông 2×2 (shape mới, dễ thỏa)
- L4, L5, L7, L9 = tăng dần size + area
- L6 = vuông 3×3 (peak shape difficulty)
- L8 = bbox 3×3 cho phép cả chữ nhật (đỡ ngặt hơn L6)
- L10, L11, L12 = endgame, lớn dần

#### UI in-game (Zen)

```
┌──────────────────────────────────┐
│  L3 Riverside  [▦]      [pause]   │
│  Score: 187                        │
│  ─────────────                     │
│  Next: L4 Ocean Shore  ✓ unlocked  │
│  [Tap to travel]                    │
│  ┌─ board ─┐                        │
│  └─────────┘                        │
└──────────────────────────────────┘
```

- Icon constraint (24×24) cạnh tên level
- Tap icon → tooltip mô tả constraint đầy đủ
- Kéo sai constraint → flash icon đỏ + "Wrong shape" 1s + reset combo

#### Pause menu (Zen)

```
─ Resume
─ Restart current level
─ Change Level ▾
   ✓ L1 Meadow            (visited)
   ✓ L2 Forest            (visited)
   ✓ L3 Riverside         ← current
   ✓ L4 Ocean Shore       (unlocked, not visited)
   🔒 L5 Deep Sea          (need 500 pts)
─ Save
─ Leave
```

#### Cơ chế chuyển level

**Khi đạt mốc unlock L+1:**
- Sound chime nhẹ (1 nốt)
- Badge "L4 unlocked! Tap to travel" ở góc với glow
- Người chơi tiếp tục chơi nếu muốn (vẫn tích điểm cho L+2, L+3...)

**Khi tap badge / chọn từ pause menu:**
- Fade out scene (1.5s)
- Center text: "Welcome to Ocean Shore" (1s)
- Fade in với theme + constraint mới
- BGM crossfade (nếu có ở T5)
- **Smart generate board mới** với constraint level mới

#### Save data structure (extend save_zen.json hiện tại)

```json
{
  "current_level": 3,
  "unlocked_levels": [1, 2, 3, 4],
  "total_score": 387,
  "play_time_seconds": 1840,
  "max_combo": 5,
  "board_state": [...],
  "powerups": {"hint": 2, "shuffle": 1, "remove": 3}
}
```

`current_level` mặc định = 1 cho save mới. `unlocked_levels` mặc định = `[1]`.

---

### Implementation Notes (Zen Level System)

#### Files mới
- `data/zen_levels.gd` — config 12 level (data-driven)
- `scripts/zen_level_manager.gd` — validation + state management
- `scripts/zen_board_generator.gd` — **smart generation** (key file)
- `scenes/zen_level_transition.tscn` — fade animation

#### Files cần sửa

**`main.gd`:**
- `calculate_points()` (line 861): thêm density check cho Zen/Mutation
- `evaluate_selection()`: sau check `sum==10`, thêm Zen constraint check
- `generate_board()`: nếu mode == ZEN → gọi `ZenBoardGenerator.generate(level)` thay vì random thông thường
- Thêm `_apply_zen_level_theme(level)`: load palette + ambient
- Thêm logic trigger unlock check sau mỗi lần cộng điểm

**`global.gd`:**
- Extend `save_game()` / `load_game()` cho Zen — thêm `current_level`, `unlocked_levels`
- Default values cho save mới

**Pause menu UI:** thêm submenu "Change Level"

#### Smart Board Generation (CRITICAL)

Đây là thay đổi quan trọng nhất. Thay vì random rồi check, **gieo guaranteed solution trước**.

**Algorithm chung:**

```gdscript
# zen_board_generator.gd
class_name ZenBoardGenerator

static func generate(level: int) -> Dictionary:
    var rules = ZenLevels.LEVELS[level - 1].constraints
    var board = _create_empty_board(8, 12)
    
    # Bước 1: Gieo guaranteed solution
    var solution_rect = _pick_solution_rect(rules)
    var solution_tiles = _generate_tiles_summing_to(10, rules)
    _place_solution(board, solution_rect, solution_tiles)
    
    # Bước 2: Fill phần còn lại random weighted
    _fill_remaining_random(board)
    
    return board

static func _pick_solution_rect(rules: Dictionary) -> Rect2i:
    # Chọn vị trí + size phù hợp với constraint
    if rules.has("must_be_square"):
        var min_size = rules.get("min_square_size", 2)
        var size = randi_range(min_size, min(min_size + 1, 4))
        # ... pick top-left random
        return Rect2i(x, y, size, size)
    
    if rules.has("min_bbox_size"):
        var ms = rules.min_bbox_size
        # Random orientation (ms.x × ms.y) hoặc (ms.y × ms.x)
        # ...
    
    if rules.has("min_bbox_area"):
        # Pick rect có area >= min_bbox_area
        # ...
    
    # Default: pick random rect đủ size cho min_tiles
    var n = rules.get("min_tiles", 3)
    return _random_rect_with_capacity(n)

static func _generate_tiles_summing_to(target: int, rules: Dictionary) -> Array:
    # Tạo array N số (1-9) có tổng = target
    var n = rules.get("min_tiles", 3)
    var numbers = []
    var remaining = target
    
    for i in range(n - 1):
        var max_val = min(9, remaining - (n - i - 1))
        var val = randi_range(1, max(1, max_val))
        numbers.append(val)
        remaining -= val
    
    numbers.append(remaining)  # ô cuối lấy số dư
    numbers.shuffle()
    return numbers
```

**Per-level generators:**

Hầu hết level dùng generator chung. Nhưng L3, L6 (vuông) cần generator riêng nhỏ:

```gdscript
static func _generate_square_solution(rules):
    var size = rules.get("min_square_size", 2)
    # Random size từ min đến min+1 (cho variety, vẫn dễ thỏa)
    # Pick (x, y) sao cho không out of bound
    # Generate ≥min_tiles số có tổng=10, fill vào ô của vùng vuông
```

#### Constraint validation

```gdscript
# zen_level_manager.gd
const ZenLevels = preload("res://data/zen_levels.gd")

static func validate_constraint(rect: Rect2i, tile_count: int, level: int) -> Dictionary:
    var rules = ZenLevels.LEVELS[level - 1].constraints
    var bbox_w = rect.size.x
    var bbox_h = rect.size.y
    var bbox_area = bbox_w * bbox_h

    if rules.has("min_tiles") and tile_count < rules.min_tiles:
        return {"valid": false, "reason": "Need ≥%d tiles" % rules.min_tiles}

    if rules.has("min_bbox_area") and bbox_area < rules.min_bbox_area:
        return {"valid": false, "reason": "Area too small"}

    if rules.has("must_be_square") and bbox_w != bbox_h:
        return {"valid": false, "reason": "Must be square"}

    if rules.has("min_square_size"):
        if bbox_w != bbox_h or bbox_w < rules.min_square_size:
            return {"valid": false, "reason": "Must be ≥%dx%d square" % [rules.min_square_size, rules.min_square_size]}

    if rules.has("min_bbox_size"):
        var ms = rules.min_bbox_size
        var ok = (bbox_w >= ms.x and bbox_h >= ms.y) or (bbox_w >= ms.y and bbox_h >= ms.x)
        if not ok:
            return {"valid": false, "reason": "Bbox too small"}

    return {"valid": true}
```

#### Data-driven config

```gdscript
# data/zen_levels.gd
class_name ZenLevels

const LEVELS = [
    {
        "id": 1, "name": "Meadow", "biome": "meadow",
        "unlock_score": 0,
        "constraints": {"min_tiles": 3},
        "constraint_text": "Vùng ≥ 3 ô",
        "constraint_icon": "res://assets/ui/icons/zen_l1.png",
        "palette": "meadow",
    },
    {
        "id": 2, "name": "Forest", "biome": "forest",
        "unlock_score": 50,
        "constraints": {"min_tiles": 3, "min_bbox_area": 4},
        "constraint_text": "Vùng ≥ 3 ô và bbox ≥ 4",
    },
    {
        "id": 3, "name": "Riverside", "biome": "riverside",
        "unlock_score": 150,
        "constraints": {"must_be_square": true, "min_square_size": 2, "min_tiles": 3},
        "constraint_text": "Vùng vuông (≥2×2)",
    },
    # ... L4 - L12
]
```

#### Tích hợp với combo

- Combo Zen vẫn hoạt động bình thường
- Kéo sai constraint → reset combo (như kéo sai sum)
- `evaluate_selection()` flow:
  1. Check `sum == 10`
  2. **(Zen only)** Check `validate_constraint()` → fail: "Wrong shape", reset combo, return
  3. Pass cả 2 → `calculate_points()` (đã có density fix) → cộng vào `total_score`
  4. Check `total_score >= LEVELS[current_level].unlock_score` → mark unlocked + show badge

#### Cảnh báo kỹ thuật

- **Smart generation đảm bảo 100% solvable** — không cần fallback. Nhưng vẫn nên có safety check `scan_board_for_constraint()` sau generate để verify (an toàn hơn).
- **Số 1-9 weighted distribution** vẫn áp dụng cho phần "fill random còn lại" (không áp cho guaranteed solution — solution dùng partition algorithm để tổng đúng = 10).
- **Constraint icon spritesheet:** 12 icon 24×24 px → 1 file `assets/ui/zen_constraint_icons.png` (4×3 grid). Có thể dùng Unicode (▭▦) tạm thời ở T4.
- **Asset visual ở T4:** chỉ palette khác nhau (4-5 màu/level). Particle/BGM → T5.
- **`density` threshold (0.4):** số ban đầu, cần playtest. Có thể chỉ áp dụng Zen nếu Mutation bị nerf quá nặng.
- **Refill khi chuyển level:** gọi `ZenBoardGenerator.generate(new_level)` — không reuse board cũ.
- **Khi nào regenerate trong session:** Zen hiện tại refill 70% sau mỗi gravity apply (theo decision T3). Cần kiểm tra: refill này có cần dùng smart generation không, hay chỉ apply cho board ban đầu + level transition? **Đề xuất:** smart generation chỉ ở 2 thời điểm — start level mới và Shuffle power-up; refill 70% giữa game vẫn dùng random thường (vì board đã guaranteed có valid move từ đầu).

---

### Sound + VFX
- SFX: tile clear, combo hit, power-up use, game over (jsfxr)
- BGM: 1 track ambient loop (Pixabay)
- VFX: `GPUParticles2D` khi clear tiles, Tween feedback khi combo tăng

### Highscore screen ✅ (done T5)
- Top 3 per mode, save `user://highscore.json`
- Tab bar = `ScrollContainer` + `HBoxContainer` buttons (swipe ngang trên Android)

---

## 🏅 Hệ thống Thành tựu (Achievement System)

**✅ Done T6 (2026-05-18)**

### Files

| File | Vai trò |
|------|---------|
| `data/achievements.gd` | Config 25 thành tựu (`AchievementData.LIST`, `get_def(id)`) |
| `achievement_popup.gd/tscn` | Notification popup — `CanvasLayer` layer 10, queue, slide+fade |
| `achievement_screen.gd/tscn` | Màn danh sách 25 thành tựu, 6 category |

### Lưu ý kỹ thuật

- **Signal:** `Global.achievement_unlocked(id)` — popup connect trong `_ready()`, không cần wire thủ công
- **`unlock_achievement()` idempotent** — gọi bao nhiêu lần cũng an toàn, chỉ emit signal lần đầu
- **`update_achievement_progress(id, value)` tự unlock** khi `value >= target` — không cần gọi `unlock_achievement()` riêng
- **`hints_used_this_game`** reset trong `setup_mode_config()` — dùng cho achievement `no_hint` (Classic)
- **`_mutation_types_cleared`** là local var trong `main.gd`, reset trong `setup_mode_config()` — track 4 loại tile Mutation
- **`_modes_played`** lưu bền vững trong `achievements.json` (key `_modes_played`) — track qua nhiều session cho `all_modes`
- **Popup queue:** nhiều achievement unlock cùng lúc → hiện lần lượt, không chồng, không mất

**Cần thêm tracking trong Global:** `modes_played[]`, `total_hints_used`, `total_cancels_remove`, `virus_exploded_once`.

### Danh sách 25 Thành tựu

#### 🟢 Beginner
| ID | Tên | Điều kiện |
|----|-----|-----------|
| `first_ten` | Hello, Ten! | Ghi điểm lần đầu tiên |
| `first_powerup` | Helping Hand | Dùng power-up lần đầu |
| `all_modes` | Explorer | Chơi thử cả 5 mode |
| `first_combo` | On a Roll | Đạt combo x2 lần đầu |
| `first_special` | What's This? | Chạm vào ô Mystery lần đầu |

#### 🏆 Score (single game)
| ID | Tên | Điều kiện |
|----|-----|-----------|
| `score_100` | Century | Đạt 100 điểm trong 1 game |
| `score_500` | High Roller | Đạt 500 điểm trong 1 game |
| `score_1000` | Four Digits | Đạt 1000 điểm trong 1 game |

#### ⚡ Combo
| ID | Tên | Điều kiện |
|----|-----|-----------|
| `combo_5` | Pentagram | Đạt x5 combo |
| `combo_10` | Unstoppable | Đạt x10 combo |
| `combo_classic` | Speed Demon | Đạt x5 combo trong Classic |

#### 🎮 Mode-specific
| ID | Tên | Điều kiện | Mode |
|----|-----|-----------|------|
| `classic_survive` | Against the Clock | Kết thúc Classic còn ≥ 60s | Classic |
| `gravity_lv4` | Gravitational Pull | Lên Level 4 trong Gravity | Gravity |
| `gravity_3lives` | Untouchable | Đến Level 3 mà không mất mạng | Gravity |
| `zen_refill3` | Zen Garden | Trigger milestone refill 3 lần (300 điểm) | Zen |
| `challenge_l6` | Cube Master | Unlock Level 6 Challenge (3×3 square) | Challenge |
| `challenge_l12` | Cosmos | Unlock Level 12 Challenge | Challenge |
| `mutation_alltype` | Collector | Dọn được cả 4 loại ô đặc biệt trong 1 game | Mutation |

#### 🦠 Special Tiles
| ID | Tên | Điều kiện |
|----|-----|-----------|
| `virus_cleared` | Defused | Dọn Virus trước khi nổ |
| `joker_used` | Wild Card | Dùng Joker thành công |
| `negative_win` | Glass Half Empty | Dùng ô âm để balance tổng = 10 |

#### 🎲 Quirky / Secret
| ID | Tên | Điều kiện |
|----|-----|-----------|
| `big_selection` | Hoarder | Chọn vùng ≥ 20 ô trong 1 nước |
| `no_hint` | I Don't Need Help | Hoàn thành Classic không dùng Hint lần nào |
| `cancel_remove` | Never Mind | Cancel Remove mode (bấm Remove lần 2) |
| `virus_explode` | Oops | Để Virus nổ lần đầu |

---

## 💡 Future Work (KHÔNG làm trong scope đồ án)

- Ô đặc biệt tạo từ ghép ô (Candy Crush style)
- Cải thiện cơ chế Shuffle
- Online leaderboard
- Tutorial interactive

---

## 📅 Lộ trình 8 tuần

**Deadline:** Cuối tháng 6. **Capacity:** 15-20h/tuần.

| Tuần | Trọng tâm | Deliverable chính |
|---|---|---|
| **T1** ✅ | Bug fix + Hệ thống điểm mới | Sửa 5 bug, code combo + bonus tiles |
| **T2** ✅ | End game logic + Gravity levels | Scan board, popup end game, 3-4 level Gravity |
| **T3** ✅ | UI overhaul (phần 1) + Tutorial | Main menu, mode select, save/load, tutorial animated |
| **T4** ✅ | Zen level system (infrastructure) + density fix | ZenLevels, ZenLevelManager, save/load level, density threshold |
| **T5** ✅ | Challenge mode + Highscore | Mode mới + constraint gameplay + Smart Board Gen + Hint fix + Highscore screen |
| **T6** ✅ | Achievement System | 25 thành tựu, `Global.unlock_achievement()`, notification popup, Achievement screen |
| **T7** ⏳ | Sound + VFX + UI Polish | ✅ UI Phase 1-7 (theme, tiles, HUD, selection, VFX, Main Menu, Mode Select, Pause/GameOver/SaveResume overlays); ✅ Tile redesign; ✅ Combo cap x5; ✅ Persist last_played_mode; ✅ Phase 10 (Highscore + Achievement screen redesign); ⏳ Phase 11 (Tutorial); ⏳ BGM |
| **T8** | Polish + Playtest + Build APK | Tinh chỉnh balance, build APK ổn định, **bắt đầu chuẩn bị demo** |
| **T9** | Report (70%) + Demo rehearsal | Viết phần lớn report, quay video demo backup |
| **T10** | Report final + Slides + Buffer | Hoàn thiện report, slides, dự phòng |

### Quy tắc bất di bất dịch
- **Sau tuần 7: KHÔNG thêm feature mới**
- **Tuần 8-9: KHÔNG động vào code** (trừ bug crash)
- Mỗi tuần kết thúc → **tag git** (`v0.1`, `v0.2`...)
- **Tuần 7:** APK build phải chạy ổn định trên ít nhất 1 thiết bị thật

---

## 🎤 Chuẩn bị Demo (tuần 6-8)

### Build APK
- Build release APK cuối tuần 6, test trên thiết bị thật (không chỉ emulator)
- Nếu có thể, test trên 2 thiết bị khác cấu hình
- Lưu APK riêng, không update sau ngày bảo vệ -2

### Kịch bản demo (5-7 phút)
1. **Mở app** → main menu (15s)
2. **Tutorial** → flip nhanh để giới thiệu cơ chế (30s)
3. **Classic mode** → chơi 1 phút, show pause/resume (1.5 phút)
4. **Mutation mode** → focus vào: ô đặc biệt + combo + end game (2 phút)
5. **Gravity mode** → show 1-2 level + cơ chế 3 mạng (1.5 phút)
6. **Zen mode** → show save/load (30s)

> **Lưu ý:** Không cố "thắng" trong demo. Mục tiêu là show feature, không phải skill.

### Backup
- **Quay video demo** đầy đủ ở tuần 7 (phòng APK crash giữa buổi)
- Chuẩn bị **save file Zen** có sẵn điểm cao để demo Continue
- Mang theo **APK trên USB** + có sẵn trên 2 thiết bị

---

## 📄 Report

**Status:** Chưa có template chính thức.

### Việc cần làm sớm (tuần 1-2)
- [ ] Hỏi thầy/khoa về **template chính thức** của trường
- [ ] Nếu không có template, dùng cấu trúc chuẩn IT thesis (xem dưới)
- [ ] Bắt đầu **ghi note hằng tuần** vào file `notes.md` (commit/feature/decision quan trọng) — sẽ tiết kiệm rất nhiều thời gian khi viết report ở T7

### Cấu trúc report đề xuất (nếu không có template)
1. Mở đầu / Lý do chọn đề tài
2. Cơ sở lý thuyết (Godot, GDScript, mobile game design)
3. Phân tích & Thiết kế (Use Case, kiến trúc, scene structure)
4. Triển khai (chi tiết các mode, ô đặc biệt, hệ thống điểm)
5. Kết quả & Đánh giá (screenshot, playtest)
6. Kết luận & Future Work

---

## 🎨 Asset Sources

**UI:** [Kenney.nl UI Pack](https://kenney.nl/assets/category:Interface) (CC0) | [itch.io free UI](https://itch.io/game-assets/free/tag-ui)

**Sound:** [Freesound.org](https://freesound.org/) (CC0) | [Pixabay Music](https://pixabay.com/music/) | [jsfxr](https://sfxr.me/)

**Font:** [Google Fonts](https://fonts.google.com/) — chọn 1 heading + 1 body

**VFX (Godot built-in):** `GPUParticles2D`, `Tween`. Tránh shader phức tạp.

---

## Convention

- **Naming:** snake_case cho biến/hàm, PascalCase cho class/Node
- **Indent:** tabs (chuẩn Godot)
- **Signals:** dùng signal cho giao tiếp giữa Node
- **Global state:** chỉ dùng `global.gd` cho data thực sự xuyên scene
- **Asset path:** đặt assets trong `res://assets/{ui,sfx,bgm,fonts}/`
