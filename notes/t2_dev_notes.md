# T2 Dev Notes — End Game Logic + Gravity Levels

## Board Size: 6×8 → 8×12

**Vấn đề:** Board 6×8 quá ít ô → số valid rectangles ít (~750), Classic 120s không đủ nước đi.

**Giải pháp:** Tăng lên 8×12 = 96 ô (~2808 rectangle combinations). Tile size tự tính động theo screen để fit mọi thiết bị.

**Khó khăn:** Với tile_size cố định 105px, board 8×12 tràn ra ngoài màn hình nhỏ hơn 1080px. Phải thêm dynamic tile_size calculation trong `_ready()`.

---

## Số Distribution: Uniform → Weighted

**Vấn đề:** Uniform 1-9 tạo ra quá nhiều số lớn (7,8,9), khó ghép tổng 10, gây "dead board" nhanh.

**Phân tích:** Số 1-5 tham gia vào nhiều combo hơn số 6-9 (vì có thể kết hợp linh hoạt hơn).

**Giải pháp:** Weighted distribution — 1-5 có tổng 71%, 6-9 chỉ 29%.
```
1:15% 2:15% 3:15% 4:13% 5:13% | 6:10% 7:8% 8:6% 9:5%
```

---

## Guaranteed Solvable Board (Classic)

**Vấn đề:** Ngay cả với weighted distribution, vẫn có thể sinh ra board không có valid move nào.

**Giải pháp:** Sau khi spawn, chạy `scan_board_for_valid_moves()`. Nếu không có → clear và thử lại (tối đa 5 lần). Với 8×12 và weighted numbers, thực tế hiếm khi cần quá 2 lần thử.

**Trade-off:** Không dùng cho Zen/Mutation/Gravity vì các mode này có refill hoặc mechanics khác xử lý dead board.

---

## scan_board_for_valid_moves() — Performance

**Vấn đề:** Phải duyệt O(n⁴) rectangles. Với 8×12: ~2808 combinations × ~96 cells = ~270k ops.

**Giải pháp:**
1. Tái sử dụng `find_hint_path()` vốn đã có early-exit (trả về ngay khi tìm được 1 valid move).
2. Chỉ gọi sau mỗi action (không gọi trong `_process()`).
3. Scan từ actual tile bounds chứ không phải toàn bộ grid → giảm đáng kể khi board thưa.

**Kết quả:** ~1-3ms per check trên mobile, chấp nhận được cho after-action trigger.

---

## End Game Condition

**Quy tắc:** Hết nước đi **VÀ** hết power-ups (hint=0, shuffle=0, remove=0).

**Trường hợp đặc biệt:**
- Classic: thêm time's up
- Gravity: thêm time's up + lives=0 (shuffle=0 khi còn mạng = game over ngay)
- Zen: không áp dụng end game condition

**Thứ tự trigger check:** Sau evaluate_selection → sau mỗi power-up bị dùng → sau refill.

---

## Gravity Level System (L1-L4)

### L1 — DOWN
Existing logic: scan column bottom-up, tiles fall down. Giữ nguyên.

### L2 — RIGHT
Scan row từ phải sang trái. Tile rơi sang phải (fill right). Empty spaces tích lũy ở bên trái.

### L3 — LEFT
Scan row từ trái sang phải. Tile rơi sang trái. Empty spaces ở bên phải.

### L4 — RADIAL (tâm→rìa)
Khó khăn: Cần logic hoàn toàn khác, không phải chỉ đổi axis.

Giải pháp: Chia đôi board theo trục dọc.
- Nửa trái (x < 4): apply L3 (fall left)
- Nửa phải (x >= 4): apply L2 (fall right)

Kết quả: Tiles "nổ ra" từ center ra 2 mép. Visual effect rõ ràng, implementation đơn giản.

**Trade-off:** L4 chỉ có horizontal radial, không có vertical. Full radial (top/bottom tách) phức tạp hơn nhiều, để T5 nếu cần.

---

## Power-up System Redesign

**Trước:** boolean (available: true/false)
**Sau:** int (count: 0+), stackable

**Lý do stackable trong Zen:** Zen milestone refill (mỗi 100 điểm) cộng dồn → reward player chơi lâu.

**Gravity — Lives System:**
- shuffle_count = 3 (thay vì 1)
- Mỗi lần dùng shuffle: tiêu 1 mạng
- shuffle_count = 0 sau khi dùng → trigger_end_game("NO_LIVES") ngay

**Remove Cancel:** Player có thể hủy bỏ chế độ "ngắm bắn" bằng cách bấm Remove lần nữa. Tránh tình huống bấm nhầm mà phải xóa ô không muốn.

---

## Vấn đề chưa giải quyết / Để tuần sau hỏi supervisor

- **Gravity timer duration:** Hiện dùng 120s như Classic. Có thể cần tăng (180s?) vì board to hơn + 4 levels.
- **Gravity timer pause:** Hiện always-running như Classic. Nên dừng khi pause không?
- **L4 vertical component:** Nửa trên board nên fall UP, nửa dưới fall DOWN không? Phức tạp hơn, defer sang T5.
- **Level transition UI:** Hiện chỉ có floating text "LEVEL X!". T3 cần animation đẹp hơn.
- **Refill trigger cho Gravity:** Chưa có. Board Gravity dần cạn → end game. Supervisor cần confirm.
