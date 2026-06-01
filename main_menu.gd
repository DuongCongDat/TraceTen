extends Control

var _settings_layer: CanvasLayer = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_theme()

# ─── Navigation ───────────────────────────────────────────────

func _on_btn_play_pressed():
	# Resume last played mode directly; default Classic for first-timers
	var mode := Global.last_played_mode if Global.last_played_mode != "" else "CLASSIC"
	Global.selected_mode = mode
	Global.load_save = Global.has_save(mode)
	get_tree().change_scene_to_file("res://main.tscn")

func _on_btn_highscore_pressed():
	get_tree().change_scene_to_file("res://highscore.tscn")

func _on_btn_achievements_pressed():
	get_tree().change_scene_to_file("res://achievement_screen.tscn")

func _on_btn_help_pressed():
	get_tree().change_scene_to_file("res://tutorial.tscn")

func _on_btn_quit_pressed():
	get_tree().quit()

func _on_btn_settings_pressed():
	if _settings_layer == null:
		_build_settings_panel()
	_settings_layer.show()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _settings_layer and _settings_layer.visible:
			_settings_layer.hide()
		else:
			get_tree().quit()

# ─── Font helpers ─────────────────────────────────────────────

func _inter(weight: int, spacing: int = 0) -> FontVariation:
	var fv := ThemeTokens.font_inter(weight)
	if spacing != 0:
		fv.spacing_glyph = spacing
	return fv

func _mono(weight: int, spacing: int = 0) -> FontVariation:
	var fv := ThemeTokens.font_mono(weight)
	if spacing != 0:
		fv.spacing_glyph = spacing
	return fv

# ─── Theme ────────────────────────────────────────────────────

func _apply_theme():
	$Background.color = ThemeTokens.APP_BG

	_add_floating_bg()

	var mc := $MarginContainer
	mc.add_theme_constant_override("margin_left",   52)
	mc.add_theme_constant_override("margin_right",  52)
	mc.add_theme_constant_override("margin_top",    44)
	mc.add_theme_constant_override("margin_bottom", 48)

	var layout := $MarginContainer/MainLayout
	layout.add_theme_constant_override("separation", 16)

	$MarginContainer/MainLayout/Title.hide()

	# Existing Spacer takes 2× free space → pushes logo+buttons group down
	$MarginContainer/MainLayout/Spacer.size_flags_stretch_ratio = 2.0

	var logo := _build_logo_block()
	layout.add_child(logo)
	layout.move_child(logo, 2)  # Title[0], Spacer[1], Logo[2], Buttons[3]

	var mid_gap := Control.new()
	mid_gap.custom_minimum_size = Vector2(0, 52)
	layout.add_child(mid_gap)
	layout.move_child(mid_gap, 3)  # Logo[2], MidGap[3], Buttons[4]

	_style_nav_buttons()
	$MarginContainer/MainLayout/Buttons/BtnSettings.hide()

	# Small spacer below Buttons (1× = 1/3 of free space)
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer2.size_flags_stretch_ratio = 1.0
	layout.add_child(spacer2)

	var ver := _build_version_label()
	layout.add_child(ver)

	_add_settings_cog()

# ─── Logo ─────────────────────────────────────────────────────

func _build_logo_block() -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)

	var lbl_trace := Label.new()
	lbl_trace.text = "trace"
	lbl_trace.add_theme_font_override("font", _inter(800))
	lbl_trace.add_theme_font_size_override("font_size", 76)
	lbl_trace.add_theme_color_override("font_color", ThemeTokens.TEXT)
	lbl_trace.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl_trace)

	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(104, 104)
	var sb_tile := StyleBoxFlat.new()
	sb_tile.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(sb_tile, 22)
	sb_tile.border_width_bottom = 8
	sb_tile.border_color = ThemeTokens.MINT_DARK
	tile.add_theme_stylebox_override("panel", sb_tile)

	var lbl_10 := Label.new()
	lbl_10.text = "10"
	lbl_10.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl_10.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_10.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_10.add_theme_font_override("font", ThemeTokens.font_mono(800))
	lbl_10.add_theme_font_size_override("font_size", 48)
	lbl_10.add_theme_color_override("font_color", Color.WHITE)
	tile.add_child(lbl_10)
	row.add_child(tile)

	vb.add_child(row)

	var sub := Label.new()
	sub.text = "Sum to ten · clear the grid"
	sub.add_theme_font_override("font", _inter(600, 2))
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	return vb

