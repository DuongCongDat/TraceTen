extends Area2D
class_name BaseTile

var grid_pos = Vector2.ZERO
var value = 0
var tile_type = "NORMAL"
var is_selected = false
var virus_timer = 0.0

var _idle_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _bg: Panel
var _label: Label

func _ready():
	_bg    = $Background
	_label = $Background/Label
	_bg.clip_contents = true
	_idle_style     = ThemeTokens.sb_tile_idle()
	_selected_style = ThemeTokens.sb_tile_selected()
	_bg.add_theme_stylebox_override("panel", _idle_style)
	var fv = ThemeTokens.font_mono(700)
	_label.add_theme_font_override("font", fv)
	_label.add_theme_color_override("font_color", ThemeTokens.TEXT)

func set_data(pos, val, type = "NORMAL"):
	grid_pos = pos
	value    = val
	tile_type = type
	update_visuals()

func get_effective_value() -> int:
	return value

func update_visuals():
	if not _bg or not _label:
		return
	_label.text = str(value)
	_bg.add_theme_stylebox_override("panel", _idle_style)
	_label.add_theme_color_override("font_color", ThemeTokens.TEXT)
	_bg.modulate = Color.WHITE
	_update_type_visuals()

# Virtual — subclass overrides for type-specific look.
func _update_type_visuals():
	pass

func select():
	is_selected = true
	_bg.add_theme_stylebox_override("panel", _selected_style)
	_label.add_theme_color_override("font_color", Color.WHITE)
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.05, 1.05), 0.08)

func deselect():
	is_selected = false
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.0, 1.0), 0.08)
	update_visuals()

func flash_wrong():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.07)
	tween.tween_property(self, "modulate", Color.WHITE, 0.07)
	tween.tween_property(self, "modulate", Color.RED, 0.07)
	tween.tween_property(self, "modulate", Color.WHITE, 0.07)
