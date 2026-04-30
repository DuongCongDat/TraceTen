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
- **Gravity** — countdown 150s + 3 lives (mỗi shuffle tiêu 1 mạng). Mỗi ô ăn được +1s time bonus. 4 levels (mỗi 50 điểm): L1 DOWN → L2 RIGHT → L3 LEFT → L4 RADIAL. Timer dừng khi pause. Leave → show GameOver summary.
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
- **Cơ chế:** Mỗi **5 giây**, số trên Virus biến đổi ngẫu nhiên.
- **Hiểm họa:** Nếu Virus về **0** mà chưa dọn → phát nổ, để lại lỗ hổng vĩnh viễn cắt đứt đường nối hình chữ nhật.

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

### Classic / Zen / Gravity
- 1 điểm/ô × combo_multiplier

### Mutation Mode — thêm Bonus theo loại ô
| Loại ô | Bonus |
|--------|-------|
| Ô thường | 1 điểm/ô |
| Ô Joker | +5 bonus |
| Ô Đột Biến (số âm) | +3 bonus |
| Ô Ẩn Số | +2 bonus |
| Ô Virus (dọn được trước khi nổ) | +10 bonus |

**Công thức Mutation:**
```
score = (base_tiles + sum_bonuses) * combo_multiplier
```

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
- Gravity L1–L4: DOWN / RIGHT / LEFT / RADIAL (cx=4, split ngang)
- Level threshold: 50 điểm/level; `GravityLevelLabel` hiển thị "Lv.X"
- New GameOver UI: TimePlayedLabel, MaxComboLabel, LivesLabel (Gravity)
- Leave trên pause menu: Classic/Gravity → `trigger_end_game("LEFT")` thay vì về menu thẳng
- Debug UI toggle: nút "TEST" góc trên phải, expand ra 4 nút debug (ẩn trước APK build)
- Tất cả text in-game bằng tiếng Anh

---

## ⚠️ Lưu ý kỹ thuật

- **`DEBUG_MODE = true` trong `main.gd`** — **BẮT BUỘC set `false` trước khi build APK**
- **Combo timer dùng real clock** (`Time.get_unix_time_from_system()`) — không dừng khi pause game. Chấp nhận được vì combo timeout 5s và pause thường ngắn.
- **Tile hitbox KHÔNG scale theo `TILE_VISUAL_RATIO`** — chỉ visual (sprite) được scale. CollisionShape2D trong `tile.tscn` giữ nguyên kích thước cell. Cần verify trên thiết bị thật rằng touch vào khoảng trống giữa tiles không trigger nhầm.
- **`total_duration` bị modify động trong Gravity** — mỗi tile ăn được cộng `GRAVITY_TIME_PER_TILE` (1.0s) vào `total_duration`. Không phải bug.
- **`scan_board_for_valid_moves()` là O(n⁴)** — chỉ gọi sau actions (evaluate_selection, power-up, refill). KHÔNG gọi trong `_process()`.
- **Board 8×12 = 96 ô** — `grid_cols=8`, `grid_rows=12`. `tile_size` tự tính: `screen_w * 0.90 / grid_cols`.
- **Gravity `shuffle_count = 3` = lives** — khi `shuffle_count` về 0 sau khi dùng → `trigger_end_game("NO_LIVES")` ngay.

---

## 🚧 Feature T3 (tiếp theo)

### Main Menu
- Tên game, nút **Play**, **Highscore** (icon cúp), **Help/Tutorial**, **Quit**

### Zen Mode save/load
- Menu phụ: **Continue**, **Restart**, **New Save**
- Continue hiển thị thêm thời gian + tổng điểm

### In-game HUD + Tile Design
- Heart icon cho lives (Gravity), shuffle icon, đẹp hơn text thuần
- Gravity level transition animation

### Tutorial
- 5 màn hình: 1 cơ chế kéo chọn + 4 ô đặc biệt
- Mỗi màn: 1 GIF/ảnh + 2-3 dòng text + nút Next/Skip

---

## 💡 Future Work (KHÔNG làm trong scope đồ án)

- Ô đặc biệt tạo từ ghép ô (Candy Crush style)
- Cải thiện cơ chế Shuffle
- Online leaderboard
- Achievement system
- Tutorial interactive

---

## 📅 Lộ trình 8 tuần

**Deadline:** Cuối tháng 6. **Capacity:** 15-20h/tuần.

| Tuần | Trọng tâm | Deliverable chính |
|---|---|---|
| **T1** ✅ | Bug fix + Hệ thống điểm mới | Sửa 5 bug, code combo + bonus tiles |
| **T2** ✅ | End game logic + Gravity levels | Scan board, popup end game, 3-4 level Gravity |
| **T3** | UI overhaul (phần 1) | Main menu, mode select, pause menu |
| **T4** | UI overhaul (phần 2) + Tutorial | In-game HUD, tile design, 5 màn tutorial |
| **T5** | Sound + VFX | SFX (jsfxr), BGM (Pixabay), particles, Tween animations |
| **T6** | Polish + Playtest + Build APK | Tinh chỉnh balance, build APK ổn định, **bắt đầu chuẩn bị demo** |
| **T7** | Report (70%) + Demo rehearsal | Viết phần lớn report, quay video demo backup |
| **T8** | Report final + Slides + Buffer | Hoàn thiện report, slides, dự phòng |

### Quy tắc bất di bất dịch
- **Sau tuần 5: KHÔNG thêm feature mới**
- **Tuần 7-8: KHÔNG động vào code** (trừ bug crash)
- Mỗi tuần kết thúc → **tag git** (`v0.1`, `v0.2`...)
- **Tuần 6:** APK build phải chạy ổn định trên ít nhất 1 thiết bị thật

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
