extends Control

var _pending_mode := ""

@onready var save_sub_menu := $SaveSubMenu

# Refs set in _style_save_submenu — updated in _show_save_menu
var _sm_mode_lbl:  Label = null
var _sm_score_lbl: Label = null
var _sm_time_lbl:  Label = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	save_sub_menu.hide()
	_apply_theme()

# ─── Navigation ───────────────────────────────────────────────

func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if save_sub_menu.visible:
			_on_btn_cancel_pressed()
		else:
			_on_btn_back_pressed()

func _start_mode(mode_name: String):
	Global.selected_mode = mode_name
	if Global.has_save(mode_name):
		_show_save_menu(mode_name)
	else:
		_go_to_game(false)

func _show_save_menu(mode_name: String):
	_pending_mode = mode_name
	var preview := Global.get_save_preview(mode_name)
	var t := int(preview.get("time", 0))
	if _sm_mode_lbl:
		_sm_mode_lbl.text = mode_name.capitalize()
	if _sm_score_lbl:
		_sm_score_lbl.text = str(int(preview.get("score", 0)))
	if _sm_time_lbl:
		_sm_time_lbl.text = "%02d:%02d" % [t / 60, t % 60]
	save_sub_menu.show()

func _go_to_game(load: bool):
	Global.load_save = load
	Global.last_played_mode = Global.selected_mode
	Global.save_config()
	get_tree().change_scene_to_file("res://main.tscn")

func _on_btn_continue_pressed():
	save_sub_menu.hide()
	_go_to_game(true)

func _on_btn_new_game_pressed():
	save_sub_menu.hide()
	Global.delete_save(_pending_mode)
	_go_to_game(false)

func _on_btn_cancel_pressed():
	save_sub_menu.hide()
	_pending_mode = ""

func _on_btn_classic_pressed():   _start_mode("CLASSIC")
func _on_btn_zen_pressed():       _start_mode("ZEN")
func _on_btn_gravity_pressed():   _start_mode("GRAVITY")
func _on_btn_mutation_pressed():  _start_mode("MUTATION")
func _on_btn_challenge_pressed(): _start_mode("CHALLENGE")

# ─── Theme ────────────────────────────────────────────────────

func _apply_theme():
	$Background.color = ThemeTokens.APP_BG

	var mc := $MarginContainer
	mc.add_theme_constant_override("margin_left",   44)
	mc.add_theme_constant_override("margin_right",  44)
	mc.add_theme_constant_override("margin_top",    40)
	mc.add_theme_constant_override("margin_bottom", 56)

	$MarginContainer/MainLayout.add_theme_constant_override("separation", 20)

	_style_top_bar()
	$MarginContainer/MainLayout/HSep.hide()
	_insert_heading()
	_build_mode_cards()
	_style_save_submenu()

func _style_top_bar():
	var top_bar := $MarginContainer/MainLayout/TopBar
	top_bar.add_theme_constant_override("separation", 0)

	# Back button — icon style
	var btn_back := $MarginContainer/MainLayout/TopBar/BtnBack
	btn_back.text = "←"
	btn_back.custom_minimum_size = Vector2(80, 80)
	btn_back.add_theme_font_size_override("font_size", 44)
	btn_back.add_theme_color_override("font_color", ThemeTokens.TEXT)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb_back := ThemeTokens.sb_menu_button()
	btn_back.add_theme_stylebox_override("normal", sb_back)
	var sb_bh := sb_back.duplicate() as StyleBoxFlat
	sb_bh.bg_color = ThemeTokens.BOARD_BG
	btn_back.add_theme_stylebox_override("hover", sb_bh)
	btn_back.add_theme_stylebox_override("pressed", sb_bh)

	# Hide old page title
	$MarginContainer/MainLayout/TopBar/PageTitle.hide()

	# Mini logo (centered)
	var logo_center := CenterContainer.new()
	logo_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo_center.add_child(_build_mini_logo())
	top_bar.add_child(logo_center)

	# Right spacer to balance back button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(80, 0)
	spacer.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_bar.add_child(spacer)

