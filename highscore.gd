extends Control

const MODES        = ["CLASSIC", "GRAVITY", "MUTATION", "ZEN", "CHALLENGE"]
const MODE_LABELS  = ["Classic", "Gravity", "Mutation", "Zen", "Adventure"]
const MODE_ICONS   = ["⌛", "🍎", "🧠", "☯", "⛰"]
const MODE_ACCENTS = [
	Color("#c8923a"),  # Classic  — amber
	Color("#5a9fd4"),  # Gravity  — blue
	Color("#8a7fc8"),  # Mutation — purple
	Color("#7fc8a9"),  # Zen      — mint
	Color("#e0a85c"),  # Adventure— orange
]

var _current_tab:    int   = 0
var _content_nodes:  Array = []
var _tab_buttons:    Array = []


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_theme()
	_build_ui()
	_select_tab(0)


func _apply_theme():
	$Background.color = ThemeTokens.APP_BG

	# Tighten margins (tscn has 50px — override to 16/18)
	$MarginContainer.add_theme_constant_override("margin_left",  16)
	$MarginContainer.add_theme_constant_override("margin_right", 16)
	$MarginContainer.add_theme_constant_override("margin_top",   18)
	$MarginContainer.add_theme_constant_override("margin_bottom",16)
	$MarginContainer/MainLayout.add_theme_constant_override("separation", 12)

	# ── Replace title + back + separator with a proper top-bar HBox ──────────
	var main_layout = $MarginContainer/MainLayout
	$MarginContainer/MainLayout/Title.free()
	$MarginContainer/MainLayout/BtnBack.free()
	$MarginContainer/MainLayout/HSep.free()

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	main_layout.add_child(top_bar)
	main_layout.move_child(top_bar, 0)

	# Back chip button
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

	# Title
	var title := Label.new()
	title.text = "Highscore"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(title)

	# TabScroll min-height
	$MarginContainer/MainLayout/TabScroll.custom_minimum_size = Vector2(0, 44)


func _build_ui():
	var data      = Global.load_highscore()
	var tab_bar   = $MarginContainer/MainLayout/TabScroll/TabButtons
	var content   = $MarginContainer/MainLayout/ContentArea
	content.add_theme_constant_override("separation", 0)

	for i in MODES.size():
		# Tab pill: icon + name
		var btn := Button.new()
		btn.text = MODE_ICONS[i] + "  " + MODE_LABELS[i]
		btn.custom_minimum_size = Vector2(108, 38)
		btn.add_theme_font_override("font", ThemeTokens.font_inter(700))
		btn.add_theme_font_size_override("font_size", 13)
		var idx := i
		btn.pressed.connect(func(): _select_tab(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

		# Per-mode scroll wrapper
		var scroll_c := ScrollContainer.new()
		scroll_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_c.visible = false
		content.add_child(scroll_c)
		_content_nodes.append(scroll_c)

		var container := VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_theme_constant_override("separation", 12)
		scroll_c.add_child(container)

		var entries: Array = data.get(MODES[i], [])
		if entries.is_empty():
			_make_empty_state(container)
		else:
			_make_mode_content(container, entries, i)


func _make_mode_content(vbox: VBoxContainer, entries: Array, mode_idx: int):
	var accent: Color      = MODE_ACCENTS[mode_idx]
	var best:   Dictionary = entries[0]

	# ── Hero card ─────────────────────────────────────────────
	var hero := PanelContainer.new()
	var hero_sb := StyleBoxFlat.new()
	hero_sb.bg_color = accent
	ThemeTokens._set_radius(hero_sb, 20)
	hero_sb.shadow_color  = Color(accent.r, accent.g, accent.b, 0.45)
	hero_sb.shadow_size   = 10
	hero_sb.shadow_offset = Vector2(0, 5)
	hero.add_theme_stylebox_override("panel", hero_sb)
	vbox.add_child(hero)

	var hmc := MarginContainer.new()
	hmc.add_theme_constant_override("margin_left",  18)
	hmc.add_theme_constant_override("margin_right", 18)
	hmc.add_theme_constant_override("margin_top",   16)
	hmc.add_theme_constant_override("margin_bottom",16)
	hero.add_child(hmc)

	var hvbox := VBoxContainer.new()
	hvbox.add_theme_constant_override("separation", 4)
	hmc.add_child(hvbox)

	var pb_lbl := Label.new()
	pb_lbl.text = "PERSONAL BEST"
	pb_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	pb_lbl.add_theme_font_size_override("font_size", 10)
	pb_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hvbox.add_child(pb_lbl)

	var score_lbl := Label.new()
	score_lbl.text = _fmt_score(best.get("score", 0))
	score_lbl.add_theme_font_override("font", ThemeTokens.font_mono(800))
	score_lbl.add_theme_font_size_override("font_size", 44)
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	hvbox.add_child(score_lbl)

	# ── Stats row ─────────────────────────────────────────────
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_row)

	var cb := _make_stat_box("BEST COMBO", "×%d" % best.get("max_combo", 0))
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_child(cb)

	var tb := _make_stat_box("BEST TIME", _fmt_time(best.get("time", 0)))
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_child(tb)

	# ── Top runs header ────────────────────────────────────────
	var runs_hdr := Label.new()
	runs_hdr.text = "TOP RUNS"
	runs_hdr.add_theme_font_override("font", ThemeTokens.font_inter(700))
	runs_hdr.add_theme_font_size_override("font_size", 10)
	runs_hdr.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(runs_hdr)

	# ── Runs card ─────────────────────────────────────────────
	var runs_card := PanelContainer.new()
	var rc_sb := StyleBoxFlat.new()
	rc_sb.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(rc_sb, 16)
	rc_sb.border_width_left = 1; rc_sb.border_width_right  = 1
	rc_sb.border_width_top  = 1; rc_sb.border_width_bottom = 1
	rc_sb.border_color = ThemeTokens.BOARD_INSET
	runs_card.add_theme_stylebox_override("panel", rc_sb)
	vbox.add_child(runs_card)

	var rmc := MarginContainer.new()
	rmc.add_theme_constant_override("margin_left",  6)
	rmc.add_theme_constant_override("margin_right", 6)
	rmc.add_theme_constant_override("margin_top",   6)
	rmc.add_theme_constant_override("margin_bottom",6)
	runs_card.add_child(rmc)

	var rvbox := VBoxContainer.new()
	rvbox.add_theme_constant_override("separation", 2)
	rmc.add_child(rvbox)

	for j in entries.size():
		rvbox.add_child(_make_run_row(j + 1, entries[j], accent))


func _make_stat_box(label_text: String, value_text: String) -> PanelContainer:
	var box := PanelContainer.new()
	var sb  := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb, 14)
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.border_color = ThemeTokens.BOARD_INSET
	box.add_theme_stylebox_override("panel", sb)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",  10)
	mc.add_theme_constant_override("margin_right", 10)
	mc.add_theme_constant_override("margin_top",   12)
	mc.add_theme_constant_override("margin_bottom",12)
	box.add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	mc.add_child(vb)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	val_lbl.add_theme_font_size_override("font_size", 17)
	val_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vb.add_child(val_lbl)

	var lbl_lbl := Label.new()
	lbl_lbl.text = label_text
	lbl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lbl.add_theme_font_override("font", ThemeTokens.font_inter(600))
	lbl_lbl.add_theme_font_size_override("font_size", 9)
	lbl_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vb.add_child(lbl_lbl)

	return box


