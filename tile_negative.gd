extends BaseTile

var _neg_style: StyleBoxFlat

func _ready():
	super._ready()
	_neg_style = _make_neg_style()
	_bg.add_theme_stylebox_override("panel", _neg_style)
	_label.add_theme_color_override("font_color", ThemeTokens.NEG_DARK)
	_add_chevron()

func _make_neg_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.NEG_BG
	ThemeTokens._set_radius(sb, ThemeTokens.TILE_RADIUS)
	sb.border_width_bottom = 2
	sb.border_color = Color(ThemeTokens.NEG_DARK.r, ThemeTokens.NEG_DARK.g, ThemeTokens.NEG_DARK.b, 0.2)
	sb.shadow_color = Color(0.549, 0.235, 0.235, 0.1)
	sb.shadow_size  = 2
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _add_chevron():
	# Small "▾" label bottom-right of tile
	var lbl := Label.new()
	lbl.text = "▾"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", ThemeTokens.NEG_DARK)
	lbl.position = Vector2(54, 50)
	lbl.size     = Vector2(20, 20)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(lbl)

func _update_type_visuals():
	if is_instance_valid(_neg_style):
		_bg.add_theme_stylebox_override("panel", _neg_style)
	_label.add_theme_color_override("font_color", ThemeTokens.NEG_DARK)
