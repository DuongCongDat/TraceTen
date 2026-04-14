extends Area2D

var grid_pos = Vector2.ZERO # Lưu tọa độ (x,y) của ô này trên lưới
var value = 0               # Giá trị số của ô
var is_selected = false     # Trạng thái đang được vuốt qua
@onready var original_style = $Background.get_theme_stylebox("panel").duplicate() #Lưu lại giá trị bo góc

func set_data(pos: Vector2, val: int):
	grid_pos = pos
	value = val
	$Background/Label.text = str(value) # Hiện số lên màn hình

func select():
	is_selected = true
	
	# 1. Lấy cái khung bo góc hiện tại và nhân bản (duplicate) nó ra
	var new_style = original_style.duplicate()
	# 2. Đổi màu nền của bản sao này sang Vàng chanh
	new_style.bg_color = Color(0.8, 0.8, 0.5) 
	# 3. Gắn nó lại vào Background
	$Background.add_theme_stylebox_override("panel", new_style)
	
	# Đổi màu chữ sang đen
	$Background/Label.add_theme_color_override("font_color", Color.BLACK) 

func deselect():
	is_selected = false
	
	# Xóa cái style màu vàng đi, tự động trở về màu mặc định ban đầu
	$Background.add_theme_stylebox_override("panel", original_style)
	
	# Trả màu chữ về mặc định
	$Background/Label.remove_theme_color_override("font_color")