func _build_mini_logo() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	var trace := Label.new()
	trace.text = "trace"
	trace.add_theme_font_override("font", ThemeTokens.font_inter(700))
	trace.add_theme_font_size_override("font_size", 32)
	trace.add_theme_color_override("font_color", ThemeTokens.TEXT)
	trace.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(trace)

	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(44, 44)
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(sb, 10)
	tile.add_theme_stylebox_override("panel", sb)

	var n10 := Label.new()
	n10.text = "10"
	n10.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n10.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n10.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n10.add_theme_font_override("font", ThemeTokens.font_mono(800))
	n10.add_theme_font_size_override("font_size", 22)
	n10.add_theme_color_override("font_color", Color.WHITE)
	tile.add_child(n10)
	row.add_child(tile)

	return row

func _insert_heading():
	var layout := $MarginContainer/MainLayout

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)

	var cap_font := ThemeTokens.font_inter(600)
	cap_font.spacing_glyph = 6
	var cap := Label.new()
	cap.text = "CHOOSE A MODE"
	cap.add_theme_font_override("font", cap_font)
	cap.add_theme_font_size_override("font_size", 22)
	cap.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vb.add_child(cap)

	var heading := Label.new()
	heading.text = "5 ways to play"
	heading.add_theme_font_override("font", ThemeTokens.font_inter(800))
	heading.add_theme_font_size_override("font_size", 44)
	heading.add_theme_color_override("font_color", ThemeTokens.TEXT)
	heading.add_theme_color_override("font_outline_color", ThemeTokens.TEXT)
	heading.add_theme_constant_override("outline_size", 2)
	vb.add_child(heading)

	layout.add_child(vb)
	layout.move_child(vb, 2)  # TopBar[0], HSep[1], heading[2], Modes[3]

func _build_mode_cards():
	var modes_vbox := $MarginContainer/MainLayout/Modes
	modes_vbox.add_theme_constant_override("separation", 16)

	for child in modes_vbox.get_children():
		child.queue_free()

	var hs := Global.load_highscore()

	var modes := [
		{name="Classic",   tag="Beat the clock",          accent=Color("c8923a"), chip_bg=Color("fde8c4"), icon="⌛", key="CLASSIC",   cb=_on_btn_classic_pressed},
		{name="Gravity",   tag="Tiles fall, lives count", accent=Color("5179c8"), chip_bg=Color("d5e0f3"), icon="🍎", key="GRAVITY",   cb=_on_btn_gravity_pressed},
		{name="Zen",       tag="No timer, just play",     accent=Color("6aa68a"), chip_bg=Color("dceee2"), icon="☯",  key="ZEN",       cb=_on_btn_zen_pressed},
		{name="Adventure", tag="Curated levels, ranked",  accent=Color("d4763a"), chip_bg=Color("fadbc4"), icon="⛰",  key="CHALLENGE", cb=_on_btn_challenge_pressed},
		{name="Mutation",  tag="Tiles change every turn", accent=Color("7d4a9c"), chip_bg=Color("e5d4ee"), icon="🧠", key="MUTATION",  cb=_on_btn_mutation_pressed},
	]

	for m in modes:
		var best := _get_best_str(hs, m.key)
		var card := _build_hero_card(m.name, m.tag, m.accent, m.chip_bg, m.icon, m.cb, best)
		modes_vbox.add_child(card)

func _get_best_str(hs: Dictionary, mode: String) -> String:
	var entries: Array = hs.get(mode, [])
	if entries.is_empty(): return ""
	var score := int(entries[0].get("score", 0))
	return "%d" % score if score > 0 else ""