func _make_run_row(rank: int, entry: Dictionary, accent: Color) -> PanelContainer:
	var is_top := rank == 1

	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.12) if is_top else Color(0, 0, 0, 0)
	ThemeTokens._set_radius(sb, 11)
	panel.add_theme_stylebox_override("panel", sb)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",  12)
	mc.add_theme_constant_override("margin_right", 12)
	mc.add_theme_constant_override("margin_top",    9)
	mc.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(mc)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	mc.add_child(hbox)

	# Rank badge
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(22, 22)
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = accent if is_top else ThemeTokens.BOARD_INSET
	ThemeTokens._set_radius(badge_sb, 7)
	badge.add_theme_stylebox_override("panel", badge_sb)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var rank_lbl := Label.new()
	rank_lbl.text = str(rank)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	rank_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rank_lbl.add_theme_font_override("font", ThemeTokens.font_mono(800))
	rank_lbl.add_theme_font_size_override("font_size", 11)
	rank_lbl.add_theme_color_override("font_color", Color.WHITE if is_top else ThemeTokens.SUB_TEXT)
	badge.add_child(rank_lbl)
	hbox.add_child(badge)

	# Score (expand fill)
	var score_lbl := Label.new()
	score_lbl.text = _fmt_score(entry.get("score", 0))
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	score_lbl.add_theme_font_size_override("font_size", 15)
	score_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	hbox.add_child(score_lbl)

	# Combo
	var combo_lbl := Label.new()
	combo_lbl.text = "×%d" % entry.get("max_combo", 0)
	combo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_lbl.add_theme_font_override("font", ThemeTokens.font_mono(600))
	combo_lbl.add_theme_font_size_override("font_size", 13)
	combo_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	hbox.add_child(combo_lbl)

	# Time
	var time_lbl := Label.new()
	time_lbl.text = _fmt_time(entry.get("time", 0))
	time_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_lbl.add_theme_font_override("font", ThemeTokens.font_mono(500))
	time_lbl.add_theme_font_size_override("font_size", 13)
	time_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	hbox.add_child(time_lbl)

	return panel


func _make_empty_state(vbox: VBoxContainer):
	var lbl := Label.new()
	lbl.text = "No scores yet."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size.y = 120
	lbl.add_theme_font_override("font", ThemeTokens.font_inter(500))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(lbl)


func _select_tab(idx: int):
	_current_tab = idx
	for i in _content_nodes.size():
		_content_nodes[i].visible = (i == idx)
	for i in _tab_buttons.size():
		var btn: Button   = _tab_buttons[i]
		var sb  := StyleBoxFlat.new()
		ThemeTokens._set_radius(sb, 999)
		if i == idx:
			sb.bg_color = MODE_ACCENTS[i]
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = ThemeTokens.CARD_BG
			sb.border_width_left = 1; sb.border_width_right  = 1
			sb.border_width_top  = 1; sb.border_width_bottom = 1
			sb.border_color = ThemeTokens.BOARD_INSET
			btn.add_theme_color_override("font_color", ThemeTokens.TEXT)
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb)
		btn.add_theme_stylebox_override("pressed", sb)


func _fmt_score(s: int) -> String:
	if s < 1000:
		return str(s)
	var str_s  := str(s)
	var result := ""
	var count  := 0
	for i in range(str_s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_s[i] + result
		count += 1
	return result


func _fmt_time(secs: float) -> String:
	var s := int(secs)
	return "%d:%02d" % [s / 60, s % 60]


func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_btn_back_pressed()
