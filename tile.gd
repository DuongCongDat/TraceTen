extends Area2D
class_name BaseTile

var grid_pos = Vector2.ZERO
var value = 0
var tile_type = "NORMAL"
var is_selected = false
var virus_timer = 0.0
var _tile_style: StyleBoxFlat

func _ready():
	_tile_style = $Background.get_theme_stylebox("panel").duplicate()
	$Background.add_theme_stylebox_override("panel", _tile_style)

func set_data(pos, val, type = "NORMAL"):
	grid_pos = pos
	value = val
	tile_type = type
	update_visuals()

func get_effective_value() -> int:
	return value

func update_visuals():
	var label = $Background/Label
	var bg = $Background
	label.text = str(value)
	bg.modulate = Color.WHITE
	if _tile_style:
		_tile_style.bg_color = _value_bg_color(value)
	_update_type_visuals()

func _value_bg_color(val: int) -> Color:
	var cool = Color(0.18, 0.26, 0.52, 1.0)
	var warm = Color(0.50, 0.25, 0.14, 1.0)
	if val <= 0:
		return Color(0.22, 0.27, 0.38, 1.0)
	var t = clamp((val - 1) / 8.0, 0.0, 1.0)
	return cool.lerp(warm, t)

# Virtual: subclass override để tùy chỉnh hiển thị theo loại ô.
func _update_type_visuals():
	pass

func select():
	is_selected = true
	$Background.modulate = $Background.modulate.darkened(0.2)

func deselect():
	is_selected = false
	update_visuals()
