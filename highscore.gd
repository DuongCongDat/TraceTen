extends Control

const MODES = ["CLASSIC", "GRAVITY", "MUTATION", "ZEN", "CHALLENGE"]
const MODE_LABELS = ["Classic", "Gravity", "Mutation", "Zen", "Challenge"]

var _current_tab: int = 0
var _content_nodes: Array = []
var _tab_buttons: Array = []

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	_select_tab(0)

func _build_ui():
	var data = Global.load_highscore()
	var tab_bar = $MarginContainer/MainLayout/TabScroll/TabButtons
	var content_area = $MarginContainer/MainLayout/ContentArea

	for i in MODES.size():
		# Tab button
		var btn = Button.new()
		btn.text = MODE_LABELS[i]
		btn.custom_minimum_size = Vector2(140, 50)
		btn.add_theme_font_size_override("font_size", 26)
		var idx = i
		btn.pressed.connect(func(): _select_tab(idx))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

		# Content container
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 18)
		container.visible = false
		content_area.add_child(container)
		_content_nodes.append(container)

		# Fill entries
		var entries: Array = data.get(MODES[i], [])
		if entries.is_empty():
			var lbl = Label.new()
			lbl.text = "No scores yet."
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 1))
			container.add_child(lbl)
		else:
			for j in entries.size():
				container.add_child(_make_row(j + 1, entries[j]["score"], entries[j]["time"], entries[j]["max_combo"]))

func _select_tab(idx: int):
	_current_tab = idx
	for i in _content_nodes.size():
		_content_nodes[i].visible = (i == idx)
	for i in _tab_buttons.size():
		_tab_buttons[i].modulate = Color(1, 1, 1, 1) if i == idx else Color(0.6, 0.65, 0.75, 1)

func _make_row(rank: int, score: int, time_sec: float, combo: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)

	var rank_lbl = _lbl("#%d" % rank, 32, Color(0.6, 0.65, 0.75, 1))
	rank_lbl.custom_minimum_size.x = 50

	var score_lbl = _lbl("%d pts" % score, 32, Color(1, 1, 1, 1))
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var combo_lbl = _lbl("x%d combo" % combo, 28, Color(1.0, 0.85, 0.3, 1))
	combo_lbl.custom_minimum_size.x = 130

	var time_lbl = _lbl(_fmt_time(time_sec), 28, Color(0.75, 0.78, 0.85, 1))
	time_lbl.custom_minimum_size.x = 90

	row.add_child(rank_lbl)
	row.add_child(score_lbl)
	row.add_child(combo_lbl)
	row.add_child(time_lbl)
	return row

func _lbl(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _fmt_time(secs: float) -> String:
	var s = int(secs)
	return "%d:%02d" % [s / 60, s % 60]

func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_btn_back_pressed()
