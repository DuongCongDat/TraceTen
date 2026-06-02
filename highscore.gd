extends Control

const MODES        = ["CLASSIC", "GRAVITY", "MUTATION", "ZEN", "CHALLENGE"]
const MODE_LABELS  = ["Classic", "Gravity", "Mutation", "Zen", "Adventure"]
const MODE_ICONS   = ["⌛", "🍎", "🧠", "☯", "⛰"]
const MODE_ACCENTS : Array = [
	Color("#c8923a"),  # Classic  — amber
	Color("#5a9fd4"),  # Gravity  — blue
	Color("#8a7fc8"),  # Mutation — purple
	Color("#7fc8a9"),  # Zen      — mint
	Color("#e0a85c"),  # Adventure— orange
]

var _current_tab:   int   = 0
var _content_nodes: Array = []
var _tab_buttons:   Array = []


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_theme()
	_build_ui()
	_select_tab(0)


func _apply_theme():
	$Background.color = ThemeTokens.APP_BG

	$MarginContainer.add_theme_constant_override("margin_left",   44)
	$MarginContainer.add_theme_constant_override("margin_right",  44)
	$MarginContainer.add_theme_constant_override("margin_top",    40)
	$MarginContainer.add_theme_constant_override("margin_bottom", 56)
	$MarginContainer/MainLayout.add_theme_constant_override("separation", 20)

	# ── Top bar ──────────────────────────────────────────────────────────────
	var ml = $MarginContainer/MainLayout
	$MarginContainer/MainLayout/Title.free()
	$MarginContainer/MainLayout/BtnBack.free()
	$MarginContainer/MainLayout/HSep.free()

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 14)
	ml.add_child(top_bar)
	ml.move_child(top_bar, 0)

	var btn_back := Button.new()
	btn_back.text = "←"
	btn_back.custom_minimum_size = Vector2(80, 80)
	btn_back.add_theme_font_size_override("font_size", 44)
	btn_back.add_theme_color_override("font_color", ThemeTokens.TEXT)
	var sb_back := ThemeTokens.sb_menu_button()
	btn_back.add_theme_stylebox_override("normal", sb_back)
	var sb_bh := sb_back.duplicate() as StyleBoxFlat
	sb_bh.bg_color = ThemeTokens.BOARD_BG
	btn_back.add_theme_stylebox_override("hover",   sb_bh)
	btn_back.add_theme_stylebox_override("pressed", sb_bh)
	btn_back.pressed.connect(_on_btn_back_pressed)
	top_bar.add_child(btn_back)

	var title := Label.new()
	title.text = "Highscore"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(title)

	$MarginContainer/MainLayout/TabScroll.custom_minimum_size = Vector2(0, 52)


