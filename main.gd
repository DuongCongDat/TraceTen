extends Node2D

var tile_scene = preload("res://tile.tscn")
#var grid_size = 5
var grid_cols = 6
var grid_rows= 8
var tile_size = 105 #105
#var start_pos = Vector2(85, 300)
var start_pos = Vector2.ZERO

var tiles = {}

#GAMEMODE CLASSIC, GRAVITY, MUTATION, ZEN
var gameplay_mode = ""
var game_start_time = 0.0
var total_duration = 120.0 # 120 giây cố định cho 3 mode classic, gravity & mutation
var is_game_over = false
var is_paused = false # Trạng thái pause riêng

# --- BIẾN POWER-UPS ---
var hint_available = true
var shuffle_available = true
var remove_available = true
var is_remove_mode = false # Biến này để bật chế độ "ngắm bắn" xóa ô

var score = 0

# ==========================================
# Change GAME MODE
# Đổi thành "TRACE" nếu muốn kẻ viền đỏ
# Đổi thành "RECTANGLE" nếu muốn kéo khung
var current_mode = "RECTANGLE" 
# ==========================================

# --- HỆ THỐNG UNLOCK VÀ TUTORIAL ---
var unlocked_modes = ["CLASSIC"] # Mặc định chỉ mở Classic
var seen_tutorials = {
	"CLASSIC": false,
	"GRAVITY": false,
	"ZEN": false,
	"MUTATION": false
}

var tutorial_texts = {
	"CLASSIC": [
		"Chào mừng đến với TraceTen!\n\nCách chơi: Kéo chọn một vùng hình chữ nhật sao cho tổng các ô bằng đúng 10 để ghi điểm.",
		"Bạn có 120 giây!\nThanh thời gian ở trên cùng sẽ cạn dần. Hãy nhanh tay lên!",
		"Quyền trợ giúp:\nNếu bế tắc, hãy dùng Hint (Gợi ý), Shuffle (Xáo trộn) hoặc Remove (Xóa 1 ô) ở bên dưới nhé."
	],
	"GRAVITY": [
		"Chế độ Trọng Lực (Gravity)!\n\nKhi bạn ăn điểm, các ô phía trên sẽ rơi xuống lấp chỗ trống.",
		"Sẽ KHÔNG có ô mới sinh ra bù vào. Hãy tính toán cẩn thận để dọn sạch bàn cờ!"
	],
	"MUTATION": [
		"Chế độ Đột Biến (Mutation)!\n\nSự hỗn loạn bắt đầu. Ô màu đỏ là số âm, bắt buộc bạn phải làm toán trừ.",
		"Ô Dấu Hỏi (?): Chỉ lộ diện khi bị chạm vào.\nÔ Ngôi Sao (Joker): Ép tổng thành 10 (giới hạn sức mạnh từ -9 đến 9).",
		"Virus (Màu xanh): Mỗi 5 giây tự đổi số. Nếu biến thành số 0, nó tự hủy và để lại lỗ hổng vĩnh viễn!"
	],
	"ZEN": [
		"Chế độ Thiền (Zen)!\n\nKhông có áp lực thời gian. Cứ chơi thư giãn, khi bàn cờ cạn 75% sẽ tự động được bơm thêm ô mới."
	]
}

var current_tutorial_step = 0
var is_tutorial_active = false

@onready var selection_box = $SelectionBox
@onready var trace_line = $DrawLine
@onready var pause_menu = $PauseMenuLayer
@onready var time_bar = $TimeBar
@onready var score_label = $ScoreLabel

var is_dragging = false

# Biến cho Mode Kéo Khung
var drag_start_grid = Vector2.ZERO
var selected_tiles = []

# Biến cho Mode Kẻ Viền
var vertex_path = []

func _ready():
	gameplay_mode = Global.selected_mode
	print("Đang khởi tạo chế độ chơi: ", gameplay_mode)
	# Ẩn các công cụ đồ họa lúc mới vào
	if selection_box: selection_box.visible = false
	if trace_line: trace_line.clear_points()
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	
	var total_width = grid_cols * tile_size
	var total_height = grid_rows * tile_size
	
	var start_x = (screen_width - total_width) / 2.0 + (tile_size / 2.0)
	var start_y = (screen_height - total_height) / 2.0 + (tile_size / 2.0)
	start_pos = Vector2(start_x,start_y)
	
	score = 0
	update_score_ui()
	
	spawn_grid()
	$TutorialLayer.hide() # Giấu đi mặc định
	#check_and_start_tutorial()
	start_time_attack_game()
	
