extends BaseTile

var _virus_style: StyleBoxFlat
var _countdown_dots: Array = []
var _ticks_remaining: int = 4
var _max_ticks: int = 4
var _glow_tween: Tween

func _ready():
	super._ready()
	_max_ticks = randi_range(1, 5)
	_ticks_remaining = _max_ticks
	_virus_style = _make_virus_style()
	_bg.add_theme_stylebox_override("panel", _virus_style)
	_label.add_theme_color_override("font_color", ThemeTokens.VIRUS_TEXT)
	_add_countdown_dots()
	_start_glow_pulse()

func _make_virus_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.VIRUS_BG
	ThemeTokens._set_radius(sb, ThemeTokens.TILE_RADIUS)
	sb.border_width_bottom = 3
	sb.border_width_top    = 3
	sb.border_width_left   = 3
	sb.border_width_right  = 3
	sb.border_color = ThemeTokens.VIRUS_DARK
	sb.shadow_color = ThemeTokens.VIRUS_GLOW
	sb.shadow_size  = 0
	sb.shadow_offset = Vector2.ZERO
	return sb

func _add_countdown_dots():
	var dot_size  := 8.0
	var dot_gap   := 5.0
	var n         := _max_ticks
	var total_w   := n * dot_size + (n - 1) * dot_gap
	var start_x   := (80.0 - total_w) * 0.5
	var y         := 62.0

	_countdown_dots.clear()
	for i in n:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(dot_size, dot_size)
		dot.size     = Vector2(dot_size, dot_size)
		dot.position = Vector2(start_x + i * (dot_size + dot_gap), y)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		ThemeTokens._set_radius(sb, 999)
		sb.bg_color    = ThemeTokens.VIRUS_DARK
		sb.border_width_bottom = 2
		sb.border_width_top    = 2
		sb.border_width_left   = 2
		sb.border_width_right  = 2
		sb.border_color = ThemeTokens.VIRUS_DARK
		dot.add_theme_stylebox_override("panel", sb)
		_bg.add_child(dot)
		_countdown_dots.append({"panel": dot, "style": sb})
	_refresh_dots()

func _refresh_dots():
	for i in _countdown_dots.size():
		var entry = _countdown_dots[i]
		var sb: StyleBoxFlat = entry["style"]
		if i < _ticks_remaining:
			sb.bg_color = ThemeTokens.VIRUS_DARK
			entry["panel"].modulate.a = 1.0
		else:
			sb.bg_color = Color.TRANSPARENT
			entry["panel"].modulate.a = 0.4

func _start_glow_pulse():
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_method(_set_glow_size, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_method(_set_glow_size, 1.0, 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_glow_size(t: float):
	if is_instance_valid(_virus_style):
		_virus_style.shadow_size = int(t * 8)

func _update_type_visuals():
	if is_instance_valid(_virus_style):
		_bg.add_theme_stylebox_override("panel", _virus_style)
	_label.add_theme_color_override("font_color", ThemeTokens.VIRUS_TEXT)
	_label.text = str(value)

func _process(delta):
	if is_selected or get_parent().is_paused:
		return
	virus_timer += delta
	if virus_timer < 10.0:
		return
	virus_timer = 0.0

	if _ticks_remaining > 0:
		_ticks_remaining -= 1
		_refresh_dots()

	if _ticks_remaining <= 0:
		# All dots depleted — spread to adjacent tile
		_ticks_remaining = _max_ticks
		_refresh_dots()
		if get_parent().has_method("kill_tile_from_virus"):
			get_parent().kill_tile_from_virus(grid_pos)
		return

	# Mutate value each tick
	var p := randf()
	if p <= 0.65:
		value = randi_range(1, 9)
	elif p <= 0.95:
		value = randi_range(-5, -1)
	else:
		value = randi_range(-9, -6)
	update_visuals()
	var normal_scale := scale
	var tween := create_tween()
	tween.tween_property(self, "scale", normal_scale * 1.2, 0.1)
	tween.tween_property(self, "scale", normal_scale, 0.1)
