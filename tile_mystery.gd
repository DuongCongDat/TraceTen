extends BaseTile

var _hidden_style: StyleBoxFlat
var _revealed_style: StyleBoxFlat
var _hatch: Control

func _ready():
	super._ready()
	_hidden_style = _make_hidden_style()
	_revealed_style = _make_revealed_style()

	# Hatch overlay — visible only when hidden
	_hatch = MysteryHatch.new()
	_hatch.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.add_child(_hatch)

	_apply_hidden()

func _make_hidden_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.MYSTERY_BG
	ThemeTokens._set_radius(sb, ThemeTokens.TILE_RADIUS)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _make_revealed_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.MYSTERY_REV_BG
	ThemeTokens._set_radius(sb, ThemeTokens.TILE_RADIUS)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _apply_hidden():
	_bg.add_theme_stylebox_override("panel", _hidden_style)
	_label.text = "?"
	_label.add_theme_color_override("font_color", ThemeTokens.MYSTERY_TEXT)
	if _hatch:
		_hatch.visible = true

func _apply_revealed():
	_bg.add_theme_stylebox_override("panel", _revealed_style)
	_label.text = str(value)
	_label.add_theme_color_override("font_color", ThemeTokens.MYSTERY_REV_TEXT)
	if _hatch:
		_hatch.visible = false

func _update_type_visuals():
	if is_selected:
		_apply_revealed()
	else:
		_apply_hidden()

func select():
	if not is_selected:
		Global.unlock_achievement("first_special")
	is_selected = true
	_apply_revealed()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.05, 1.05), 0.08)
