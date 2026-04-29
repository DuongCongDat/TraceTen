extends Area2D

var grid_pos = Vector2.ZERO # Lưu tọa độ (x,y) của ô này trên lưới
var value = 0               # Giá trị số của ô
var tile_type = "NORMAL" # CÁC LOẠI: NORMAL, NEGATIVE, MYSTERY, VIRUS, JOKER
var is_selected = false     # Trạng thái đang được vuốt qua
var virus_timer = 0.0
@onready var original_style = $Background.get_theme_stylebox("panel").duplicate() #Lưu lại giá trị bo góc

func set_data(pos, val, type = "NORMAL"):
	grid_pos = pos
	value = val
	tile_type = type
	update_visuals()

func update_visuals():
	# Đã sửa lại đường dẫn theo đúng cây thư mục của cậu
	var label = $Background/Label 
	var bg = $Background 
	
	if tile_type == "NORMAL":
		label.text = str(value)
		bg.modulate = Color.WHITE
	elif tile_type == "NEGATIVE":
		label.text = str(value)
		bg.modulate = Color.PALE_VIOLET_RED # Màu đỏ cảnh báo
	elif tile_type == "MYSTERY":
		label.text = str(value) if is_selected else "?"
		bg.modulate = Color.DARK_GRAY # Màu xám bí ẩn
	elif tile_type == "VIRUS":
		label.text = str(value)
		bg.modulate = Color.GREEN_YELLOW # Xanh lá độc hại
	elif tile_type == "JOKER":
		label.text = "★" # Ngôi sao
		bg.modulate = Color.GOLD # Màu vàng kim

func select():
	is_selected = true
	# Sửa lại thành $Background
	$Background.modulate = $Background.modulate.darkened(0.2) 
	if tile_type == "MYSTERY": 
		update_visuals() # Lật mặt dấu ?

func deselect():
	is_selected = false
	update_visuals() # Trả lại màu gốc và úp lại dấu ?
	
# LOGIC VIRUS: Tự động đổi số mỗi 5 giây
# LOGIC VIRUS: Tự động đổi số mỗi 5 giây với tỷ lệ an toàn
func _process(delta):
	if tile_type == "VIRUS" and not is_selected:
		virus_timer += delta
		if virus_timer >= 10.0:
			virus_timer = 0.0
			
			var p = randf()
			if p <= 0.65:
				value = randi_range(1, 9)       # 65% ra số dương
			elif p <= 0.95:
				value = randi_range(-5, -1)     # 30% ra số âm nhỏ
			elif p <= 0.99:
				value = randi_range(-9, -6)     # 4% ra số âm lớn
			else:
				value = 0                       # 1% trúng số 0 (Tự hủy)
			
			if value == 0:
				# Nếu random ra 0 -> Tự hủy thành lỗ hổng
				if get_parent().has_method("kill_tile_from_virus"):
					get_parent().kill_tile_from_virus(grid_pos)
			else:
				# Hiển thị số mới và hiệu ứng giật nảy
				update_visuals()
				var tween = create_tween()
				tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
				tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
