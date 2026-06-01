extends Control

var _pending_mode := ""

@onready var save_sub_menu := $SaveSubMenu
@onready var save_title    := $SaveSubMenu/OuterMargin/InnerBox/Title
@onready var save_info     := $SaveSubMenu/OuterMargin/InnerBox/LblInfo

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
	save_title.text = "Resume " + mode_name.capitalize() + "?"
	var preview := Global.get_save_preview(mode_name)
	var t := int(preview.get("time", 0))
	save_info.text = "Score: %d  |  Time: %02d:%02d" % [preview.get("score", 0), t / 60, t % 60]
	save_sub_menu.show()

func _go_to_game(load: bool):
	Global.load_save = load
	Global.last_played_mode = Global.selected_mode
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
	$SaveSubMenu/DimBg.color = ThemeTokens.DIM_BG

	# Card background behind the content
	var card := Panel.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", ThemeTokens.sb_card())
	$SaveSubMenu/OuterMargin.add_child(card)
	$SaveSubMenu/OuterMargin.move_child(card, 0)

	save_title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	save_title.add_theme_font_size_override("font_size", 50)
	save_title.add_theme_color_override("font_color", ThemeTokens.TEXT)

	save_info.add_theme_font_override("font", ThemeTokens.font_mono(400))
	save_info.add_theme_font_size_override("font_size", 26)
	save_info.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)

	var inner_box := $SaveSubMenu/OuterMargin/InnerBox
	for btn_name in ["BtnContinue", "BtnNewGame", "BtnCancel"]:
		var btn := inner_box.get_node(btn_name) as Button
		btn.custom_minimum_size = Vector2(0, 88)
		btn.add_theme_font_override("font", ThemeTokens.font_inter(600))
		btn.add_theme_font_size_override("font_size", 34)
		btn.add_theme_color_override("font_color", ThemeTokens.TEXT)
		var sb := ThemeTokens.sb_menu_button()
		btn.add_theme_stylebox_override("normal", sb)
		var sb_h := sb.duplicate() as StyleBoxFlat
		sb_h.bg_color = ThemeTokens.BOARD_BG
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_h)
