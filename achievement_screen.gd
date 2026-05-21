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
	_build_ui()

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
		list.add_child(_make_spacer(12))

func _make_header(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = "— " + text + " —"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))
	lbl.custom_minimum_size.y = 40
	return lbl

func _make_row(def: Dictionary, unlocked: bool, progress: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 72

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Icon
	var icon = Label.new()
	icon.text = "★" if unlocked else "○"
	icon.add_theme_font_size_override("font_size", 32)
	icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1) if unlocked else Color(0.45, 0.47, 0.55, 1))
	icon.custom_minimum_size.x = 40
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Name + desc
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = def.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 26)
	var name_color = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.58, 0.65, 1)
	name_lbl.add_theme_color_override("font_color", name_color)
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = def.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 19)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75, 1))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Progress (right side, only if target > 1)
	var target: int = def.get("target", 1)
	if target > 1:
		var prog_lbl = Label.new()
		prog_lbl.text = "%d / %d" % [min(progress, target), target] if not unlocked else "Done"
		prog_lbl.add_theme_font_size_override("font_size", 22)
		prog_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1) if unlocked else Color(0.65, 0.68, 0.75, 1))
		prog_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prog_lbl.custom_minimum_size.x = 80
		prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(prog_lbl)

	# Dim panel if locked
	if not unlocked:
		panel.modulate = Color(1, 1, 1, 0.6)

	return panel

func _make_spacer(height: int) -> Control:
	var s = Control.new()
	s.custom_minimum_size.y = height
	return s

func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_btn_back_pressed()