# ─── Nav buttons ──────────────────────────────────────────────

func _style_nav_buttons():
	var btns := $MarginContainer/MainLayout/Buttons
	btns.add_theme_constant_override("separation", 16)

	# ── PLAY (primary) ──────────────────────────────────────────
	var last_key := Global.last_played_mode if Global.last_played_mode != "" else "CLASSIC"
	var mode_labels := {"CLASSIC":"CLASSIC","ZEN":"ZEN","GRAVITY":"GRAVITY",
						"MUTATION":"MUTATION","CHALLENGE":"ADVENTURE"}
	var mode_chip_text: String = mode_labels.get(last_key, "CLASSIC")

	var btn_play := $MarginContainer/MainLayout/Buttons/BtnPlay
	btn_play.text = "PLAY"
	btn_play.custom_minimum_size = Vector2(0, 128)
	btn_play.add_theme_font_override("font", _inter(800, 7))
	btn_play.add_theme_font_size_override("font_size", 34)
	btn_play.add_theme_color_override("font_color", Color.WHITE)
	btn_play.add_theme_color_override("font_outline_color", Color.WHITE)
	btn_play.add_theme_constant_override("outline_size", 2)

	var sb_play := StyleBoxFlat.new()
	sb_play.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(sb_play, ThemeTokens.CHIP_RADIUS)
	sb_play.border_width_bottom = 8
	sb_play.border_color = ThemeTokens.MINT_DARK
	sb_play.shadow_color = Color(ThemeTokens.MINT_DARK.r, ThemeTokens.MINT_DARK.g, ThemeTokens.MINT_DARK.b, 0.5)
	sb_play.shadow_size = 14
	sb_play.shadow_offset = Vector2(0, 6)
	btn_play.add_theme_stylebox_override("normal", sb_play)
	var sb_play_h := sb_play.duplicate() as StyleBoxFlat
	sb_play_h.bg_color = ThemeTokens.MINT_DARK
	btn_play.add_theme_stylebox_override("hover", sb_play_h)
	btn_play.add_theme_stylebox_override("pressed", sb_play_h)

	_add_mode_chip(btn_play, mode_chip_text)

	# ── MODES (new, goes to mode_select) ─────────────────────────
	var btn_modes := Button.new()
	btns.add_child(btn_modes)
	btns.move_child(btn_modes, 1)
	_style_sec_btn(btn_modes, "MODES", "")
	btn_modes.pressed.connect(func(): get_tree().change_scene_to_file("res://mode_select.tscn"))

	# ── Highscore sub-text: top score for last mode ───────────────
	var hs := Global.load_highscore()
	var top: Array = hs.get(last_key, [])
	var score_str := "%d" % int(top[0].get("score", 0)) if not top.is_empty() else ""

	# ── Achievement sub-text: X / 25 ─────────────────────────────
	var ach_str := "%d / 25" % Global.count_unlocked()

	_style_sec_btn($MarginContainer/MainLayout/Buttons/BtnHighscore,    "HIGHSCORE",    score_str)
	_style_sec_btn($MarginContainer/MainLayout/Buttons/BtnAchievements, "ACHIEVEMENTS", ach_str)
	_style_sec_btn($MarginContainer/MainLayout/Buttons/BtnHelp,         "TUTORIAL",     "")
	_style_sec_btn($MarginContainer/MainLayout/Buttons/BtnQuit,         "QUIT",         "")

func _style_sec_btn(btn: Button, label_text: String, sub_text: String):
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 96)
	btn.add_theme_font_override("font", _inter(600, 4))
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", ThemeTokens.TEXT)
	btn.add_theme_color_override("font_outline_color", ThemeTokens.TEXT)
	btn.add_theme_constant_override("outline_size", 2)
	var sb := ThemeTokens.sb_menu_button()
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = ThemeTokens.BOARD_BG
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)

	if sub_text == "":
		return
	var sub := Label.new()
	sub.text = sub_text
	sub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub.offset_right = -28.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sub.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", _mono(600))
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(sub)

