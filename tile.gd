extends Area2D
class_name BaseTile

var grid_pos = Vector2.ZERO
var value = 0
var tile_type = "NORMAL"
var is_selected = false
var virus_timer = 0.0
@onready var original_style = $Background.get_theme_stylebox("panel").duplicate()

func set_data(pos, val, type = "NORMAL"):
	grid_pos = pos
	value = val
	tile_type = type
	update_visuals()

# Trả về giá trị dùng để tính tổng. Subclass JOKER sẽ override trả về 0.
func get_effective_value() -> int:
	return value

func update_visuals():
	var label = $Background/Label
	var bg = $Background
	label.text = str(value)
	bg.modulate = Color.WHITE
	_update_type_visuals()

# Virtual: subclass override để tùy chỉnh hiển thị theo loại ô.
func _update_type_visuals():
	pass

func select():
	is_selected = true
	$Background.modulate = $Background.modulate.darkened(0.2)

func deselect():
	is_selected = false
	update_visuals()