func spawn_grid():
	for x in range(grid_cols):
		for y in range(grid_rows):
			spawn_single_tile(x, y)
			
# --- HÀM TẠO 1 Ô ĐỘC LẬP (MÁY GACHA) ---
func spawn_single_tile(x, y):
	var spawn_pos = Vector2(x, y)
	var type = "NORMAL"
	var val = randi_range(1, 9)
	
	# CHỈ KÍCH HOẠT ĐỘT BIẾN NẾU ĐANG Ở MODE MUTATION
	if gameplay_mode == "MUTATION":
		var p = randf() # Quay 1 số ngẫu nhiên từ 0.0 đến 1.0 (tương đương 0% đến 100%)
		
		if p <= 0.70:
			# 70% tỷ lệ ra số dương bình thường
			val = randi_range(1, 9) 
		elif p <= 0.95:
			# 25% tỷ lệ ra số âm nhỏ (từ -5 đến -1)
			val = randi_range(-5, -1)
			type = "NEGATIVE"
		else:
			# 5% tỷ lệ ra số âm lớn (từ -9 đến -6)
			val = randi_range(-9, -6)
			type = "NEGATIVE"
		
		# Tung xúc xắc cho các đặc tính ẩn
		var roll = randf()
		if roll < 0.15: type = "MYSTERY"      # 15% thành Dấu ?
		elif roll < 0.20: type = "JOKER"      # 5% thành Ngôi sao cứu mạng
		elif roll < 0.30: type = "VIRUS"      # 10% thành Virus
	
	var new_tile = tile_scene.instantiate()
	new_tile.position = start_pos + Vector2(x * tile_size, y * tile_size)
	add_child(new_tile)
	
	new_tile.set_data(spawn_pos, val, type)
	tiles[spawn_pos] = new_tile
	
	return new_tile

# --- BỘ CHIA TÍN HIỆU ĐIỀU KHIỂN ---
func _input(event):
	if is_game_over or is_paused: 
		return
	
	if current_mode == "RECTANGLE":
		handle_rectangle_input(event)
	elif current_mode == "TRACE":
		handle_trace_input(event)

# ==========================================
# PHẦN 1: LOGIC KÉO KHUNG (RECTANGLE MODE)
# ==========================================
func handle_rectangle_input(event):
	if is_tutorial_active: return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			var touch_grid = pixel_to_grid(event.position)
			
			# --- NẾU ĐANG Ở CHẾ ĐỘ REMOVE TILE ---
			if is_remove_mode:
				if is_within_grid(touch_grid) and tiles.has(touch_grid):
					# Xóa ô vừa chạm
					tiles[touch_grid].queue_free()
					tiles.erase(touch_grid)
					
					# Tắt chế độ remove và khóa nút
					is_remove_mode = false
					remove_available = false
					$PowerUpContainer/BtnRemove.disabled = true
					
					# Gọi hiệu ứng rớt (nếu đang chơi Gravity)
					if gameplay_mode == "GRAVITY":
						apply_gravity()
						
				return # Dừng hàm tại đây, không cho kéo chọn nữa
			# ------------------------------------
			
			# CHỈ BẮT ĐẦU KÉO NẾU CHẠM VÀO TRONG LƯỚI
			if is_within_grid(touch_grid):
				is_dragging = true
				drag_start_grid = touch_grid
				selection_box.visible = true
				update_selection(event.position)
		else:
			is_dragging = false
			selection_box.visible = false
			evaluate_selection()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			update_selection(event.position)

func pixel_to_grid(pixel_pos: Vector2) -> Vector2:
	var top_left_corner = start_pos - Vector2(tile_size/2.0, tile_size/2.0)
	var grid_x = floor((pixel_pos.x - top_left_corner.x) / tile_size)
	var grid_y = floor((pixel_pos.y - top_left_corner.y) / tile_size)
	return Vector2(grid_x, grid_y)