func _add_mode_chip(btn: Button, chip_text: String):
	var chip := Control.new()
	chip.anchor_left   = 1.0
	chip.anchor_right  = 1.0
	chip.anchor_top    = 0.5
	chip.anchor_bottom = 0.5
	chip.offset_left   = -184.0
	chip.offset_right  = -24.0
	chip.offset_top    = -22.0
	chip.offset_bottom =  22.0
	chip.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.22)
	ThemeTokens._set_radius(sb, 999)
	bg.add_theme_stylebox_override("panel", sb)
	chip.add_child(bg)

	var lbl := Label.new()
	lbl.text = chip_text
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _inter(800, 4))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(lbl)

	btn.add_child(chip)

# ─── Settings cog ─────────────────────────────────────────────

func _add_settings_cog():
	var cog := Button.new()
	cog.text = "⚙"
	cog.custom_minimum_size = Vector2(80, 80)
	cog.anchor_left   = 1.0
	cog.anchor_right  = 1.0
	cog.anchor_top    = 0.0
	cog.anchor_bottom = 0.0
	cog.offset_left   = -116
	cog.offset_right  =  -36
	cog.offset_top    =   36
	cog.offset_bottom =  116
	cog.add_theme_font_size_override("font_size", 32)
	cog.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	var sb := ThemeTokens.sb_menu_button()
	sb.content_margin_top    = 12.0
	sb.content_margin_bottom =  4.0
	cog.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = ThemeTokens.BOARD_BG
	cog.add_theme_stylebox_override("hover",   sb_h)
	cog.add_theme_stylebox_override("pressed", sb_h)
	cog.pressed.connect(_on_btn_settings_pressed)
	add_child(cog)

# ─── Version label ────────────────────────────────────────────

func _build_version_label() -> Label:
	var ver := Label.new()
	ver.text = "v0.9"
	ver.add_theme_font_override("font", ThemeTokens.font_mono(400))
	ver.add_theme_font_size_override("font_size", 20)
	ver.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return ver

# ─── Floating background tiles ────────────────────────────────

func _add_floating_bg():
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	move_child(layer, 1)  # after Background[0], before MarginContainer

	# Plain number tiles  [x%, y%, glyph, rot°, opacity, size]
	var nums := [
		[0.06, 0.08, "3",  -8, 0.22, 96],
		[0.02, 0.44, "5",   4, 0.18, 88],
		[0.07, 0.76, "6",  10, 0.16, 80],
		[0.70, 0.84, "1",  -4, 0.18, 84],
		[0.32, 0.03, "4",  -3, 0.12, 52],
		[0.56, 0.66, "4",  -8, 0.12, 52],
	]
	for d in nums:
		layer.add_child(_make_float_tile(d[0], d[1], d[2], d[3], d[4], d[5],
			ThemeTokens.TILE_WHITE, ThemeTokens.TEXT))

	# Special tiles  [x%, y%, glyph, rot°, opacity, size, bg, text_color]
	var specials := [
		[0.78, 0.06, "♠",   6, 0.55, 84, Color("ffe6a8"), Color("5a3712")],
		[0.86, 0.28, "-3", -12, 0.45, 72, ThemeTokens.NEG_BG,     ThemeTokens.NEG_DARK],
		[0.82, 0.56, "4",  -6, 0.50, 92, ThemeTokens.VIRUS_BG,   ThemeTokens.VIRUS_TEXT],
		[0.03, 0.62, "?",   8, 0.40, 76, ThemeTokens.MYSTERY_BG, ThemeTokens.MYSTERY_TEXT],
		[0.26, 0.87, "♠", -10, 0.40, 64, Color("ffe6a8"), Color("5a3712")],
		[0.62, 0.36, "",    4, 0.45, 56, ThemeTokens.MINT_SOFT,  Color.WHITE],
	]
	for d in specials:
		layer.add_child(_make_float_tile(d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7]))

	# Sparkle dots  [x%, y%, color, diameter]
	var dots := [
		[0.36, 0.22, Color("ffe6a8"),       8.0],
		[0.64, 0.16, ThemeTokens.MINT_DARK, 6.0],
		[0.74, 0.44, ThemeTokens.MINT_DARK, 8.0],
		[0.44, 0.80, ThemeTokens.MINT_DARK, 6.0],
		[0.08, 0.32, Color("ffe6a8"),       6.0],
		[0.90, 0.76, Color("ffe6a8"),       6.0],
	]
	for d in dots:
		var dot := ColorRect.new()
		dot.anchor_left   = d[0]; dot.anchor_right  = d[0]
		dot.anchor_top    = d[1]; dot.anchor_bottom  = d[1]
		var hs: float = d[3] * 0.5
		dot.offset_left = -hs; dot.offset_right  = hs
		dot.offset_top  = -hs; dot.offset_bottom = hs
		var c: Color = d[2]
		dot.color = Color(c.r, c.g, c.b, 0.55)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(dot)