func _build_ui():
	var data    = Global.load_highscore()
	var tab_bar = $MarginContainer/MainLayout/TabScroll/TabButtons
	var content = $MarginContainer/MainLayout/ContentArea
	content.add_theme_constant_override("separation", 0)

	for i in MODES.size():
		# Tab pill: icon + name
		var btn := Button.new()
		btn.text = MODE_ICONS[i] + "  " + MODE_LABELS[i]
		btn.custom_minimum_size = Vector2(130, 48)
		btn.add_theme_font_override("font", ThemeTokens.font_inter(700))
		btn.add_theme_font_size_override("font_size", 22)
		var idx := i
		btn.pressed.connect(func(): _select_tab(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

		var scroll_c := ScrollContainer.new()
		scroll_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_c.visible = false
		content.add_child(scroll_c)
		_content_nodes.append(scroll_c)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 16)
		scroll_c.add_child(vbox)

		var entries: Array    = data.get(MODES[i], [])
		var meta:    Dictionary = data.get(MODES[i] + "_meta", {})
		if entries.is_empty():
			_make_empty_state(vbox)
		else:
			_make_mode_content(vbox, entries, meta, i)


func _make_mode_content(vbox: VBoxContainer, entries: Array, meta: Dictionary, mode_idx: int):
	var accent: Color      = MODE_ACCENTS[mode_idx]
	var best:   Dictionary = entries[0]

	# ── Hero card ────────────────────────────────────────────────────────────
	var hero := PanelContainer.new()
	hero.clip_contents = true
	var hero_sb := StyleBoxFlat.new()
	hero_sb.bg_color     = accent
	ThemeTokens._set_radius(hero_sb, 20)
	hero_sb.shadow_color  = Color(accent.r, accent.g, accent.b, 0.5)
	hero_sb.shadow_size   = 14
	hero_sb.shadow_offset = Vector2(0, 6)
	hero.add_theme_stylebox_override("panel", hero_sb)
	vbox.add_child(hero)

	# Ghost watermark icon
	var ghost := Label.new()
	ghost.text = MODE_ICONS[mode_idx]
	ghost.add_theme_font_size_override("font_size", 84)
	ghost.modulate = Color(1, 1, 1, 0.22)
	ghost.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ghost.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ghost.position = Vector2(-8, -6)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(ghost)

	var hmc := MarginContainer.new()
	hmc.add_theme_constant_override("margin_left",  22)
	hmc.add_theme_constant_override("margin_right", 22)
	hmc.add_theme_constant_override("margin_top",   20)
	hmc.add_theme_constant_override("margin_bottom",20)
	hero.add_child(hmc)

	var hvbox := VBoxContainer.new()
	hvbox.add_theme_constant_override("separation", 6)
	hmc.add_child(hvbox)

	var pb_lbl := Label.new()
	pb_lbl.text = "PERSONAL BEST"
	pb_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	pb_lbl.add_theme_font_size_override("font_size", 16)
	pb_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hvbox.add_child(pb_lbl)

	var score_lbl := Label.new()
	score_lbl.text = _fmt_score(best.get("score", 0))
	score_lbl.add_theme_font_override("font", ThemeTokens.font_mono(800))
	score_lbl.add_theme_font_size_override("font_size", 64)
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	hvbox.add_child(score_lbl)

	var date_str: String = best.get("date", "")
	if date_str != "":
		var date_lbl := Label.new()
		date_lbl.text = "achieved " + date_str
		date_lbl.add_theme_font_override("font", ThemeTokens.font_inter(500))
		date_lbl.add_theme_font_size_override("font_size", 18)
		date_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		hvbox.add_child(date_lbl)

	# ── Stats (3 boxes) ───────────────────────────────────────────────────────
	var games:    int = int(meta.get("games", 0))
	var total_sc: int = int(meta.get("total_score", 0))
	var avg_sc:   int = total_sc / games if games > 0 else 0
	var best_cb:  int = best.get("max_combo", 0)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_row)

	for pair in [
		["GAMES",   str(games) if games > 0 else "–"],
		["AVG",     _fmt_score(avg_sc) if games > 0 else "–"],
		["BEST CB", "×%d" % best_cb],
	]:
		var box := _make_stat_box(pair[0], pair[1])
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_row.add_child(box)

	# ── Top Runs ─────────────────────────────────────────────────────────────
	var hdr := Label.new()
	hdr.text = "TOP RUNS"
	hdr.add_theme_font_override("font", ThemeTokens.font_inter(700))
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(hdr)

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
	rmc.add_theme_constant_override("margin_left",  8)
	rmc.add_theme_constant_override("margin_right", 8)
	rmc.add_theme_constant_override("margin_top",   8)
	rmc.add_theme_constant_override("margin_bottom",8)
	runs_card.add_child(rmc)

	var rvbox := VBoxContainer.new()
	rvbox.add_theme_constant_override("separation", 2)
	rmc.add_child(rvbox)

	for j in entries.size():
		rvbox.add_child(_make_run_row(j + 1, entries[j], accent))

	var sp := Control.new()
	sp.custom_minimum_size.y = 8
	vbox.add_child(sp)


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
	mc.add_theme_constant_override("margin_left",  12)
	mc.add_theme_constant_override("margin_right", 12)
	mc.add_theme_constant_override("margin_top",   16)
	mc.add_theme_constant_override("margin_bottom",16)
	box.add_child(mc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	mc.add_child(vb)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	val_lbl.add_theme_font_size_override("font_size", 30)
	val_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vb.add_child(val_lbl)

	var lbl_lbl := Label.new()
	lbl_lbl.text = label_text
	lbl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_lbl.add_theme_font_override("font", ThemeTokens.font_inter(600))
	lbl_lbl.add_theme_font_size_override("font_size", 16)
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
	mc.add_theme_constant_override("margin_left",  14)
	mc.add_theme_constant_override("margin_right", 14)
	mc.add_theme_constant_override("margin_top",   12)
	mc.add_theme_constant_override("margin_bottom",12)
	panel.add_child(mc)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	mc.add_child(hbox)

	# Rank badge
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(30, 30)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = accent if is_top else ThemeTokens.BOARD_INSET
	ThemeTokens._set_radius(badge_sb, 8)
	badge.add_theme_stylebox_override("panel", badge_sb)

	var rank_lbl := Label.new()
	rank_lbl.text = str(rank)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	rank_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rank_lbl.add_theme_font_override("font", ThemeTokens.font_mono(800))
	rank_lbl.add_theme_font_size_override("font_size", 16)
	rank_lbl.add_theme_color_override("font_color", Color.WHITE if is_top else ThemeTokens.SUB_TEXT)
	badge.add_child(rank_lbl)
	hbox.add_child(badge)

	# Score (expand)
	var score_lbl := Label.new()
	score_lbl.text = _fmt_score(entry.get("score", 0))
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	score_lbl.add_theme_font_size_override("font_size", 26)
	score_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	hbox.add_child(score_lbl)

	# Date
	var date_str: String = entry.get("date", "")
	var date_lbl := Label.new()
	date_lbl.text = date_str if date_str != "" else _fmt_time(entry.get("time", 0))
	date_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	date_lbl.add_theme_font_override("font", ThemeTokens.font_inter(500))
	date_lbl.add_theme_font_size_override("font_size", 18)
	date_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	hbox.add_child(date_lbl)

	return panel


func _make_empty_state(vbox: VBoxContainer):
	var lbl := Label.new()
	lbl.text = "No scores yet."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size.y = 160
	lbl.add_theme_font_override("font", ThemeTokens.font_inter(500))
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(lbl)


func _select_tab(idx: int):
	_current_tab = idx
	for i in _content_nodes.size():
		_content_nodes[i].visible = (i == idx)
	for i in _tab_buttons.size():
		var btn:    Button     = _tab_buttons[i]
		var accent: Color      = MODE_ACCENTS[i]
		var sb     := StyleBoxFlat.new()
		ThemeTokens._set_radius(sb, 999)
		if i == idx:
			# Active: solid accent bg, white text
			sb.bg_color = accent
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			# Inactive: white bg + border, text = accent color
			sb.bg_color = ThemeTokens.CARD_BG
			sb.border_width_left = 1; sb.border_width_right  = 1
			sb.border_width_top  = 1; sb.border_width_bottom = 1
			sb.border_color = ThemeTokens.BOARD_INSET
			btn.add_theme_color_override("font_color", accent)
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
