extends BaseTile

func get_effective_value() -> int:
	return 0

func _ready():
	super._ready()
	_apply_joker_style()
	_add_gradient_bg()
	_add_jester()
	_add_sparkle()
	_label.text = ""  # jester replaces the number

func _apply_joker_style():
	var sb := StyleBoxFlat.new()
	# Amber background; gradient is overlaid via TextureRect child
	sb.bg_color = ThemeTokens.JOKER_A
	ThemeTokens._set_radius(sb, ThemeTokens.TILE_RADIUS)
	sb.border_width_bottom = 2
	sb.border_width_top    = 2
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_color = Color(ThemeTokens.JOKER_STROKE.r, ThemeTokens.JOKER_STROKE.g, ThemeTokens.JOKER_STROKE.b, 0.33)
	sb.shadow_color = Color(ThemeTokens.JOKER_B.r, ThemeTokens.JOKER_B.g, ThemeTokens.JOKER_B.b, 0.67)
	sb.shadow_size  = 18
	sb.shadow_offset = Vector2.ZERO
	_bg.add_theme_stylebox_override("panel", sb)

func _add_gradient_bg():
	var grad := Gradient.new()
	grad.set_color(0, ThemeTokens.JOKER_A)
	grad.set_color(1, ThemeTokens.JOKER_B)
	var tex := GradientTexture2D.new()
	tex.gradient   = grad
	tex.fill_from  = Vector2(0.2, 0.0)
	tex.fill_to    = Vector2(0.8, 1.0)
	var tr := TextureRect.new()
	tr.texture        = tex
	tr.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode   = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(tr)
	_bg.move_child(tr, 0)  # behind label

func _add_jester():
	var draw := JokerDraw.new()
	# Top-left anchors (default) so position is relative to Background top-left.
	# Jester 52×48 centered in 80×80, leaving room for sparkle near bottom-right.
	draw.size         = Vector2(52, 48)
	draw.position     = Vector2(14, 8)
	draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(draw)

func _add_sparkle():
	var spark := ColorRect.new()
	spark.size     = Vector2(8, 8)
	spark.position = Vector2(62, 62)
	spark.color    = Color.WHITE
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Rounded pill via a Panel would be cleaner, but ColorRect is fine at this scale
	_bg.add_child(spark)

func _update_type_visuals():
	_label.text = ""
