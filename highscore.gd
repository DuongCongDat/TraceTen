extends Control

const MODES       = ["CLASSIC", "GRAVITY", "MUTATION", "ZEN", "CHALLENGE"]
const MODE_LABELS = ["Classic", "Gravity", "Mutation", "Zen", "Adventure"]

var _current_tab: int = 0
var _content_nodes: Array = []
var _tab_buttons: Array = []

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_theme()
	_build_ui()
	_select_tab(0)


func _apply_theme():
	$Background.color = ThemeTokens.APP_BG

	var title = $MarginContainer/MainLayout/Title
	title.text = "HIGHSCORE"
	title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)

	var sep_sb := StyleBoxFlat.new()
	sep_sb.bg_color = Color(ThemeTokens.BOARD_INSET.r, ThemeTokens.BOARD_INSET.g, ThemeTokens.BOARD_INSET.b, 0.6)
	$MarginContainer/MainLayout/HSep.add_theme_stylebox_override("separator", sep_sb)

	var btn_back = $MarginContainer/MainLayout/BtnBack
	btn_back.text = "Back"
	var sb_back := StyleBoxFlat.new()
	sb_back.bg_color = Color(0, 0, 0, 0)
	ThemeTokens._set_radius(sb_back, 14)
	btn_back.add_theme_stylebox_override("normal",  sb_back)
	btn_back.add_theme_stylebox_override("hover",   sb_back)
	btn_back.add_theme_stylebox_override("pressed", sb_back)
	btn_back.add_theme_font_override("font", ThemeTokens.font_inter(700))
	btn_back.add_theme_font_size_override("font_size", 24)
	btn_back.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)


func _build_ui():
	var data      = Global.load_highscore()
	var tab_bar   = $MarginContainer/MainLayout/TabScroll/TabButtons
	var content   = $MarginContainer/MainLayout/ContentArea

	for i in MODES.size():
		var btn := Button.new()
		btn.text = MODE_LABELS[i]
		btn.custom_minimum_size = Vector2(130, 44)
		btn.add_theme_font_override("font", ThemeTokens.font_inter(700))
		btn.add_theme_font_size_override("font_size", 21)
		var idx := i
		btn.pressed.connect(func(): _select_tab(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 10)
		container.visible = false
		content.add_child(container)
		_content_nodes.append(container)

		var entries: Array = data.get(MODES[i], [])
		if entries.is_empty():
			var lbl := Label.new()
			lbl.text = "No scores yet."
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_override("font", ThemeTokens.font_inter(500))
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
			container.add_child(lbl)
		else:
			for j in entries.size():
				var e = entries[j]
				container.add_child(_make_row(j + 1, e["score"], e["time"], e["max_combo"]))


func _select_tab(idx: int):
	_current_tab = idx
	for i in _content_nodes.size():
		_content_nodes[i].visible = (i == idx)
	for i in _tab_buttons.size():
		var btn: Button = _tab_buttons[i]
		var sb := StyleBoxFlat.new()
		ThemeTokens._set_radius(sb, 20)
		if i == idx:
			sb.bg_color = ThemeTokens.MINT_DARK
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color(ThemeTokens.BOARD_INSET.r, ThemeTokens.BOARD_INSET.g, ThemeTokens.BOARD_INSET.b, 0.45)
			btn.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb)
		btn.add_theme_stylebox_override("pressed", sb)


func _make_row(rank: int, score: int, time_sec: float, combo: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb, 12)
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.border_color = Color(ThemeTokens.BOARD_INSET.r, ThemeTokens.BOARD_INSET.g, ThemeTokens.BOARD_INSET.b, 0.5)
	panel.add_theme_stylebox_override("panel", sb)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",  16)
	mc.add_theme_constant_override("margin_right", 16)
	mc.add_theme_constant_override("margin_top",   12)
	mc.add_theme_constant_override("margin_bottom",12)
	panel.add_child(mc)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	mc.add_child(row)

	# Rank
	var r := Label.new()
	r.text = "#%d" % rank
	r.custom_minimum_size.x = 40
	r.add_theme_font_override("font", ThemeTokens.font_mono(700))
	r.add_theme_font_size_override("font_size", 22)
	r.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(r)

	# Score
	var s := Label.new()
	s.text = "%d" % score
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_theme_font_override("font", ThemeTokens.font_mono(800))
	s.add_theme_font_size_override("font_size", 30)
	s.add_theme_color_override("font_color", ThemeTokens.TEXT)
	s.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(s)

	# Combo
	var c := Label.new()
	c.text = "x%d" % combo
	c.custom_minimum_size.x = 55
	c.add_theme_font_override("font", ThemeTokens.font_mono(700))
	c.add_theme_font_size_override("font_size", 20)
	c.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)
	c.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(c)

	# Time
	var t := Label.new()
	t.text = _fmt_time(time_sec)
	t.custom_minimum_size.x = 65
	t.add_theme_font_override("font", ThemeTokens.font_mono(500))
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	t.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(t)

	return panel


func _fmt_time(secs: float) -> String:
	var s := int(secs)
	return "%d:%02d" % [s / 60, s % 60]


func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_btn_back_pressed()