func update_selection(touch_pos: Vector2):
	var current_grid = pixel_to_grid(touch_pos)
	var min_x = min(drag_start_grid.x, current_grid.x)
	var max_x = max(drag_start_grid.x, current_grid.x)
	var min_y = min(drag_start_grid.y, current_grid.y)
	var max_y = max(drag_start_grid.y, current_grid.y)
	
	var top_left_pixel = start_pos + Vector2(min_x * tile_size, min_y * tile_size) - Vector2(tile_size/2.0, tile_size/2.0)
	selection_box.position = top_left_pixel
	selection_box.size = Vector2((max_x - min_x + 1) * tile_size, (max_y - min_y + 1) * tile_size)
	
	for pos in selected_tiles:
		if tiles.has(pos): tiles[pos].deselect()
	selected_tiles.clear()
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2(x, y)
			if tiles.has(pos):
				selected_tiles.append(pos)
				tiles[pos].select()
				
	#Calculate SUM real time			
	var current_sum = 0
	for pos in selected_tiles:
		current_sum += tiles[pos].value
		
	var sum_label = selection_box.get_node("SumLabel")
	sum_label.text = str(current_sum)
	sum_label.position.x = (selection_box.size.x - sum_label.size.x) / 2.0
	sum_label.position.y = -60 # Đẩy số lên trên cách khung 60 pixel
	
	# Đổi màu linh hoạt (Juice)
	if current_sum == 10:
		sum_label.add_theme_color_override("font_color", Color.GREEN) # Chuẩn 10 -> Xanh lá báo hiệu buông tay
	elif current_sum > 10:
		sum_label.add_theme_color_override("font_color", Color.RED) # Lố 10 -> Đỏ cảnh báo
	else:
		sum_label.add_theme_color_override("font_color", Color.WHITE) # Đang tính -> Trắng

# --- LOGIC TÍNH TỔNG & BỐC HƠI ---
func evaluate_selection():
	if selected_tiles.size() == 0: return
	
	var total_sum = 0
	var has_joker = false
	var sum_others = 0 # Biến mới: Tính tổng các ô KHÔNG PHẢI Joker
	
	# Tính tổng và dò tìm Joker
	for pos in selected_tiles: 
		var t = tiles[pos]
		if t.tile_type == "JOKER":
			has_joker = true
		else:
			sum_others += t.value
			total_sum += t.value
	# Bùa hộ mệnh: Có Joker và kéo lọt vào khung ít nhất 2 ô -> Ép tổng = 10!
	if has_joker and selected_tiles.size() > 1:
		var needed_value = 10 - sum_others # Xem còn thiếu bao nhiêu để tròn 10
		
		# Joker chỉ có thể biến hình thành 1 số từ -9 đến 9
		if needed_value >= -9 and needed_value <= 9:
			total_sum = 10 # Joker bù thành công!
			print("Joker đã biến hình thành số: ", needed_value)
		else:
			print("Joker quá tải! Cần số ", needed_value, " nhưng quá sức.")
			total_sum = 999 # Cố tình gán 999 để phá hỏng tổng, từ chối nước đi này
			var last_pos = selected_tiles[-1] 
			show_floating_text_center("OVERLOAD")
		
	if total_sum == 10:
		# --- BƯỚC 1: TÍNH ĐIỂM ---
		var points_earned = selected_tiles.size() * 1 # Mỗi ô 1 điểm
		score += points_earned
		score_label.text = "Score: " + str(score)
		print("Cộng " + str(points_earned) + " điểm!")
		
		# --- BƯỚC 2: XÓA CÁC Ô VỪA CHỌN ---
		for pos in selected_tiles:
			if tiles.has(pos):
				tiles[pos].queue_free()
				tiles.erase(pos)
				
		# --- BƯỚC 3: XỬ LÝ BÀN CỜ SAU KHI ĂN ĐIỂM THEO MODE ---
		if gameplay_mode == "GRAVITY":
			# Trọng lực: Chỉ rơi ô cũ xuống, để lại khoảng trống ở trên
			apply_gravity() 
			
		elif gameplay_mode in ["ZEN", "MUTATION"]:
			# Zen Mode: Bơm thêm ô nếu bàn cờ bị ăn mất 70%
			var total_slots = grid_rows * grid_cols 
			var remaining_tiles = tiles.size()
			var cleared_percent = 1.0 - (float(remaining_tiles) / float(total_slots))
			
			if cleared_percent >= 0.70:
				print("Đã dọn sạch ", round(cleared_percent * 100), "%! Gọi wave mới...")
				refill_empty_slots()
				
	else:
		# --- XỬ LÝ KHI KÉO SAI (TỔNG KHÁC 10) ---
		await get_tree().create_timer(0.3).timeout
		for pos in selected_tiles:
			if tiles.has(pos): 
				tiles[pos].deselect()
			
	# Cuối cùng, luôn dọn dẹp mảng lựa chọn
	selected_tiles.clear()

