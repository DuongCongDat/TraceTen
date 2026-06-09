extends Control

# ─── Inner class: dashed border rect (mechanic ghost) ────────
class _DashedRect extends Control:
	var border_color := Color(0.306, 0.647, 0.518, 0.30)
	var border_width  := 1.5
	var corner_radius := 6.0
	func _draw() -> void:
		var r  := Rect2(Vector2.ZERO, size)
		var c  := border_color
		var bw := border_width
		var cr := corner_radius
		draw_dashed_line(r.position + Vector2(cr,0), Vector2(r.end.x-cr, r.position.y), c, bw, 8, true)
		draw_dashed_line(Vector2(r.end.x, r.position.y+cr), Vector2(r.end.x, r.end.y-cr), c, bw, 8, true)
		draw_dashed_line(Vector2(r.end.x-cr, r.end.y), Vector2(r.position.x+cr, r.end.y), c, bw, 8, true)
		draw_dashed_line(Vector2(r.position.x, r.end.y-cr), Vector2(r.position.x, r.position.y+cr), c, bw, 8, true)

var _settings_layer: CanvasLayer = null
var _tint_shader: Shader = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioManager.play_bgm("MENU")
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
	$Background.color = ThemeTokens.PHONE_BG

	_add_floating_bg()

	var mc := $MarginContainer
	mc.add_theme_constant_override("margin_left",   52)
	mc.add_theme_constant_override("margin_right",  52)
	mc.add_theme_constant_override("margin_top",    44)
	mc.add_theme_constant_override("margin_bottom", 48)

	var layout := $MarginContainer/MainLayout
	layout.add_theme_constant_override("separation", 16)

	$MarginContainer/MainLayout/Title.hide()

	# Spacer fixed → logo position locked regardless of MidGap
	var spacer := $MarginContainer/MainLayout/Spacer
	spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	spacer.custom_minimum_size = Vector2(0, 150)

	var logo := _build_logo_block()
	layout.add_child(logo)
	layout.move_child(logo, 2)  # Title[0], Spacer[1], Logo[2], Buttons[3]

	# MidGap: đổi số này để di chuyển khối buttons lên/xuống
	var mid_gap := Control.new()
	mid_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_gap.size_flags_stretch_ratio = 2
	layout.add_child(mid_gap)
	layout.move_child(mid_gap, 3)  # Logo[2], MidGap[3], Buttons[4]

	_style_nav_buttons()
	$MarginContainer/MainLayout/Buttons/BtnSettings.hide()

	# spacer2: đổi stretch_ratio để di chuyển khối buttons lên/xuống
	# mid_gap(trên) vs spacer2(dưới) tranh nhau space
	# spacer2 lớn hơn = buttons lên cao; mid_gap lớn hơn = buttons xuống thấp
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
	lbl_trace.add_theme_font_size_override("font_size", 91)
	lbl_trace.add_theme_color_override("font_color", ThemeTokens.TEXT)
	lbl_trace.add_theme_color_override("font_outline_color", ThemeTokens.TEXT)
	lbl_trace.add_theme_constant_override("outline_size", 2)
	lbl_trace.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl_trace)

	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(125, 125)
	var sb_tile := StyleBoxFlat.new()
	sb_tile.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(sb_tile, 26)
	sb_tile.border_width_bottom = 10
	sb_tile.border_color = ThemeTokens.MINT_DARK
	tile.add_theme_stylebox_override("panel", sb_tile)

	var lbl_10 := Label.new()
	lbl_10.text = "10"
	lbl_10.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl_10.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_10.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_10.add_theme_font_override("font", ThemeTokens.font_mono(800))
	lbl_10.add_theme_font_size_override("font_size", 58)
	lbl_10.add_theme_color_override("font_color", Color.WHITE)
	lbl_10.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.18))
	lbl_10.add_theme_constant_override("outline_size", 2)
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
	var sb_modes := StyleBoxFlat.new()
	sb_modes.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb_modes, ThemeTokens.CHIP_RADIUS)
	sb_modes.border_width_left   = 1
	sb_modes.border_width_right  = 1
	sb_modes.border_width_top    = 1
	sb_modes.border_width_bottom = 3
	sb_modes.border_color = ThemeTokens.BOARD_INSET
	btn_modes.add_theme_stylebox_override("normal", sb_modes)
	var sb_modes_h := sb_modes.duplicate() as StyleBoxFlat
	sb_modes_h.bg_color = ThemeTokens.BOARD_BG
	btn_modes.add_theme_stylebox_override("hover",   sb_modes_h)
	btn_modes.add_theme_stylebox_override("pressed", sb_modes_h)
	btn_modes.pressed.connect(func(): get_tree().change_scene_to_file("res://mode_select.tscn"))

	# ── Hide old secondary buttons ───────────────────────────────
	$MarginContainer/MainLayout/Buttons/BtnHighscore.hide()
	$MarginContainer/MainLayout/Buttons/BtnAchievements.hide()
	$MarginContainer/MainLayout/Buttons/BtnHelp.hide()
	$MarginContainer/MainLayout/Buttons/BtnQuit.hide()

	# ── Icon row: SCORES / AWARDS / HOW TO ───────────────────────
	var icon_gap := Control.new()
	icon_gap.custom_minimum_size = Vector2(0, 12)
	btns.add_child(icon_gap)

	var ach_count := "%d/25" % Global.count_unlocked()
	var icon_row := HBoxContainer.new()
	icon_row.add_theme_constant_override("separation", 0)
	icon_row.add_child(_make_nav_icon_tile(
		"res://assets/ui/icons/icon_score.png",  "SCORES",  Color("c8923a"), "",
		func(): get_tree().change_scene_to_file("res://highscore.tscn")))
	icon_row.add_child(_make_nav_icon_tile(
		"res://assets/ui/icons/icon_awards.png", "AWARDS",  Color("4ea584"), ach_count,
		func(): get_tree().change_scene_to_file("res://achievement_screen.tscn")))
	icon_row.add_child(_make_nav_icon_tile(
		"res://assets/ui/icons/icon_howto.png",  "HOW TO",  Color("4a78c8"), "",
		func(): get_tree().change_scene_to_file("res://tutorial.tscn")))
	btns.add_child(icon_row)

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
	lbl.add_theme_color_override("font_outline_color", ThemeTokens.MINT_DARK)
	lbl.add_theme_constant_override("outline_size", 2)
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

