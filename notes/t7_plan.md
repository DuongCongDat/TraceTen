# T7 Plan — Sound + VFX + UI Polish

**Status:** Chưa bắt đầu
**Nguyên tắc:** KHÔNG thêm gameplay feature mới. Chỉ juice + polish.
**Thứ tự ưu tiên:** SFX → VFX → UI Polish → BGM

---

## Phần 1 — SFX

### Danh sách 11 file cần tạo

| ID | Sự kiện | Gợi ý jsfxr |
|---|---|---|
| `sfx_score` | Ăn điểm thành công | "Pickup/Coin" — pitch tăng theo combo |
| `sfx_wrong` | Tổng sai / wrong shape | "Hit/Hurt" tone thấp |
| `sfx_combo` | Combo tăng | "Powerup" ngắn |
| `sfx_powerup_use` | Dùng Hint/Shuffle/Remove | "Laser/Shoot" biến thể |
| `sfx_powerup_gain` | Zen refill power-up | "Sparkle" |
| `sfx_shuffle` | Board shuffle | "Whoosh" |
| `sfx_tile_remove` | Remove 1 tile | "Pop/delete" |
| `sfx_virus_explode` | Virus nổ | "Explosion" nhỏ |
| `sfx_gameover` | Game over | "Random" → chỉnh tay |
| `sfx_achievement` | Achievement unlock | "Ding/chime" |
| `sfx_level_up` | Gravity level up / Challenge unlock | "Fanfare" ngắn |

**Nguồn:** https://sfxr.me/ → export .wav → convert .ogg
**Thư mục:** `res://audio/sfx/`

### audio_manager.gd (autoload mới)

**File:** `res://scripts/audio_manager.gd`
- Pool 8 `AudioStreamPlayer` (tránh SFX bị cắt khi rapid-fire combo)
- `play_sfx(id: String, pitch: float = 1.0)`
- `play_bgm(stream, fade_in)` + `stop_bgm(fade_out)`
- Đăng ký autoload trong `project.godot`: `AudioManager = res://scripts/audio_manager.gd`

### Hook call points

| SFX | File | Vị trí | Code thêm |
|---|---|---|---|
| `score` | main.gd | ~line 390, sau `show_floating_score` | `AudioManager.play_sfx("score", 1.0 + combo_count * 0.05)` |
| `wrong` | main.gd | ~line 475, else branch evaluate_selection | `AudioManager.play_sfx("wrong")` |
| `combo` | main.gd | ~line 396, sau `combo_count += 1` | `AudioManager.play_sfx("combo")` |
| `powerup_use` | main.gd | line 986, 1006, 1039 (3 btn handlers) | Đầu mỗi handler |
| `powerup_gain` | main.gd | ~line 487, `_check_zen_milestone` | Sau `show_floating_text_center` |
| `shuffle` | main.gd | ~line 1006, `_on_btn_shuffle_pressed` | Đầu function |
| `virus_explode` | main.gd | `kill_tile_from_virus` | Grep để tìm line chính xác |
| `gameover` | main.gd | ~line 528, `trigger_end_game` | Đầu function |
| `level_up` | main.gd | ~line 595, `_show_gravity_level_flash` | Đầu function |
| `achievement` | achievement_popup.gd | line 33, `_show_next` | Trước tween slide-in |

---

## Phần 2 — VFX

### 2.1 Tile clear burst (ưu tiên cao nhất)

- **File mới:** `res://scenes/tile_burst.tscn` — `CPUParticles2D` (nhẹ hơn GPU cho Android)
- One-shot, lifetime 0.4s, 8-12 particles, scatter radius 20px, fade + scale down
- Màu theo tile type: WHITE (normal), RED (negative), BLUE (virus), GOLD (joker)
- **Hook:** `main.gd` — trong `for pos in selected_tiles` trước `queue_free()`:
  ```gdscript
  var burst = preload("res://scenes/tile_burst.tscn").instantiate()
  burst.position = tiles[pos].position
  burst.modulate = _get_burst_color(tiles[pos].tile_type)
  add_child(burst)
  ```

### 2.2 Combo pop

- `ComboLabel` scale bounce khi combo tăng
- **Hook:** `update_combo_ui()` trong main.gd
  ```gdscript
  var tween = create_tween()
  tween.tween_property(combo_label, "scale", Vector2(1.4, 1.4), 0.1)
  tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
  ```

### 2.3 Score float cải thiện

- Màu vàng khi combo ≥ x3
- Font size: `24 + combo_count * 4` (capped)

### 2.4 Wrong selection shake

- SelectionBox rung khi sai (thêm vào else branch evaluate_selection)
  ```gdscript
  var ox = selection_box.position.x
  var tween = create_tween()
  tween.tween_property(selection_box, "position:x", ox + 8, 0.05)
  tween.tween_property(selection_box, "position:x", ox - 8, 0.05)
  tween.tween_property(selection_box, "position:x", ox, 0.05)
  ```

---

## Phần 3 — UI Polish

### 3.1 Button sizes

- Mọi interactive button ≥ **48×48 px** (Android minimum)
- Power-up buttons ≥ **64×64 px**
- Cần audit: Hint/Shuffle/Remove buttons + Pause button trong `main.tscn`

### 3.2 Font

- Dùng **Nunito** (Google Fonts) — rounded, dễ đọc trên mobile
- Download: https://fonts.google.com/specimen/Nunito
- Import vào `res://assets/fonts/`
- Tạo Theme resource: `res://assets/ui/main_theme.tres`
- Áp dụng cho `main.tscn` HUD + `main_menu.tscn` trước, các màn phụ sau

### 3.3 Power-up button feedback

- Khi count về 0: scale nhỏ lại 0.1s
- Khi refill: scale to lên 0.1s
- Hook: `update_power_up_ui()` trong main.gd

---

## Phần 4 — BGM (làm cuối)

- 1 track ambient loop cho toàn game
- **Nguồn:** https://pixabay.com/music/ — search "puzzle ambient loop" (filter CC0)
- **Thư mục:** `res://audio/bgm/`
- Play khi enter `main.tscn`, loop liên tục
- Fade out 1s khi `trigger_end_game()`

---

## Lịch triển khai (ước tính ~13h)

| Ngày | Việc | Giờ |
|---|---|---|
| 1 | Generate 11 SFX (jsfxr), convert .ogg | 1.5h |
| 1 | Viết audio_manager.gd, add autoload | 1h |
| 2 | Hook SFX vào main.gd + achievement_popup.gd | 2h |
| 3 | Tạo tile_burst.tscn, hook vào evaluate_selection | 1.5h |
| 3 | Combo pop + wrong shake + float score cải thiện | 1h |
| 4 | Import Nunito, tạo Theme resource, áp main + menu | 2h |
| 4 | Audit + fix button sizes | 1h |
| 5 | Import BGM, hook play/stop | 1h |
| 5 | Test tổng thể, fix bugs nhỏ | 1h |
| buffer | Chỉnh balance âm lượng, tinh chỉnh | 1h |

---

## Checklist kết thúc T7

- [ ] 11 SFX phát đúng, không bị cắt nhau khi rapid-fire
- [ ] `DEBUG_MODE = false` trong `main.gd` trước APK build
- [ ] Particle burst không lag trên thiết bị thật
- [ ] BGM loop liền mạch (không có pop/click ở điểm nối)
- [ ] Button sizes ≥ 48px kiểm tra trên màn hình thật
- [ ] Font Nunito nhất quán ở main_menu + main HUD
