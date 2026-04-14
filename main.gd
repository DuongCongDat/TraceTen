extends Node2D

var tile_scene = preload("res://tile.tscn")
#var grid_size = 5
var grid_cols = 6
var grid_rows= 8
var tile_size = 105 
#var start_pos = Vector2(85, 300)
var start_pos = Vector2.ZERO

var tiles = {}

# ==========================================
# CÔNG TẮC ĐỔI GAME MODE Ở ĐÂY
# Đổi thành "TRACE" nếu muốn kẻ viền đỏ
# Đổi thành "RECTANGLE" nếu muốn kéo khung
var current_mode = "RECTANGLE" 
# ==========================================

@onready var selection_box = $SelectionBox
@onready var trace_line = $DrawLine

var is_dragging = false

# Biến cho Mode Kéo Khung
var drag_start_grid = Vector2.ZERO
var selected_tiles = []

# Biến cho Mode Kẻ Viền
var vertex_path = []

func _ready():
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
	
	spawn_grid()

func spawn_grid():
	for x in range(grid_cols):
		for y in range(grid_rows):
			var new_tile = tile_scene.instantiate()
			new_tile.position = start_pos + Vector2(x * tile_size, y * tile_size)
			add_child(new_tile)
			var grid_pos = Vector2(x, y)
			new_tile.set_data(grid_pos, randi_range(1, 9))
			tiles[grid_pos] = new_tile

# --- BỘ CHIA TÍN HIỆU ĐIỀU KHIỂN ---
func _input(event):
	if current_mode == "RECTANGLE":
		handle_rectangle_input(event)
	elif current_mode == "TRACE":
		handle_trace_input(event)

# ==========================================
# PHẦN 1: LOGIC KÉO KHUNG (RECTANGLE MODE)
# ==========================================
func handle_rectangle_input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_dragging = true
			drag_start_grid = pixel_to_grid(event.position)
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
	var grid_x = clamp(floor((pixel_pos.x - top_left_corner.x) / tile_size), 0, grid_cols - 1)
	var grid_y = clamp(floor((pixel_pos.y - top_left_corner.y) / tile_size), 0, grid_rows - 1)
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
	for pos in selected_tiles: total_sum += tiles[pos].value
	
	if total_sum == 10:
		for pos in selected_tiles:
			if tiles.has(pos):
				tiles[pos].queue_free()
				tiles.erase(pos)
				
		# --- ĐIỀU KIỆN REFILL 80% ---
		var total_slots = grid_rows * grid_cols # 10x7 = 70
		var remaining_tiles = tiles.size()
		var cleared_percent = 1.0 - (float(remaining_tiles) / float(total_slots))
		
		# Nếu đã dọn dẹp được từ 80% bàn cờ trở lên
		if cleared_percent >= 0.75:
			print("Đã dọn sạch ", round(cleared_percent * 100), "%! Gọi wave mới...")
			refill_empty_slots()
		# ----------------------------
	else:
		await get_tree().create_timer(0.3).timeout
		for pos in selected_tiles:
			if tiles.has(pos): tiles[pos].deselect()
			
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
