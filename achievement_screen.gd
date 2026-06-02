extends Control

const CATEGORIES = [
	{"label": "Beginner",      "color": Color("#7fc8a9"), "ids": ["first_ten", "first_powerup", "all_modes", "first_combo", "first_special"]},
	{"label": "Score",         "color": Color("#e0a85c"), "ids": ["score_100", "score_500", "score_1000"]},
	{"label": "Combo",         "color": Color("#f08a5d"), "ids": ["combo_5", "combo_10", "combo_classic"]},
	{"label": "Mode",          "color": Color("#5a9fd4"), "ids": ["classic_survive", "gravity_lv4", "gravity_3lives", "zen_refill3", "challenge_l6", "challenge_l12", "mutation_alltype"]},
	{"label": "Special Tiles", "color": Color("#8a7fc8"), "ids": ["virus_cleared", "joker_used", "negative_win"]},
	{"label": "Quirky",        "color": Color("#c97fa8"), "ids": ["big_selection", "no_hint", "cancel_remove", "virus_explode"]},
]

const SECRET_IDS = ["big_selection", "no_hint", "cancel_remove", "virus_explode"]

const ACH_ICONS = {
	"first_ten":      "✓", "first_powerup": "✦", "all_modes":   "◎",
	"first_combo":    "◈", "first_special": "◆",
	"score_100":      "★", "score_500":     "♛", "score_1000":  "◆",
	"combo_5":        "★", "combo_10":      "⚡", "combo_classic":"◈",
	"classic_survive":"⏱", "gravity_lv4":  "✦", "gravity_3lives":"♥",
	"zen_refill3":    "◎", "challenge_l6": "▦", "challenge_l12":"★",
	"mutation_alltype":"◆",
	"virus_cleared":  "♥", "joker_used":   "◆", "negative_win": "⚡",
	"big_selection":  "▦", "no_hint":      "✦", "cancel_remove":"◎",
	"virus_explode":  "◈",
}


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build()


func _build():
	# Background
	var bg := ColorRect.new()
	bg.color = ThemeTokens.APP_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)
	move_child(bg, 0)

	# Compute totals
	var ach_data   = Global._achievements
	var total      := AchievementData.LIST.size()
	var total_unlocked := 0
	for id in ach_data:
		if ach_data[id].get("unlocked", false):
			total_unlocked += 1

	# Tighten margins
	var mc = $MarginContainer
	mc.add_theme_constant_override("margin_left",  16)
	mc.add_theme_constant_override("margin_right", 16)
	mc.add_theme_constant_override("margin_top",   18)
	mc.add_theme_constant_override("margin_bottom",16)

	# Free old layout and rebuild from scratch
	var old_layout = mc.get_node_or_null("Layout")
	if old_layout:
		old_layout.free()

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 12)
	mc.add_child(layout)

	# ── TOP BAR ─────────────────────────────────────────────────
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	layout.add_child(top_bar)

	# Back chip
	var btn_back := Button.new()
	btn_back.text = "‹"
	btn_back.custom_minimum_size = Vector2(38, 38)
	var bb_sb := StyleBoxFlat.new()
	bb_sb.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(bb_sb, 12)
	bb_sb.border_width_left = 1; bb_sb.border_width_right  = 1
	bb_sb.border_width_top  = 1; bb_sb.border_width_bottom = 1
	bb_sb.border_color = ThemeTokens.BOARD_INSET
	btn_back.add_theme_stylebox_override("normal",  bb_sb)
	btn_back.add_theme_stylebox_override("hover",   bb_sb)
	btn_back.add_theme_stylebox_override("pressed", bb_sb)
	btn_back.add_theme_font_override("font", ThemeTokens.font_inter(700))
	btn_back.add_theme_font_size_override("font_size", 20)
	btn_back.add_theme_color_override("font_color", ThemeTokens.TEXT)
	btn_back.pressed.connect(_on_btn_back_pressed)
	top_bar.add_child(btn_back)

	# Title (expand)
	var title := Label.new()
	title.text = "Achievements"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(title)

	# Count: "12" mint + "/25" sub
	var cnt_box := HBoxContainer.new()
	top_bar.add_child(cnt_box)

	var c1 := Label.new()
	c1.text = str(total_unlocked)
	c1.add_theme_font_override("font", ThemeTokens.font_mono(800))
	c1.add_theme_font_size_override("font_size", 24)
	c1.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)
	c1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cnt_box.add_child(c1)

	var c2 := Label.new()
	c2.text = "/%d" % total
	c2.add_theme_font_override("font", ThemeTokens.font_mono(600))
	c2.add_theme_font_size_override("font_size", 24)
	c2.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	c2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cnt_box.add_child(c2)

	# ── OVERALL PROGRESS BAR ────────────────────────────────────
	var pb := ProgressBar.new()
	pb.custom_minimum_size.y = 8
	pb.min_value = 0
	pb.max_value = max(total, 1)
	pb.value     = total_unlocked
	pb.show_percentage = false
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(pb_fill, 999)
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = ThemeTokens.BOARD_INSET
	ThemeTokens._set_radius(pb_bg, 999)
	pb.add_theme_stylebox_override("fill",       pb_fill)
	pb.add_theme_stylebox_override("background", pb_bg)
	layout.add_child(pb)

	# ── SCROLL + LIST ────────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)

	# ── CATEGORIES ───────────────────────────────────────────────
	for cat in CATEGORIES:
		var cat_color: Color = cat["color"]
		var cat_ids:   Array = cat["ids"]

		var cat_unlocked := 0
		for id in cat_ids:
			if ach_data.get(id, {}).get("unlocked", false):
				cat_unlocked += 1

		list.add_child(_make_cat_header(cat["label"], cat_color, cat_unlocked, cat_ids.size()))

		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		list.add_child(grid)

		for id in cat_ids:
			var def      = AchievementData.get_def(id)
			var entry    = ach_data.get(id, {"unlocked": false, "progress": 0})
			var unlocked : bool = entry.get("unlocked", false)
			var progress : int  = int(entry.get("progress", 0))
			var is_secret: bool = id in SECRET_IDS
			grid.add_child(_make_badge(def, unlocked, progress, cat_color, is_secret))

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	list.add_child(spacer)