func _build_hero_card(
		mode_name: String, tag: String,
		accent: Color, chip_bg: Color,
		icon: String, on_press: Callable,
		best_str: String
) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ThemeTokens.sb_card())
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Single content child
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 28)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	# Icon chip
	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(116, 116)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_icon := StyleBoxFlat.new()
	sb_icon.bg_color = chip_bg
	ThemeTokens._set_radius(sb_icon, 32)
	icon_panel.add_theme_stylebox_override("panel", sb_icon)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_panel.add_child(icon_lbl)
	hbox.add_child(icon_panel)

	# Text column
	var text_vb := VBoxContainer.new()
	text_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vb.add_theme_constant_override("separation", 6)

	var name_lbl := Label.new()
	name_lbl.text = mode_name
	name_lbl.add_theme_font_override("font", ThemeTokens.font_inter(800))
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	name_lbl.add_theme_color_override("font_outline_color", ThemeTokens.TEXT)
	name_lbl.add_theme_constant_override("outline_size", 2)
	text_vb.add_child(name_lbl)

	var tag_lbl := Label.new()
	tag_lbl.text = tag
	tag_lbl.add_theme_font_override("font", ThemeTokens.font_inter(400))
	tag_lbl.add_theme_font_size_override("font_size", 22)
	tag_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	text_vb.add_child(tag_lbl)

	hbox.add_child(text_vb)

	# BEST column — score on top, "BEST" label below, right-aligned before chevron
	if best_str != "":
		var best_col := VBoxContainer.new()
		best_col.alignment = BoxContainer.ALIGNMENT_CENTER
		best_col.add_theme_constant_override("separation", 2)
		best_col.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var score_lbl := Label.new()
		score_lbl.text = best_str
		score_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
		score_lbl.add_theme_font_size_override("font_size", 26)
		score_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		best_col.add_child(score_lbl)

		var best_lbl := Label.new()
		best_lbl.text = "BEST"
		best_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
		best_lbl.add_theme_font_size_override("font_size", 16)
		best_lbl.add_theme_color_override("font_color", accent)
		best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		best_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		best_col.add_child(best_lbl)

		hbox.add_child(best_col)

	# Chevron
	var chevron := Label.new()
	chevron.text = "›"
	chevron.add_theme_font_size_override("font_size", 64)
	chevron.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(chevron)

	# Click handling via gui_input on the PanelContainer
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton \
				and event.button_index == MOUSE_BUTTON_LEFT \
				and event.pressed:
			on_press.call()
	)

	return card

