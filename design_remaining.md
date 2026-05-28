# TraceTen — Design Remaining (handoff to Claude Design)

## Đã xong (in-game HUD)
- Tile redesign (Normal / Virus / Mystery / Joker / Negative) ✅
- Top bar: Score lớn + Pause button ✅
- Sub-info bar: Timer, GravityLevel, Lives, ChallengeConstraint ✅
- Power-up bar: 3 nút circular (?, ↺, ✕) ✅
- Selection box: border đổi màu theo sum, sum bubble ✅
- Score tick-up animation ✅
- Tile burst + scale-down animation ✅
- Combo badge (ring đếm ngược) ✅
- Floating "+points" ✅

---

## Còn cần thiết kế

### 1. Game Over Overlay (`GameOverLayer`)
**Hiện tại:** ColorRect đen 85% opacity + VBoxContainer giữa màn hình, text thô.

**Cần:**
- Card trắng/cream bo góc nổi lên trên nền mờ
- Title rõ ràng (TIME'S UP / NO MOVES / NO LIVES / LEFT)
- Score lớn nổi bật
- Dòng phụ: Time played, Best combo
- 2 nút: Restart + Quit — style nhất quán với power-up bar

---

### 2. Pause Menu (`PauseMenuLayer`)
**Hiện tại:** Nền đen 94% opacity + VBoxContainer nút dọc.

**Cần:**
- Nền mờ blur-like (dùng ColorRect semi-transparent là đủ)
- Card trắng/cream chứa nút
- Nút: Continue / Restart / Change Level (Challenge) / Leave
- Style nút nhất quán với thiết kế tổng thể

---

### 3. Main Menu (`main_menu.tscn`)
**Hiện tại:** Chưa được thiết kế, placeholder text.

**Cần:**
- Background màu APP_BG / PHONE_BG
- Logo "TraceTen" — typography nổi bật
- 4 nút: Play / Highscore / Achievements / Help
- Có thể thêm animated tile decoration nhỏ (optional)

---

### 4. Mode Select (`mode_select.tscn`)
**Hiện tại:** 4 card chế độ chơi, chưa được polish.

**Cần:**
- Card cho mỗi mode: icon + tên + description ngắn
- Màu accent khác nhau mỗi mode (hoặc cùng palette)
- Nút Play rõ ràng trên mỗi card

---

### 5. Highscore Screen (`highscore.tscn`)
**Hiện tại:** Stub, chỉ có nút Back.

**Cần:**
- Tab bar 5 mode (swipe ngang)
- Mỗi tab: top 3 entry với rank, score, time, max combo
- Empty state khi chưa có score

---

### 6. Achievement Screen (`achievement_screen.tscn`)
**Hiện tại:** Danh sách 25 thành tựu, chưa được polish visual.

**Cần:**
- Header category rõ ràng (6 category)
- Row mỗi achievement: icon ★/○ + tên + desc + progress bar (nếu target > 1)
- Locked: dim 60%, Unlocked: highlight

---

### 7. Achievement Popup (`achievement_popup.tscn`)
**Hiện tại:** Slide-in từ phải, chưa được styled.

**Cần:**
- Card nhỏ bo góc, nền trắng/cream
- Icon ★ + tên achievement
- Slide-in 0.3s → đứng 2.5s → fade out

---

### 8. Tutorial Screen (`tutorial.tscn`)
**Hiện tại:** 5 màn animated demo, chưa được polish.

**Cần:**
- Consistent với overall palette
- Nút Next / Back rõ ràng
- Demo area có border/card rõ ràng

---

### 9. Gravity Mode — Lives Display
**Hiện tại:** `LivesLabel` trong sub-info bar hiện text `♥♥♥` / `♥♥♡` / `♥♡♡` màu đỏ đơn giản. Trông chưa đẹp và thiếu tính visual.

**Bối cảnh:** Gravity có đúng 3 mạng (tương đương 3 lần dùng Shuffle). Mất mạng khi dùng hết nước đi hoặc bấm Shuffle. Mất mạng cuối → Game Over.

**Cần thiết kế:**
- 3 icon tim (filled/empty) trực quan hơn — có thể dùng hình tim thật, hoặc pill badge, hoặc icon tròn có viền
- Màu: tim đầy = đỏ/hồng ấm, tim trống = xám nhạt
- Fit vào sub-info bar (y=128..192, cao 64px) — cạnh phải màn hình, không đè lên timer
- Khi mất tim: animation nhỏ (rung / fade out tim đó)
- Có thể tham khảo style "lives" của các mobile game (vd: 3 chấm tròn, 3 viên đá quý, 3 tim cách đều nhau)
- **Tự do thiết kế** nếu ý tưởng mới phù hợp palette Mint Cream hơn là dùng emoji ♥

---

### 10. Zen & Challenge — Level Themes (12 biome)
**Hiện tại:** Không có visual theme theo level — bảng và UI trông giống hệt nhau ở mọi level.

**Bối cảnh:**
- 12 level với 12 biome: Meadow → Forest → Riverside → Ocean Shore → Deep Sea → Coral Reef → Desert → Canyon → Mountain → Snow Peak → Aurora → Cosmos
- Mỗi level có constraint hình dạng riêng (hiện hiển thị text trong sub-info bar)
- Level unlock theo điểm tích lũy (0 / 50 / 150 / 300 / 500 / 750 / 1000 / 1300 / 1700 / 2200 / 2800 / 3500)

**Cần thiết kế — 2 lựa chọn (chọn 1 hoặc kết hợp):**

**Lựa chọn A — Palette shift theo biome (nhẹ nhàng, dễ implement):**
Mỗi nhóm biome đổi màu accent (MINT → màu khác) và board background nhẹ:
- L1-L2 Meadow/Forest: palette xanh lá hiện tại (giữ nguyên)
- L3-L4 Riverside/Ocean Shore: palette xanh dương nhạt
- L5-L6 Deep Sea/Coral Reef: palette teal/aqua
- L7-L8 Desert/Canyon: palette cam đất / nâu ấm
- L9-L10 Mountain/Snow Peak: palette xám lạnh / xanh băng
- L11-L12 Aurora/Cosmos: palette tím / indigo

**Lựa chọn B — Level icon + tên hiển thị đẹp trong sub-info bar:**
- Icon biome nhỏ (emoji hoặc pixel art 24×24) cạnh tên level
- Tên level + constraint text được style rõ ràng hơn
- Level transition: fade + welcome text "Welcome to [Biome]"

**Constraint icon (Challenge mode):**
Hiện tại `ChallengeConstraintLabel` chỉ là text. Có thể thiết kế icon nhỏ (24×24) thể hiện shape constraint:
- ▭ = tile_count ≥ N
- □ = must be square
- ▦ = bbox area ≥ N
Đặt cạnh text constraint, dễ đọc hơn khi chơi.

**Gợi ý:** Nếu Lựa chọn A + B cùng quá phức tạp, ưu tiên **B trước** (level name + icon đẹp trong sub-info bar) vì visible hơn khi chơi. Palette shift (A) có thể làm sau nếu còn thời gian.

---

## Palette tham khảo (đã implement)

```
APP_BG      #F5EEEA   (nền toàn màn)
PHONE_BG    #EBE3D2   (top bar, bottom bar)
BOARD_BG    #EFE7D5   (nền board)
BOARD_INSET #E3D8C0   (border board)
TEXT        #2F3A36   (text chính)
SUB_TEXT    #8A958F   (text phụ)
MINT        #7FC8A9   (accent chính, selected)
MINT_DARK   #4EA584   (accent đậm)
MINT_SOFT   #CDE9DA   (accent nhạt)
TILE_WHITE  #FFFFFF   (nền tile normal)
```

## Font
- **Inter Variable** — UI text, label
- **JetBrains Mono Variable** — số, score, timer

## Độ ưu tiên
1. Game Over + Pause Menu (xuất hiện nhiều nhất khi chơi)
2. Gravity Lives Display (gameplay-critical, trông chưa ổn)
3. Main Menu + Mode Select (first impression)
4. Zen/Challenge Level Themes — B trước (sub-info bar icon + name), A sau (palette shift)
5. Highscore + Achievement (secondary screens)
6. Tutorial + Popup (polish cuối)