# ==========================================
# PHẦN 2: LOGIC KẺ VIỀN (TRACE MODE)
# ==========================================
func handle_trace_input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_dragging = true
			vertex_path.clear()
			trace_line.clear_points()
			try_snap_to_vertex(event.position)
		else:
			is_dragging = false
			vertex_path.clear()
			trace_line.clear_points()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			try_snap_to_vertex(event.position)

func try_snap_to_vertex(touch_pos: Vector2):
	var top_left_corner = start_pos - Vector2(tile_size/2.0, tile_size/2.0)
	
	if vertex_path.is_empty():
		var vx = round((touch_pos.x - top_left_corner.x) / tile_size)
		var vy = round((touch_pos.y - top_left_corner.y) / tile_size)
		if vx >= 0 and vx <= grid_cols and vy >= 0 and vy <= grid_rows:
			var vertex_pixel = top_left_corner + Vector2(vx * tile_size, vy * tile_size)
			if touch_pos.distance_to(vertex_pixel) < 40:
				add_vertex_to_line(Vector2(vx, vy), vertex_pixel)
		return

	var last_coord = vertex_path.back()
	var last_pixel = top_left_corner + Vector2(last_coord.x * tile_size, last_coord.y * tile_size)
	var drag_vector = touch_pos - last_pixel
	var swipe_threshold = tile_size * 0.77 # Ngưỡng nhạy 
	
	if drag_vector.length() > swipe_threshold:
		var next_coord = last_coord
		if abs(drag_vector.x) > abs(drag_vector.y):
			next_coord.x += sign(drag_vector.x)
		else:
			next_coord.y += sign(drag_vector.y)
			
		if next_coord.x < 0 or next_coord.x > grid_cols or next_coord.y < 0 or next_coord.y > grid_rows:
			return
			
		if vertex_path.size() > 1 and next_coord == vertex_path[vertex_path.size() - 2]:
			vertex_path.pop_back()
			trace_line.remove_point(trace_line.get_point_count() - 1)
			return
			
		if next_coord != last_coord:
			var next_pixel = top_left_corner + Vector2(next_coord.x * tile_size, next_coord.y * tile_size)
			add_vertex_to_line(next_coord, next_pixel)
			check_closed_loop()

func add_vertex_to_line(coord: Vector2, pixel_pos: Vector2):
	vertex_path.append(coord)
	trace_line.add_point(pixel_pos)

func check_closed_loop():
	if vertex_path.size() > 3:
		var current_coord = vertex_path.back()
		for i in range(vertex_path.size() - 2):
			if vertex_path[i] == current_coord:
				var closed_loop_coords = vertex_path.slice(i, vertex_path.size())
				is_dragging = false 
				evaluate_polygon(closed_loop_coords)
				return

func evaluate_polygon(loop_coords: Array):
	var logical_polygon = PackedVector2Array(loop_coords)
	var enclosed_tiles = []
	var total_sum = 0
	
	for pos in tiles.keys():
		var tile = tiles[pos]
		var logical_center = pos + Vector2(0.5, 0.5)
		if Geometry2D.is_point_in_polygon(logical_center, logical_polygon):
			enclosed_tiles.append(pos)
			total_sum += tile.value
			tile.select() 
			
	if total_sum == 10:
		for pos in enclosed_tiles:
			tiles[pos].queue_free()
			tiles.erase(pos)
	else:
		await get_tree().create_timer(0.5).timeout
		for pos in enclosed_tiles:
			if tiles.has(pos): tiles[pos].deselect()
			
	# --- LOGIC ZEN MODE: refill ---