func _make_cat_header(text: String, color: Color, unlocked: int, total: int) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.custom_minimum_size.y = 24

	# Colored dot (8×8, rounded via PanelContainer)
	var dot_panel := PanelContainer.new()
	dot_panel.custom_minimum_size = Vector2(8, 8)
	dot_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot_sb := StyleBoxFlat.new()
	dot_sb.bg_color = color
	ThemeTokens._set_radius(dot_sb, 3)
	dot_panel.add_theme_stylebox_override("panel", dot_sb)
	hbox.add_child(dot_panel)

	var name_lbl := Label.new()
	name_lbl.text = text
	name_lbl.add_theme_font_override("font", ThemeTokens.font_inter(800))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spc)

	var count_lbl := Label.new()
	count_lbl.text = "%d/%d" % [unlocked, total]
	count_lbl.add_theme_font_override("font", ThemeTokens.font_mono(500))
	count_lbl.add_theme_font_size_override("font_size", 17)
	count_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(count_lbl)

	return hbox


func _make_badge(def: Dictionary, unlocked: bool, progress: int, color: Color, is_secret: bool) -> PanelContainer:
	var hidden     : bool = is_secret and not unlocked
	var target     : int  = def.get("target", 1)
	var in_progress: bool = not unlocked and progress > 0 and target > 1

	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb, 16)
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.border_color = ThemeTokens.BOARD_INSET
	panel.add_theme_stylebox_override("panel", sb)
	if not unlocked:
		panel.modulate = Color(1, 1, 1, 0.58)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   8)
	mc.add_theme_constant_override("margin_right",  8)
	mc.add_theme_constant_override("margin_top",   12)
	mc.add_theme_constant_override("margin_bottom",10)
	panel.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mc.add_child(vbox)

	# ── Icon chip (46×46) ─────────────────────────────────────
	var chip_wrap := HBoxContainer.new()
	chip_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(chip_wrap)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(46, 46)
	var chip_sb := StyleBoxFlat.new()
	chip_sb.bg_color = color if (unlocked or in_progress) and not hidden else Color("#dcd6c6")
	ThemeTokens._set_radius(chip_sb, 14)
	if unlocked and not hidden:
		chip_sb.shadow_color  = Color(color.r, color.g, color.b, 0.38)
		chip_sb.shadow_size   = 8
		chip_sb.shadow_offset = Vector2(0, 3)
	chip.add_theme_stylebox_override("panel", chip_sb)
	chip_wrap.add_child(chip)

	var chip_mc := MarginContainer.new()
	chip_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip.add_child(chip_mc)

	var chip_lbl := Label.new()
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	chip_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip_lbl.add_theme_color_override("font_color", Color.WHITE)
	if hidden:
		chip_lbl.text = "?"
		chip_lbl.add_theme_font_override("font", ThemeTokens.font_mono(800))
		chip_lbl.add_theme_font_size_override("font_size", 26)
	else:
		chip_lbl.text = ACH_ICONS.get(def.get("id", ""), "★")
		chip_lbl.add_theme_font_size_override("font_size", 24)
	chip_mc.add_child(chip_lbl)

	# ── Name ─────────────────────────────────────────────────
	var name_lbl := Label.new()
	name_lbl.text = "???" if hidden else def.get("name", "?")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color",
		ThemeTokens.SUB_TEXT if hidden else ThemeTokens.TEXT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	# ── Status area ──────────────────────────────────────────
	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 3)
	status_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(status_vbox)

	if hidden:
		var s := Label.new()
		s.text = "SECRET"
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.add_theme_font_override("font", ThemeTokens.font_inter(600))
		s.add_theme_font_size_override("font_size", 14)
		s.add_theme_color_override("font_color", Color("#b3b2a4"))
		status_vbox.add_child(s)
	elif in_progress:
		var prog_pct := float(progress) / float(target)
		var pb := ProgressBar.new()
		pb.custom_minimum_size.y = 4
		pb.min_value = 0
		pb.max_value = target
		pb.value     = progress
		pb.show_percentage = false
		var pf := StyleBoxFlat.new()
		pf.bg_color = color
		ThemeTokens._set_radius(pf, 999)
		var pbg := StyleBoxFlat.new()
		pbg.bg_color = ThemeTokens.BOARD_INSET
		ThemeTokens._set_radius(pbg, 999)
		pb.add_theme_stylebox_override("fill",       pf)
		pb.add_theme_stylebox_override("background", pbg)
		status_vbox.add_child(pb)

		var pct_lbl := Label.new()
		pct_lbl.text = "%d%%" % int(prog_pct * 100.0)
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pct_lbl.add_theme_font_override("font", ThemeTokens.font_mono(600))
		pct_lbl.add_theme_font_size_override("font_size", 14)
		pct_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
		status_vbox.add_child(pct_lbl)
	else:
		var s := Label.new()
		s.text = "UNLOCKED" if unlocked else "LOCKED"
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.add_theme_font_override("font", ThemeTokens.font_inter(600))
		s.add_theme_font_size_override("font_size", 14)
		s.add_theme_color_override("font_color", color if unlocked else Color("#b3b2a4"))
		status_vbox.add_child(s)

	return panel


func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_btn_back_pressed()
