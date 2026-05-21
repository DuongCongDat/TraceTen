extends Control

var _settings_layer: CanvasLayer = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_btn_play_pressed():
	get_tree().change_scene_to_file("res://mode_select.tscn")

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

func _build_settings_panel():
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 4
	add_child(_settings_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.90)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_layer.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 80)
	_settings_layer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 36)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_volume_row("Music", AudioManager.get_bgm_volume(),
		func(v: float): AudioManager.set_bgm_volume(v)))
	vbox.add_child(_make_volume_row("SFX", AudioManager.get_sfx_volume(),
		func(v: float): AudioManager.set_sfx_volume(v)))

	vbox.add_child(HSeparator.new())

	var btn_back := Button.new()
	btn_back.text = "<-- Back"
	btn_back.custom_minimum_size = Vector2(0, 60)
	btn_back.add_theme_font_size_override("font_size", 36)
	btn_back.pressed.connect(func(): _settings_layer.hide())
	vbox.add_child(btn_back)

func _make_volume_row(label_text: String, initial: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 32)
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
	pct.add_theme_font_size_override("font_size", 30)
	pct.custom_minimum_size = Vector2(70, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pct)

	slider.value_changed.connect(func(v: float):
		on_change.call(v)
		pct.text = "%d%%" % int(v * 100)
	)
	return row

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _settings_layer and _settings_layer.visible:
			_settings_layer.hide()
		else:
			get_tree().quit()