func refill_empty_slots():
	# Đợi 0.4 giây để người chơi kịp nhìn thấy các ô cũ vừa bốc hơi
	await get_tree().create_timer(0.4).timeout 
	
	# Quét toàn bộ lưới 5x5 (từ 0 đến 4)
	for x in range(grid_cols):
		for y in range(grid_rows):
			var check_pos = Vector2(x, y)
			
			# Nếu tọa độ này KHÔNG có trong biến tiles (nghĩa là đang bị lủng lỗ)
			if not tiles.has(check_pos):
				# Tạo một ô mới tinh
				var new_tile = tile_scene.instantiate()
				new_tile.position = start_pos + Vector2(x * tile_size, y * tile_size)
				
				# Thêm một chút hiệu ứng "nhỏ dần ra to" (Scale animation) cho sinh động
				new_tile.scale = Vector2(0.1, 0.1) # Bắt đầu từ kích thước 0
				add_child(new_tile)
				
				# Gán dữ liệu và lưu vào Dictionary
				var random_value = randi_range(1, 9)
				new_tile.set_data(check_pos, random_value)
				tiles[check_pos] = new_tile
				
				# Dùng Tween của Godot 4 để làm hiệu ứng phóng to mượt mà
				var tween = get_tree().create_tween()
				tween.tween_property(new_tile, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
	vertex_path.clear()
	trace_line.clear_points()
	
func start_time_attack_game():
	is_game_over = false
	is_paused = false
	# Lấy thời gian hệ thống tính bằng giây
	game_start_time = Time.get_unix_time_from_system()
	$PauseMenuLayer.hide() # Ẩn menu khi bắt đầu

# --- HÀM XỬ LÝ KHI HẾT 120 GIÂY ---
func on_time_up():
	is_game_over = true
	$TimeLabel.text = "00:00"
	print("Hết 120 giây! Trò chơi kết thúc.")

	# Hiện màn hình kết thúc
	$GameOverLayer/VBoxContainer/FinalScoreLabel.text = "Total Score: " + str(score)
	$GameOverLayer.show()
	if gameplay_mode == "CLASSIC" and score >= 100:
		if not "GRAVITY" in unlocked_modes:
			unlocked_modes.append("GRAVITY")
			print("BẠN ĐÃ MỞ KHÓA CHẾ ĐỘ TRỌNG LỰC!")
			# (Cậu có thể gọi thêm hàm hiện bảng thông báo chúc mừng ở đây)

func _process(_delta):
	if is_game_over: return
	if is_tutorial_active: return
	
	# Tính toán thời gian thực bất kể game có đang pause hay không
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - game_start_time
	
	if gameplay_mode in ["ZEN", "MUTATION"]:
		# --- LOGIC ZEN MODE ---
		# Đếm thời gian đã chơi (đếm lên), không bao giờ gọi on_time_up()
		update_timer_display(elapsed)
		
		# Ẩn thanh lửa đi vì Zen không có áp lực thời gian
		if time_bar: 
			time_bar.hide()
	else:
		# --- LOGIC 3 MODE CÒN LẠI (TIME ATTACK) ---
		var time_left = max(0, total_duration - elapsed)
		update_timer_display(time_left)
		
		if time_bar:
			time_bar.show()
			time_bar.value = time_left
		
		# Hết 120 giây thì ép thua
		if time_left <= 0:
			on_time_up()

func update_timer_display(seconds):
	# Format về dạng MM:SS
	var mins = floor(seconds / 60.0) 
	var secs = int(seconds) % 60
	$TimeLabel.text = "%02d:%02d" % [mins, secs]
	
	# --- NÚT TẠM DỪNG Ở NGOÀI MÀN HÌNH CHÍNH (Cậu tự tạo 1 nút || rồi nối vào đây nhé) ---
func _on_pause_button_pressed():
	if is_game_over: return 
	is_paused = true
	pause_menu.show()

# --- 3 NÚT BÊN TRONG MENU PAUSE ---
func _on_btn_continue_pressed():
	is_paused = false
	pause_menu.hide()
	#$PauseMenuLayer.hide() # Ẩn menu đi là xong
	
func _on_btn_restart_pressed():
	# 1. Reset các biến trạng thái
	is_paused = false
	is_game_over = false
	$PauseMenuLayer.hide()
	
	hint_available = true
	shuffle_available = true
	remove_available = true
	is_remove_mode = false
	$PowerUpContainer/BtnShuffle.disabled = false
	$PowerUpContainer/BtnRemove.disabled = false
	$PowerUpContainer/BtnHint.disabled = false
	
	score = 0
	score_label.text = "Score: 0"
	
	# 2. Xóa sạch bàn cờ cũ
	for pos in tiles.keys():
		if is_instance_valid(tiles[pos]):
			tiles[pos].queue_free()
	tiles.clear()
	
	# 3. Sinh bàn cờ mới và reset đồng hồ Unix
	spawn_grid()
	start_time_attack_game() 
	print("Đã bắt đầu lại màn chơi mới!")

func _on_btn_quit_pressed():
	# get_tree().change_scene_to_file("res://main_menu.tscn")
	# Tạm thời in ra console, sau này cậu đổi scene về Menu chính
	print("Thoát game!")
	get_tree().quit() # Hoặc dùng lệnh chuyển scene
	
func _on_btn_restart_over_pressed():
	score = 0
	score_label.text = "Score: 0"
	is_game_over = false
	$GameOverLayer.hide()
	
	# Xóa bàn cờ cũ và tạo mới
	for pos in tiles.keys():
		if is_instance_valid(tiles[pos]):
			tiles[pos].queue_free()
	tiles.clear()
	
	spawn_grid()
	start_time_attack_game()

func _on_btn_quit_over_pressed():
	get_tree().quit()
	
func is_within_grid(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_cols and grid_pos.y >= 0 and grid_pos.y < grid_rows
	
# --- LOGIC GAMEMODE GRAVITY ---
func apply_gravity():
	# Đợi 0.2 giây để các ô cũ kịp bốc hơi
	await get_tree().create_timer(0.2).timeout 
	
	# Quét từng cột (từ trái sang phải)
	for x in range(grid_cols):
		var empty_spaces = 0
		
		# Quét từng hàng từ ĐÁY lên ĐỈNH
		for y in range(grid_rows - 1, -1, -1):
			var current_pos = Vector2(x, y)
			
			# Nếu thấy lỗ hổng, đếm số lỗ hổng
			if not tiles.has(current_pos):
				empty_spaces += 1
			# Nếu gặp một ô có số, và bên dưới nó đang có lỗ hổng
			elif empty_spaces > 0:
				var target_pos = Vector2(x, y + empty_spaces)
				var tile = tiles[current_pos]
				
				# Cập nhật lại dữ liệu trong Dictionary
				tiles.erase(current_pos)
				tiles[target_pos] = tile
				
				# (Tùy chọn) Cập nhật biến grid_pos bên trong tile nếu cần
				if tile.has_method("set_data"):
					tile.set_data(target_pos, tile.value) 
				
				# Tạo animation rơi xuống
				var target_pixel_pos = start_pos + Vector2(target_pos.x * tile_size, target_pos.y * tile_size)
				var tween = get_tree().create_tween()
				tween.tween_property(tile, "position", target_pixel_pos, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		# Kéo ô mới từ trên trần nhà thả xuống để lấp đầy phần trên cùng
		#for i in range(empty_spaces):
			#var spawn_y = empty_spaces - 1 - i
			#var spawn_pos = Vector2(x, spawn_y)
			#var new_tile = tile_scene.instantiate()
			#
			## Đặt vị trí xuất phát tuốt ở phía trên màn hình (y âm)
			#var start_pixel_pos = start_pos + Vector2(x * tile_size, (-1 - i) * tile_size)
			#var target_pixel_pos = start_pos + Vector2(spawn_pos.x * tile_size, spawn_pos.y * tile_size)
			#
			#new_tile.position = start_pixel_pos
			#add_child(new_tile)
			#
			#var random_value = randi_range(1, 9)
			#new_tile.set_data(spawn_pos, random_value)
			#tiles[spawn_pos] = new_tile
			#
			## Animation rơi từ trần nhà xuống
			#var tween = get_tree().create_tween()
			#tween.tween_property(new_tile, "position", target_pixel_pos, 0.4).set_delay(0.1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
func kill_tile_from_virus(pos: Vector2):
	if tiles.has(pos):
		# Hiệu ứng nổ nhỏ (nếu cậu thích màu mè có thể thêm ở đây)
		tiles[pos].queue_free()
		tiles.erase(pos)
		print("Một con Virus ở ", pos, " vừa tự hủy thành lỗ hổng!")

# --- HÀM TẠO CHỮ BAY LÊN Ở GIỮA MÀN HÌNH ---
func show_floating_text_center(msg: String):
	var label = Label.new()
	label.text = msg
	
	# Chỉnh font to hơn và màu đỏ
	label.add_theme_font_size_override("font_size", 60)
	label.add_theme_color_override("font_color", Color.RED)
	
	# Ép chữ căn giữa (Dùng chuẩn của Godot 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Lấy kích thước màn hình
	var screen_size = get_viewport_rect().size
	
	# Trải dài node Label hết chiều ngang màn hình, chiều cao 100
	label.size = Vector2(screen_size.x, 100)
	
	# Đặt vị trí xuất phát ngay chính giữa màn hình
	label.position = Vector2(0, screen_size.y / 2.0)
	
	add_child(label)
	
	# Animation bay lên 100 pixel và mờ dần trong 1 giây
	var tween = create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0, 100), 1.0).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	
	# Xóa sau khi bay xong
	tween.tween_callback(label.queue_free)


func _on_btn_shuffle_pressed():
	if not shuffle_available or tiles.is_empty(): return
	
	shuffle_available = false
	$PowerUpContainer/BtnShuffle.disabled = true 
	
	# BƯỚC 1: Rút toàn bộ dữ liệu của bàn cờ ra một mảng tạm
	var tile_data = []
	for pos in tiles.keys():
		var t = tiles[pos]
		tile_data.append({"val": t.value, "type": t.tile_type})
		
	# BƯỚC 2: Xáo trộn mảng dữ liệu đó
	tile_data.shuffle()
	
	# BƯỚC 3: Bơm ngược dữ liệu đã xáo trộn vào lại các ô
	var i = 0
	for pos in tiles.keys():
		var t = tiles[pos]
		
		# Nhét số và loại ô mới vào
		t.set_data(pos, tile_data[i].val, tile_data[i].type)
		i += 1
		
		# BƯỚC 4: Hiệu ứng "Lật bài" cực mạnh để biết là nút có hoạt động
		t.scale = Vector2.ZERO # Ép cái ô xẹp lép đi
		var tween = create_tween()
		tween.tween_property(t, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	print("Đã xáo trộn bàn cờ thành công!")


func _on_btn_remove_pressed():
	if not remove_available: return
	
	is_remove_mode = true # Bật chế độ ngắm bắn
	print("Chạm vào một ô bất kỳ để xóa!")


func _on_btn_hint_pressed():
	if not hint_available or tiles.is_empty(): return
	
	hint_available = false
	%BtnHint.disabled = true
	
	var found_path = find_hint_path()
	
	if found_path.size() > 0:
		print("Đã tìm thấy đường đi gợi ý!")
		# Hiệu ứng nhấp nháy màu vàng cho các ô được gợi ý
		for pos in found_path:
			if tiles.has(pos):
				var t = tiles[pos]
				var tween = create_tween().set_loops(4) # Nháy 4 vòng cho chắc ăn
				
				# Đổi màu xanh lơ và phóng to lên 1.2
				tween.tween_property(t, "modulate", Color.CYAN, 0.15)
				tween.parallel().tween_property(t, "scale", Vector2(1.2, 1.2), 0.15)
				
				# Trả về màu trắng và kích thước cũ
				tween.tween_property(t, "modulate", Color.WHITE, 0.15)
				tween.parallel().tween_property(t, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		print("Bàn cờ đang bế tắc!")
		if has_method("show_floating_text_center"):
			show_floating_text_center("KHÔNG CÓ NƯỚC ĐI!")
			
# --- THUẬT TOÁN DÒ ĐƯỜNG GỢI Ý ---
func find_hint_path() -> Array:
	var all_positions = tiles.keys()
	if all_positions.is_empty(): return []

	# Tìm giới hạn của bàn cờ hiện tại
	var min_x = 999; var max_x = -999
	var min_y = 999; var max_y = -999
	
	for pos in all_positions:
		min_x = min(min_x, int(pos.x))
		max_x = max(max_x, int(pos.x))
		min_y = min(min_y, int(pos.y))
		max_y = max(max_y, int(pos.y))

	# Quét tất cả các tọa độ góc trên-trái (x1, y1) và góc dưới-phải (x2, y2)
	for x1 in range(min_x, max_x + 1):
		for y1 in range(min_y, max_y + 1):
			for x2 in range(x1, max_x + 1):
				for y2 in range(y1, max_y + 1):
					
					var current_rect_tiles = []
					# Thu thập các ô đang sống sót trong hình chữ nhật này
					for r_x in range(x1, x2 + 1):
						for r_y in range(y1, y2 + 1):
							var p = Vector2(r_x, r_y)
							if tiles.has(p):
								current_rect_tiles.append(p)
					
					# Nếu vùng này có từ 2 ô trở lên, mang đi tính điểm xem có bằng 10 không
					if current_rect_tiles.size() > 1:
						if is_valid_sum_10(current_rect_tiles):
							return current_rect_tiles # Trúng mánh! Trả về luôn!
	return []

# --- HÀM KIỂM TRA TỔNG (Y HỆT LUẬT LÚC NGƯỜI CHƠI KÉO) ---
func is_valid_sum_10(rect_tiles: Array) -> bool:
	var total_sum = 0
	var has_joker = false
	var sum_others = 0
	
	for pos in rect_tiles: 
		var t = tiles[pos]
		if t.tile_type == "JOKER":
			has_joker = true
		else:
			sum_others += t.value
			total_sum += t.value
			
	# Áp dụng đúng luật Nerf Joker: Phải nằm trong sức chịu đựng [-9 đến 9]
	if has_joker:
		var needed_value = 10 - sum_others
		if needed_value >= -9 and needed_value <= 9:
			return true
		else:
			return false
	else:
		return total_sum == 10

# --- LOGIC CHẠY TUTORIAL ---
func check_and_start_tutorial():
	if not seen_tutorials[gameplay_mode]:
		start_tutorial()

func start_tutorial():
	is_tutorial_active = true
	current_tutorial_step = 0
	$TutorialLayer.show()
	update_tutorial_ui()

func update_tutorial_ui():
	var texts = tutorial_texts[gameplay_mode]
	%TutorialText.text = texts[current_tutorial_step]
	
	# Đổi chữ nút Next thành "Bắt đầu" nếu là trang cuối
	if current_tutorial_step == texts.size() - 1:
		%BtnNext.text = "Bắt đầu trải nghiệm!"
	else:
		%BtnNext.text = "Tiếp theo"

func close_tutorial():
	$TutorialLayer.hide()
	is_tutorial_active = false
	seen_tutorials[gameplay_mode] = true # Đánh dấu là đã xem

# --- CÁC HÀM TỪ NÚT BẤM (SIGNAL) ---
func _on_btn_next_pressed():
	var texts = tutorial_texts[gameplay_mode]
	if current_tutorial_step < texts.size() - 1:
		current_tutorial_step += 1
		update_tutorial_ui()
	else:
		close_tutorial()

func _on_btn_skip_pressed():
	close_tutorial()

func _on_btn_help_pressed():
	# Nút ? để xem lại bất cứ lúc nào
	start_tutorial()
	
	# Hàm cập nhật giao diện điểm
func update_score_ui():
	# Nhớ đổi $ScoreLabel thành tên Node chứa điểm thực tế của cậu (ví dụ %Score, $UI/Score...)
	$ScoreLabel.text = "Score: " + str(score)
