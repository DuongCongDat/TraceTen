extends Control

const CATEGORIES = [
	{"label": "Beginner",      "ids": ["first_ten", "first_powerup", "all_modes", "first_combo", "first_special"]},
	{"label": "Score",         "ids": ["score_100", "score_500", "score_1000"]},
	{"label": "Combo",         "ids": ["combo_5", "combo_10", "combo_classic"]},
	{"label": "Mode",          "ids": ["classic_survive", "gravity_lv4", "gravity_3lives", "zen_refill3", "challenge_l6", "challenge_l12", "mutation_alltype"]},
	{"label": "Special Tiles", "ids": ["virus_cleared", "joker_used", "negative_win"]},
	{"label": "Quirky",        "ids": ["big_selection", "no_hint", "cancel_remove", "virus_explode"]},
]

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_theme()
	_build_ui()


func _apply_theme():
	# Background
	var bg := ColorRect.new()
	bg.color = ThemeTokens.APP_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)
	move_child(bg, 0)

	# Title
	var title = $MarginContainer/Layout/Title
	title.text = "ACHIEVEMENTS"
	title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)

	# Back button
	var btn = $MarginContainer/Layout/BtnBack
	btn.text = "Back"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	ThemeTokens._set_radius(sb, 14)
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_font_override("font", ThemeTokens.font_inter(700))
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)


func _build_ui():
	var list = $MarginContainer/Layout/Scroll/List
	var data = Global._achievements

	for cat in CATEGORIES:
		list.add_child(_make_header(cat["label"]))
		for id in cat["ids"]:
			var def     = AchievementData.get_def(id)
			var entry   = data.get(id, {"unlocked": false, "progress": 0})
			var unlocked: bool = entry.get("unlocked", false)
			var progress: int  = int(entry.get("progress", 0))
			list.add_child(_make_row(def, unlocked, progress))
		list.add_child(_make_spacer(6))


func _make_header(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)
	lbl.custom_minimum_size.y = 36
	return lbl


func _make_row(def: Dictionary, unlocked: bool, progress: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb, 12)
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.border_color = Color(ThemeTokens.BOARD_INSET.r, ThemeTokens.BOARD_INSET.g, ThemeTokens.BOARD_INSET.b, 0.5)
	panel.add_theme_stylebox_override("panel", sb)
	if not unlocked:
		panel.modulate = Color(1, 1, 1, 0.55)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",  14)
	mc.add_theme_constant_override("margin_right", 14)
	mc.add_theme_constant_override("margin_top",   10)
	mc.add_theme_constant_override("margin_bottom",10)
	panel.add_child(mc)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	mc.add_child(hbox)

	# Icon
	var icon := Label.new()
	icon.text = "★" if unlocked else "○"
	icon.add_theme_font_size_override("font_size", 26)
	icon.add_theme_color_override("font_color", ThemeTokens.MINT_DARK if unlocked else ThemeTokens.SUB_TEXT)
	icon.custom_minimum_size.x = 32
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Name + desc
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = def.get("name", "?")
	name_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700 if unlocked else 500))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT if unlocked else ThemeTokens.SUB_TEXT)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = def.get("desc", "")
	desc_lbl.add_theme_font_override("font", ThemeTokens.font_inter(400))
	desc_lbl.add_theme_font_size_override("font_size", 17)
	desc_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Progress (right, only if target > 1)
	var target: int = def.get("target", 1)
	if target > 1:
		var prog := Label.new()
		prog.text = "Done" if unlocked else "%d / %d" % [min(progress, target), target]
		prog.add_theme_font_override("font", ThemeTokens.font_mono(700))
		prog.add_theme_font_size_override("font_size", 19)
		prog.add_theme_color_override("font_color", ThemeTokens.MINT_DARK if unlocked else ThemeTokens.SUB_TEXT)
		prog.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		prog.custom_minimum_size.x = 75
		hbox.add_child(prog)

	return panel


func _make_spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size.y = height
	return s


func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_btn_back_pressed()