func _make_float_tile(px: float, py: float, val: String, rot_deg: int,
		opacity: float, sz: int, bg: Color, tc: Color) -> Control:
	var c := Control.new()
	c.anchor_left = px;  c.anchor_right  = px
	c.anchor_top  = py;  c.anchor_bottom = py
	var hs: float = sz * 0.5
	c.offset_left = -hs; c.offset_right  = hs
	c.offset_top  = -hs; c.offset_bottom = hs
	c.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	c.modulate      = Color(1.0, 1.0, 1.0, opacity)
	c.pivot_offset  = Vector2(hs, hs)
	c.rotation      = deg_to_rad(rot_deg)

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	ThemeTokens._set_radius(sb, int(sz * 0.18))
	sb.border_width_bottom = 1
	sb.border_color = Color(bg.r * 0.75, bg.g * 0.75, bg.b * 0.75, 0.4)
	panel.add_theme_stylebox_override("panel", sb)
	c.add_child(panel)

	if val != "":
		var lbl := Label.new()
		lbl.text = val
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", int(sz * 0.44))
		lbl.add_theme_color_override("font_color", tc)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(lbl)

	return c

# ─── Settings panel ───────────────────────────────────────────

func _build_settings_panel():
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 4
	add_child(_settings_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_layer.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   60)
	margin.add_theme_constant_override("margin_top",    80)
	margin.add_theme_constant_override("margin_right",  60)
	margin.add_theme_constant_override("margin_bottom", 80)
	_settings_layer.add_child(margin)

	var card := Panel.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_theme_stylebox_override("panel", ThemeTokens.sb_card())
	margin.add_child(card)

	var inner_margin := MarginContainer.new()
	inner_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_margin.add_theme_constant_override("margin_left",   48)
	inner_margin.add_theme_constant_override("margin_right",  48)
	inner_margin.add_theme_constant_override("margin_top",    48)
	inner_margin.add_theme_constant_override("margin_bottom", 48)
	card.add_child(inner_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 36)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_margin.add_child(vbox)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_override("font", _inter(800))
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_volume_row("Music", AudioManager.get_bgm_volume(),
		func(v: float): AudioManager.set_bgm_volume(v)))
	vbox.add_child(_make_volume_row("SFX", AudioManager.get_sfx_volume(),
		func(v: float): AudioManager.set_sfx_volume(v)))

	vbox.add_child(HSeparator.new())

	var btn_back := Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(0, 88)
	btn_back.add_theme_font_override("font", _inter(600))
	btn_back.add_theme_font_size_override("font_size", 30)
	btn_back.add_theme_color_override("font_color", ThemeTokens.TEXT)
	var sb_bb := ThemeTokens.sb_menu_button()
	btn_back.add_theme_stylebox_override("normal", sb_bb)
	var sb_bbh := sb_bb.duplicate() as StyleBoxFlat
	sb_bbh.bg_color = ThemeTokens.BOARD_BG
	btn_back.add_theme_stylebox_override("hover",   sb_bbh)
	btn_back.add_theme_stylebox_override("pressed", sb_bbh)
	btn_back.pressed.connect(func(): _settings_layer.hide())
	vbox.add_child(btn_back)

func _make_volume_row(label_text: String, initial: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_override("font", _inter(600))
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	lbl.custom_minimum_size = Vector2(110, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 44)
	row.add_child(slider)

	var pct := Label.new()
	pct.text = "%d%%" % int(initial * 100)
	pct.add_theme_font_override("font", ThemeTokens.font_mono(400))
	pct.add_theme_font_size_override("font_size", 28)
	pct.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	pct.custom_minimum_size = Vector2(70, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pct)

	slider.value_changed.connect(func(v: float):
		on_change.call(v)
		pct.text = "%d%%" % int(v * 100)
	)
	return row