# ─── Floating background (6 layers + bob animation) ──────────

func _add_floating_bg() -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	move_child(layer, 1)

	var bob_list: Array = []  # [[node, amp, dur, delay], ...]

	# ── Layer 1: radial glow blobs ─────────────────────────────
	_add_glow_blob(layer, -0.12, 0.28, 440, Color(0.498, 0.784, 0.663, 0.19))  # mint
	_add_glow_blob(layer,  1.15, 0.68, 480, Color(0.914, 0.620, 0.620, 0.19))  # rose
	_add_glow_blob(layer,  0.40, -0.10, 360, Color(1.0, 0.902, 0.659, 0.19))   # amber

	# ── Layer 2: large number tiles ────────────────────────────
	for d: Array in [
		[0.06, 0.08, "3", -8, 0.22, 96],
		[0.02, 0.42, "5",  4, 0.22, 88],
		[0.06, 0.76, "6", 10, 0.20, 80],
		[0.70, 0.82, "1", -4, 0.22, 84],
	]:
		var n := _make_float_tile(d[0],d[1],d[2],d[3],d[4],d[5], ThemeTokens.TILE_WHITE, ThemeTokens.TEXT)
		layer.add_child(n)
		bob_list.append([n, randf_range(6,10), randf_range(4.0,6.0), randf_range(0,2.0)])

	# ── Layer 3: special tile cameos ───────────────────────────
	for d: Array in [
		[0.78, 0.06, "♠",   6, 0.55, 84, Color("ffe6a8"), Color("5a3712")],
		[0.86, 0.28, "-3", -12, 0.50, 72, Color("f5c4c4"), Color("c46a6a")],
		[0.82, 0.56, "4",   -6, 0.55, 92, Color("c7dab2"), Color("3d5a3d")],
		[0.03, 0.62, "?",    8, 0.45, 76, Color("3d4a44"), Color("cde9da")],
		[0.62, 0.36, "",     4, 0.55, 64, ThemeTokens.MINT,      Color.WHITE],
		[0.26, 0.86, "♠",  -10, 0.45, 64, Color("ffe6a8"), Color("5a3712")],
		[0.48, 0.92, "",     6, 0.50, 56, ThemeTokens.MINT,      Color.WHITE],
	]:
		var n := _make_float_tile(d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7])
		layer.add_child(n)
		bob_list.append([n, randf_range(6,10), randf_range(4.0,6.0), randf_range(0,2.0)])

	# ── Layer 4: mid-size number tiles ─────────────────────────
	for d: Array in [
		[0.32, 0.03, "4", -3, 0.14, 52],
		[0.20, 0.28, "1",  5, 0.14, 48],
		[0.50, 0.36, "6", -2, 0.12, 48],
		[0.32, 0.58, "2",  7, 0.16, 56],
		[0.56, 0.66, "4", -8, 0.14, 52],
	]:
		var n := _make_float_tile(d[0],d[1],d[2],d[3],d[4],d[5], ThemeTokens.TILE_WHITE, ThemeTokens.TEXT)
		layer.add_child(n)
		bob_list.append([n, randf_range(5,8), randf_range(4.0,5.5), randf_range(0,2.0)])

	# ── Layer 5: mechanic ghosts ───────────────────────────────
	# 5a: dashed selection rect — 90dp×44dp → 180×88px
	var g_sel := _DashedRect.new()
	g_sel.anchor_left = 0.14; g_sel.anchor_right  = 0.14
	g_sel.anchor_top  = 0.18; g_sel.anchor_bottom = 0.18
	g_sel.offset_left = 0;    g_sel.offset_right  = 180
	g_sel.offset_top  = 0;    g_sel.offset_bottom =  88
	g_sel.pivot_offset = Vector2(90, 44)
	g_sel.rotation    = deg_to_rad(-4)
	g_sel.modulate    = Color(1,1,1,1)
	g_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(g_sel)
	bob_list.append([g_sel, randf_range(6,8), randf_range(4.0,5.0), randf_range(0,2.0)])

	# 5b: cleared tile ghost — 30dp → 60px
	var g_clr := Panel.new()
	g_clr.anchor_left = 0.20; g_clr.anchor_right  = 0.20
	g_clr.anchor_top  = 0.48; g_clr.anchor_bottom = 0.48
	g_clr.offset_left = -30;  g_clr.offset_right  = 30
	g_clr.offset_top  = -30;  g_clr.offset_bottom = 30
	g_clr.pivot_offset = Vector2(30, 30)
	g_clr.rotation    = deg_to_rad(-2)
	g_clr.modulate    = Color(1,1,1,0.55)
	g_clr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_gc := StyleBoxFlat.new()
	sb_gc.bg_color = Color(0,0,0,0)
	ThemeTokens._set_radius(sb_gc, 6)
	sb_gc.border_width_left=2; sb_gc.border_width_right=2
	sb_gc.border_width_top=2;  sb_gc.border_width_bottom=2
	sb_gc.border_color = Color(0.306, 0.647, 0.518, 0.55)
	g_clr.add_theme_stylebox_override("panel", sb_gc)
	var lbl_gc := Label.new()
	lbl_gc.text = "✓"
	lbl_gc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl_gc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_gc.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl_gc.add_theme_font_size_override("font_size", 26)
	lbl_gc.add_theme_color_override("font_color", Color(0.306, 0.647, 0.518))
	lbl_gc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g_clr.add_child(lbl_gc)
	layer.add_child(g_clr)
	bob_list.append([g_clr, randf_range(6,9), randf_range(4.5,5.5), randf_range(0,2.0)])

	# ── Layer 6: sparkle dots ──────────────────────────────────
	var _A := Color("ffe6a8"); var _R := Color("e89e9e"); var _M := ThemeTokens.MINT_DARK
	for d: Array in [
		[0.36,0.22,_A,8.0],[0.64,0.16,_M,6.0],[0.18,0.70,_A,6.0],[0.74,0.44,_M,8.0],
		[0.90,0.76,_A,6.0],[0.44,0.80,_M,6.0],[0.08,0.32,_A,6.0],[0.58,0.50,_R,8.0],
	]:
		var dot := ColorRect.new()
		dot.anchor_left=d[0]; dot.anchor_right=d[0]; dot.anchor_top=d[1]; dot.anchor_bottom=d[1]
		var dhs: float = d[3]*0.5
		dot.offset_left=-dhs; dot.offset_right=dhs; dot.offset_top=-dhs; dot.offset_bottom=dhs
		var dc: Color = d[2]; dot.color = Color(dc.r,dc.g,dc.b,0.60)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(dot)

	# ── Bob animations ─────────────────────────────────────────
	for info: Array in bob_list:
		_bob_node(info[0], info[1], info[2], info[3])


