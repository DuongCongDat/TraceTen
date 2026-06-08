class_name LifeTile
extends Control

const ROSE        = Color("#d96060")
const ROSE_WASHED = Color("#e8ddd0")
const BORDER_LOST = Color("#c8c0b0")
const RADIUS      = 4.0

var is_active: bool = true
var _drain: float   = 0.0  # 0 = full rose, 1 = washed (animated on life loss)

var _sb:   StyleBoxFlat
var _font: Font

func _ready():
	_sb = StyleBoxFlat.new()
	ThemeTokens._set_radius(_sb, int(RADIUS))
	_sb.border_color        = Color("#c46a6a55")  # inset hairline per spec
	_sb.border_width_left   = 2
	_sb.border_width_right  = 2
	_sb.border_width_top    = 2
	_sb.border_width_bottom = 2
	_font = ThemeTokens.font_inter(700)

func _draw():
	if is_active:
		_sb.bg_color = ROSE.lerp(ROSE_WASHED, _drain)
		_sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
		draw_string(_font, Vector2(0.0, size.y * 0.76), "♥",
			HORIZONTAL_ALIGNMENT_CENTER, int(size.x), int(size.y * 0.65),
			Color(1.0, 1.0, 1.0, 1.0 - _drain * 0.7))
	else:
		var m := 1.0
		_dash_seg(Vector2(m,        m       ), Vector2(size.x - m, m       ))
		_dash_seg(Vector2(size.x-m, m       ), Vector2(size.x - m, size.y-m))
		_dash_seg(Vector2(size.x-m, size.y-m), Vector2(m,          size.y-m))
		_dash_seg(Vector2(m,        size.y-m), Vector2(m,          m       ))

func _dash_seg(a: Vector2, b: Vector2):
	var total := a.distance_to(b)
	if total < 0.1: return
	var dir := (b - a) / total
	var pos := 0.0
	while pos < total:
		draw_line(a + dir * pos, a + dir * minf(pos + 3.0, total), BORDER_LOST, 1.5)
		pos += 5.0
