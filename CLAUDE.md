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
| `main.tscn` / `main.gd` | Logic cốt lõi: sinh bàn cờ, xử lý input kéo vùng, tính tổng điểm |
| `main_menu.tscn` / `main_menu.gd` | Màn hình chính, điều hướng, chọn chế độ |
| `tile.tscn` / `tile.gd` | Đối tượng ô số đơn lẻ, hiệu ứng hình ảnh |
| `global.gd` | Autoload Singleton, lưu trạng thái toàn cục, chuyển dữ liệu giữa scene |
| `PauseLayer` | Pause game, dừng timer, điều hướng về menu |

## Game Modes

- **Classic** — có Time's up
- **Zen** — không giới hạn thời gian
- **Gravity** — ô rơi theo trọng lực, có 4 levels
- **Mutation** — có ô đặc biệt

## Power-ups

- **Hint** — gợi ý vùng chữ nhật
- **Shuffle** — xáo lại bàn cờ
- **Remove** — xóa ô

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

## 🏆 Hệ thống điểm (mới)

### Classic Mode
- **Giữ nguyên:** 1 ô = 1 điểm (đơn giản, classic).

### Mutation Mode (A + B kết hợp)

**A. Combo Multiplier**
- Ăn liên tiếp trong **3 giây** → x2, x3, x4...
- Reset combo khi ngừng > 3 giây hoặc kéo sai
- UI: hiển thị combo counter ở góc màn hình, tăng size + glow khi combo cao

**B. Bonus theo loại ô** (cộng vào điểm gốc của vùng)
| Loại ô | Bonus |
|--------|-------|
| Ô thường | 1 điểm/ô |
| Ô Joker | +5 bonus (vì khó dùng đúng) |
| Ô Đột Biến (số âm) | +3 bonus (dụng não) |
| Ô Ẩn Số | +2 bonus (mạo hiểm) |
| Ô Virus (dọn được trước khi nổ) | +10 bonus |

**Công thức:**
```
score = (base_tiles + sum_bonuses) * combo_multiplier
```

### Gravity Mode
- Vẫn 1 điểm/ô để giữ điều kiện qua level (~20 điểm) đơn giản.
- Có thể thử combo nhẹ nếu test thấy chán.

### Zen Mode
- 1 điểm/ô, không có áp lực. Chế độ "thư giãn".

---

## ☠️ End Game Logic (mới)

**Trigger:** Hết nước đi (không còn vùng chữ nhật nào tổng = 10) **VÀ** hết powerup.

**Áp dụng cho:**
- ✅ Classic
- ✅ Mutation
- ⚠️ Gravity (đang thử nghiệm — có thể bỏ nếu xung đột với cơ chế "3 mạng")
- ❌ Zen (không áp dụng — đây là mode thư giãn)

**Implementation note:**
- Cần hàm `scan_board_for_valid_moves()` — duyệt toàn bộ subrectangle, check tổng = 10
- Trigger check sau mỗi: lần ăn điểm, dùng powerup, refill (Gravity)
- Tránh check mỗi frame — tốn performance trên mobile
- Khi trigger → hiện popup "No moves left" → option Restart hoặc Quit về menu (kèm tổng kết)

---

## Tiến độ

### ✅ Đã hoàn thành
- Use Case + kiến trúc hệ thống
- Cơ chế gameplay cốt lõi (Rectangle Selection)
- 4 chế độ chơi
- 3 power-ups: Hint, Shuffle, Remove
- 4 ô đặc biệt trong Mutation
- Hệ thống chuyển cảnh

---

## 🔧 Bug cần sửa (ưu tiên)

1. **Kích cỡ ô trong màn chơi quá bé** → tăng kích thước
2. **Timer trong mode không có Time's up vẫn chạy khi pause** → phải dừng timer khi pause
3. **Mutation mode — ô Joker vẫn hiện điểm khi kéo box select** → Joker phải = 0 trong tính toán hiển thị
4. **Mutation mode — refill chưa sinh ô đặc biệt trong refill** → kiểm tra logic refill
5. **Main menu — nút Quit/Leave** → phải thoát ra ngoài main menu

---

## 🚧 Feature đang triển khai

### Hệ thống điểm mới (Mutation)
- Implement combo multiplier
- Implement bonus theo loại ô
- UI hiển thị combo counter

### End Game logic
- Hàm scan board tìm valid moves
- Popup end game + tổng kết

### Main Menu
- Tên game, nút **Play**, **Highscore** (icon cúp), **Help/Tutorial**, **Quit**

### Zen Mode
- Menu phụ: **Continue**, **Restart**, **New Save**
- Continue hiển thị thêm thời gian + tổng điểm
- Spawn ô đặc biệt sau mốc điểm (vd: 100)

### Gravity Mode (tham khảo Pikachu)
- **Levels:** L1 (xuống), L2 (trái→phải), L3 (phải→trái), L4 (tâm→rìa)
- **Điều kiện qua level:** ~20 điểm
- **3 mạng** = 3 lần shuffle (thay cho power-up Shuffle). Hết mạng = end game.
- Bỏ Time's up

### Pause Menu
- **Mode có Time's up:** Resume, Restart, Quit
- **Mode không có Time's up:** thêm Save và Leave (chưa save → hỏi xác nhận)

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
| **T1** | Bug fix + Hệ thống điểm mới | Sửa 5 bug, code combo + bonus tiles |
| **T2** | End game logic + Gravity levels | Scan board, popup end game, 3-4 level Gravity |
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