func _add_glow_blob(layer: Control, cx: float, cy: float, diameter_px: float, color: Color) -> void:
	var gtex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = [color, Color(color.r, color.g, color.b, 0.0)]
	grad.offsets = [0.0, 1.0]
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to   = Vector2(1.0, 0.5)
	gtex.width = 256; gtex.height = 256
	var tr := TextureRect.new()
	tr.texture      = gtex
	tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hs := diameter_px * 0.5
	tr.anchor_left = cx; tr.anchor_right  = cx
	tr.anchor_top  = cy; tr.anchor_bottom = cy
	tr.offset_left = -hs; tr.offset_right  = hs
	tr.offset_top  = -hs; tr.offset_bottom = hs
	layer.add_child(tr)


func _bob_node(node: Control, amp: float, dur: float, delay: float) -> void:
	if delay > 0.001:
		await get_tree().create_timer(delay).timeout
	if not is_instance_valid(node): return
	var bt := node.offset_top
	var bb := node.offset_bottom
	var tw := create_tween().set_loops()
	tw.tween_method(func(v: float):
		if not is_instance_valid(node): return
		node.offset_top    = bt + v
		node.offset_bottom = bb + v
	, 0.0, -amp, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float):
		if not is_instance_valid(node): return
		node.offset_top    = bt + v
		node.offset_bottom = bb + v
	, -amp, 0.0, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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