func _style_save_submenu():
	# Dim backdrop
	var dim := $SaveSubMenu/DimBg as ColorRect
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.11, 0.125, 0.118, 0.50)

	# Grab button nodes (signals already connected in .tscn)
	var inner_box := $SaveSubMenu/OuterMargin/InnerBox
	var btn_c := inner_box.get_node("BtnContinue") as Button
	var btn_n := inner_box.get_node("BtnNewGame")  as Button
	var btn_x := inner_box.get_node("BtnCancel")   as Button
	for b in [btn_c, btn_n, btn_x]:
		inner_box.remove_child(b)
	# Free OuterMargin (and remaining InnerBox + placeholder nodes)
	$SaveSubMenu/OuterMargin.queue_free()

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$SaveSubMenu.add_child(center)

	# Card — PanelContainer auto-fills its child
	var sw := get_viewport_rect().size.x
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 800)
	var sb_c := ThemeTokens.sb_card()
	sb_c.shadow_color = Color(0, 0, 0, 0.45)
	sb_c.shadow_size = 28; sb_c.shadow_offset = Vector2(0, 10)
	card.add_theme_stylebox_override("panel", sb_c)
	center.add_child(card)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 36)
	mc.add_theme_constant_override("margin_right", 36)
	mc.add_theme_constant_override("margin_top", 36)
	mc.add_theme_constant_override("margin_bottom", 36)
	card.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	mc.add_child(vbox)

	# Resume icon chip
	var ic := CenterContainer.new()
	vbox.add_child(ic)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(88, 88)
	var sb_chip := StyleBoxFlat.new()
	sb_chip.bg_color = Color("cde9da")
	ThemeTokens._set_radius(sb_chip, 26)
	sb_chip.border_width_left = 2; sb_chip.border_width_right = 2
	sb_chip.border_width_top = 2; sb_chip.border_width_bottom = 2
	sb_chip.border_color = Color(ThemeTokens.MINT_DARK, 0.27)
	chip.add_theme_stylebox_override("panel", sb_chip)
	ic.add_child(chip)
	var icon_lbl := Label.new()
	icon_lbl.text = "▶"
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 42)
	icon_lbl.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)
	chip.add_child(icon_lbl)

	var g1 := Control.new(); g1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(g1)

	# Kicker + mode name
	var kicker := Label.new()
	kicker.text = "SAVED GAME"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kf := ThemeTokens.font_inter(700); kf.spacing_glyph = 7
	kicker.add_theme_font_override("font", kf)
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(kicker)

	var g2 := Control.new(); g2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(g2)

	_sm_mode_lbl = Label.new()
	_sm_mode_lbl.text = "—"
	_sm_mode_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sm_mode_lbl.add_theme_font_override("font", ThemeTokens.font_inter(800))
	_sm_mode_lbl.add_theme_font_size_override("font_size", 40)
	_sm_mode_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vbox.add_child(_sm_mode_lbl)

	# Divider
	var g3 := Control.new(); g3.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(g3)
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color("e3d8c0")
	vbox.add_child(div)
	var g4 := Control.new(); g4.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(g4)

	# Stats row: SCORE + TIME PLAYED
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	vbox.add_child(stats_row)

	var score_cell := _make_sm_stat_cell("—", "SCORE")
	_sm_score_lbl = score_cell.get_meta("val_lbl") as Label
	stats_row.add_child(score_cell)

	var time_cell := _make_sm_stat_cell("—", "TIME PLAYED")
	_sm_time_lbl = time_cell.get_meta("val_lbl") as Label
	stats_row.add_child(time_cell)

	var g5 := Control.new(); g5.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(g5)

	# Buttons
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_vbox)

	_style_sm_btn_primary(btn_c, "CONTINUE")
	_style_sm_btn_secondary(btn_n, "NEW GAME")
	_style_sm_btn_ghost(btn_x, "CANCEL")
	btn_vbox.add_child(btn_c)
	btn_vbox.add_child(btn_n)
	btn_vbox.add_child(btn_x)

func _make_sm_stat_cell(value_text: String, label_text: String) -> Panel:
	var cell := Panel.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 110)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe7d5")
	ThemeTokens._set_radius(sb, 12)
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_color = Color("e3d8c0")
	cell.add_theme_stylebox_override("panel", sb)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_top", 11)
	mc.add_theme_constant_override("margin_bottom", 11)
	mc.add_theme_constant_override("margin_left", 8)
	mc.add_theme_constant_override("margin_right", 8)
	cell.add_child(mc)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	mc.add_child(vb)
	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	val_lbl.add_theme_font_size_override("font_size", 30)
	val_lbl.add_theme_color_override("font_color", Color("2f3a36"))
	vb.add_child(val_lbl)
	var sub_f := ThemeTokens.font_inter(700); sub_f.spacing_glyph = 5
	var sub_lbl := Label.new()
	sub_lbl.text = label_text
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", sub_f)
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color("8a9590"))
	vb.add_child(sub_lbl)
	cell.set_meta("val_lbl", val_lbl)
	return cell

func _style_sm_btn_primary(btn: Button, label: String) -> void:
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 76)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := ThemeTokens.font_inter(700); f.spacing_glyph = 4
	btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(sb, 16)
	sb.shadow_color = Color(ThemeTokens.MINT_DARK, 0.53)
	sb.shadow_size = 6; sb.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = ThemeTokens.MINT_DARK
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)

func _style_sm_btn_secondary(btn: Button, label: String) -> void:
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 70)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := ThemeTokens.font_inter(700); f.spacing_glyph = 3
	btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", ThemeTokens.TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe7d5")
	ThemeTokens._set_radius(sb, 16)
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_color = Color("e3d8c0")
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color("dfd6c5")
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)

func _style_sm_btn_ghost(btn: Button, label: String) -> void:
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := ThemeTokens.font_inter(700); f.spacing_glyph = 5
	btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0, 0, 0, 0)
	ThemeTokens._set_radius(sb, 14)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
