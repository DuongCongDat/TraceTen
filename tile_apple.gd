extends BaseTile

const TEX_RED   = preload("res://assets/ui/tiles/apple_red.png")
const TEX_GREEN = preload("res://assets/ui/tiles/apple_green.png")

const DIR_ROT_DEG := {
	"DOWN":   0.0,
	"UP":   180.0,
	"LEFT":   90.0,
	"RIGHT": -90.0,
}

var _tex_rect:   TextureRect
var _sb_idle:    StyleBoxFlat
var _sb_sel:     StyleBoxFlat
var _stem_tween: Tween

func _ready():
	super._ready()

	# Idle = board background → tile "blends in", only apple shape visible
	_sb_idle = StyleBoxFlat.new()
	_sb_idle.bg_color = ThemeTokens.BOARD_BG
	ThemeTokens._set_radius(_sb_idle, ThemeTokens.TILE_RADIUS)

	_sb_sel = _sb_idle  # same board-bg, green apple texture is the only selected indicator

	_bg.add_theme_stylebox_override("panel", _sb_idle)

	_bg.clip_contents = false  # allow apple to bleed slightly beyond panel rect

	_tex_rect = TextureRect.new()
	_tex_rect.texture      = TEX_RED
	_tex_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Extend 12px beyond panel on each side → apple fills ~128% of tile cell
	var pad := 12.0
	_tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex_rect.offset_left   -= pad
	_tex_rect.offset_top    -= pad
	_tex_rect.offset_right  += pad
	_tex_rect.offset_bottom += pad
	_tex_rect.pivot_offset = Vector2(40.0 + pad, 40.0 + pad)  # stays at panel center

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.r < 0.04 && c.g < 0.04 && c.b < 0.04) discard;
	COLOR = c;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_tex_rect.material = mat

	_bg.add_child(_tex_rect)
	_bg.move_child(_tex_rect, 0)

	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 44)
	_label.offset_top = 24  # push number into apple body, clear of stem at top


func set_direction(dir: String, animate: bool = true):
	if not _tex_rect: return
	var target_deg: float = DIR_ROT_DEG.get(dir, 0.0)
	if animate:
		if _stem_tween and _stem_tween.is_running():
			_stem_tween.kill()
		_stem_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_stem_tween.tween_property(_tex_rect, "rotation_degrees", target_deg, 0.28)
	else:
		_tex_rect.rotation_degrees = target_deg


func select():
	is_selected = true
	if _tex_rect:
		_tex_rect.texture = TEX_GREEN
	_bg.add_theme_stylebox_override("panel", _sb_sel)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.05, 1.05), 0.08)


func deselect():
	is_selected = false
	if _tex_rect:
		_tex_rect.texture = TEX_RED
	_bg.add_theme_stylebox_override("panel", _sb_idle)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg, "scale", Vector2(1.0, 1.0), 0.08)
	update_visuals()


func _update_type_visuals():
	if _tex_rect:
		_tex_rect.texture = TEX_GREEN if is_selected else TEX_RED
	_bg.add_theme_stylebox_override("panel", _sb_sel if is_selected else _sb_idle)
	_label.add_theme_color_override("font_color", Color.WHITE)

func flash_wrong():
	var tween = create_tween()
	tween.tween_property(_label, "modulate", Color.RED, 0.07)
	tween.tween_property(_label, "modulate", Color.WHITE, 0.07)
	tween.tween_property(_label, "modulate", Color.RED, 0.07)
	tween.tween_property(_label, "modulate", Color.WHITE, 0.07)
