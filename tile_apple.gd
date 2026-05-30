extends BaseTile

const AppleDrawScript = preload("res://scripts/apple_draw.gd")

# Maps fall direction → stem angle (stem points AWAY from fall)
const DIR_STEM_RAD := {
	"DOWN":  -PI * 0.5,  # stem up
	"UP":    PI * 0.5,   # stem down
	"LEFT":  0.0,        # stem right
	"RIGHT": PI,         # stem left
}

var _apple_draw: AppleDraw
var _stem_tween: Tween

func _ready():
	super._ready()

	# Transparent panel — apple drawing handles the full visual
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	_bg.add_theme_stylebox_override("panel", sb)

	_apple_draw = AppleDrawScript.new()
	_apple_draw.size         = Vector2(80.0, 80.0)
	_apple_draw.position     = Vector2(0.0, 0.0)
	_apple_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(_apple_draw)
	_bg.move_child(_apple_draw, 0)  # behind Label

	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 44)


func set_direction(dir: String, animate: bool = true):
	if not _apple_draw:
		return
	var target: float = DIR_STEM_RAD.get(dir, -PI * 0.5)
	if animate:
		if _stem_tween and _stem_tween.is_running():
			_stem_tween.kill()
		_stem_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_stem_tween.tween_method(_set_stem_rad, _apple_draw.stem_rad, target, 0.28)
	else:
		_apple_draw.stem_rad = target
		_apple_draw.queue_redraw()


func _set_stem_rad(val: float):
	if _apple_draw:
		_apple_draw.stem_rad = val
		_apple_draw.queue_redraw()


func select():
	is_selected = true
	if _apple_draw:
		_apple_draw.selected = true
		_apple_draw.queue_redraw()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.05, 1.05), 0.08)


func deselect():
	is_selected = false
	if _apple_draw:
		_apple_draw.selected = false
		_apple_draw.queue_redraw()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.0, 1.0), 0.08)
	update_visuals()


func _update_type_visuals():
	if _apple_draw:
		_apple_draw.selected = is_selected
		_apple_draw.queue_redraw()
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.text = str(value)