func _get_tint_shader() -> Shader:
	if _tint_shader == null:
		_tint_shader = Shader.new()
		_tint_shader.code = """
shader_type canvas_item;
uniform vec4 tint_color : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(tint_color.rgb, c.a);
}
"""
	return _tint_shader


func _make_nav_icon_tile(
		icon_path: String, label_text: String, accent: Color,
		badge_text: String, on_press: Callable) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Icon chip (tap target)
	var chip := Button.new()
	chip.custom_minimum_size = Vector2(180, 112)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb_chip := StyleBoxFlat.new()
	sb_chip.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb_chip, ThemeTokens.CHIP_RADIUS)
	sb_chip.border_width_left   = 1
	sb_chip.border_width_right  = 1
	sb_chip.border_width_top    = 1
	sb_chip.border_width_bottom = 3
	sb_chip.border_color = ThemeTokens.BOARD_INSET
	chip.add_theme_stylebox_override("normal", sb_chip)
	var sb_ch := sb_chip.duplicate() as StyleBoxFlat
	sb_ch.bg_color = ThemeTokens.BOARD_BG
	chip.add_theme_stylebox_override("hover", sb_ch)
	chip.add_theme_stylebox_override("pressed", sb_ch)
	chip.pressed.connect(on_press)

	# Tinted PNG icon
	var tex := TextureRect.new()
	tex.texture = load(icon_path)
	tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.offset_left = 16; tex.offset_right  = -16
	tex.offset_top  = 12; tex.offset_bottom = -12
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _get_tint_shader()
	mat.set_shader_parameter("tint_color", accent)
	tex.material = mat
	chip.add_child(tex)

	# Badge (achievement count etc.) — Panel bg + Label text
	if badge_text != "":
		var badge_bg := Panel.new()
		# top: -6px; right: -4px — ôm sát góc trên-phải chip
		badge_bg.anchor_left = 1.0; badge_bg.anchor_right  = 1.0
		badge_bg.anchor_top  = 0.0; badge_bg.anchor_bottom = 0.0
		badge_bg.offset_right  =  4   # right: -4px (4px ló ra ngoài)
		badge_bg.offset_top    = -15
		badge_bg.offset_left   = -62  # width = 66px
		badge_bg.offset_bottom =  15
		badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_b := StyleBoxFlat.new()
		sb_b.bg_color = ThemeTokens.MINT_DARK
		ThemeTokens._set_radius(sb_b, 999)
		sb_b.content_margin_left   = 6.0
		sb_b.content_margin_right  = 6.0
		sb_b.content_margin_top    = 3.0
		sb_b.content_margin_bottom = 3.0
		sb_b.shadow_color  = Color(ThemeTokens.MINT_DARK.r, ThemeTokens.MINT_DARK.g, ThemeTokens.MINT_DARK.b, 0.45)
		sb_b.shadow_size   = 3
		sb_b.shadow_offset = Vector2(0, 2)
		badge_bg.add_theme_stylebox_override("panel", sb_b)
		var badge_lbl := Label.new()
		badge_lbl.text = badge_text
		badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
		badge_lbl.add_theme_font_size_override("font_size", 14)
		badge_lbl.add_theme_color_override("font_color", Color.WHITE)
		badge_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
		badge_lbl.add_theme_constant_override("outline_size", 2)
		badge_lbl.add_theme_constant_override("line_spacing", 0)
		badge_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_bg.add_child(badge_lbl)
		chip.clip_contents = false
		chip.add_child(badge_bg)

	# Text label
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _inter(700, 3))
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	lbl.add_theme_color_override("font_outline_color", ThemeTokens.SUB_TEXT)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(chip)
	vb.add_child(lbl)
	return vb


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
