extends Control

signal close_requested

const TUTORIALS = [
	{
		"id": "howtoplay",
		"name": "Sum to Ten",
		"tag": "HOW TO PLAY",
		"desc": "Drag to select any rectangle of tiles. If the values inside add up to exactly 10, they clear and you score.",
		"icon": "10",
		"accent": Color(0.306, 0.647, 0.518),   # MINT_DARK
	},
	{
		"id": "joker",
		"name": "The Wildcard",
		"tag": "JOKER",
		"desc": "A Joker morphs into whatever number you need so the selection lands on 10. Save it for a tight spot.",
		"icon": "★",
		"accent": Color(0.851, 0.600, 0.251),   # JOKER_STROKE
	},
	{
		"id": "virus",
		"name": "Tick, Tick…",
		"tag": "VIRUS",
		"desc": "Each tick the Virus changes its value and loses one HP dot. When all dots are gone it spreads — penalising you.",
		"icon": "!",
		"accent": Color(0.478, 0.616, 0.365),   # VIRUS_DARK
	},
	{
		"id": "mystery",
		"name": "Hidden Value",
		"tag": "MYSTERY",
		"desc": "A Mystery tile hides its number until you tap to reveal it. Scout it, then fold it into a sum.",
		"icon": "?",
		"accent": Color(0.420, 0.463, 0.439),   # MYSTERY_REV_BG
	},
	{
		"id": "negative",
		"name": "Go Below",
		"tag": "NEGATIVE",
		"desc": "A Negative tile subtracts. Use it to pull an overshooting rectangle back down to exactly 10.",
		"icon": "−",
		"accent": Color(0.769, 0.416, 0.416),   # NEG_DARK
	},
]

const TILE_SIZE := 100.0

var _current_id   := ""
var _demo_gen     := 0

var _tile_rects:      Dictionary = {}   # Vector2 → Panel
var _tile_labels:     Dictionary = {}   # Vector2 → Label
var _tile_styles:     Dictionary = {}   # Vector2 → StyleBoxFlat
var _virus_dot_styles: Dictionary = {}  # Vector2 → Array[StyleBoxFlat]

@onready var list_layer:        Control       = $ListLayer
@onready var demo_layer:        Control       = $DemoLayer
@onready var card_list:         VBoxContainer = %CardList
@onready var step_label:        Label         = %StepLabel
@onready var instruction_label: Label         = %InstructionLabel
@onready var board_container:   Node2D        = %BoardContainer
@onready var selection_box:     ColorRect     = %SelectionBox
@onready var cursor_dot:        ColorRect     = %CursorDot


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_theme()
	_populate_card_list()
	_maybe_show_timer_warning()


func _apply_theme() -> void:
	# Background
	$Background.color = ThemeTokens.APP_BG

	# ── List screen ─────────────────────────────────────────
	var btn_back: Button = $ListLayer/MarginContainer/MainLayout/TopBar/BtnBack
	btn_back.text = "←"
	btn_back.custom_minimum_size = Vector2(ThemeTokens.MENU_BUTTON_SIZE, ThemeTokens.MENU_BUTTON_SIZE)
	for state in ["normal", "hover", "pressed", "focus"]:
		btn_back.add_theme_stylebox_override(state, ThemeTokens.sb_menu_button())
	btn_back.add_theme_font_override("font", ThemeTokens.font_mono(700))
	btn_back.add_theme_font_size_override("font_size", 34)
	btn_back.add_theme_color_override("font_color", ThemeTokens.TEXT)

	var page_title: Label = $ListLayer/MarginContainer/MainLayout/TopBar/PageTitle
	page_title.text = "HOW TO PLAY"
	page_title.add_theme_font_override("font", ThemeTokens.font_inter(800))
	page_title.add_theme_font_size_override("font_size", 34)
	page_title.add_theme_color_override("font_color", ThemeTokens.TEXT)

	var sep: HSeparator = $ListLayer/MarginContainer/MainLayout/HSep
	sep.add_theme_color_override("color", ThemeTokens.BOARD_INSET)

	# ── Demo screen ──────────────────────────────────────────
	step_label.add_theme_font_override("font", ThemeTokens.font_inter(700))
	step_label.add_theme_font_size_override("font_size", 20)
	step_label.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)

	instruction_label.add_theme_font_override("font", ThemeTokens.font_inter(700))
	instruction_label.add_theme_font_size_override("font_size", 28)
	instruction_label.add_theme_color_override("font_color", ThemeTokens.TEXT)

	cursor_dot.color = ThemeTokens.MINT_DARK

	var btn_back_demo: Button = $DemoLayer/ControlBar/BtnBackDemo
	var btn_replay: Button    = $DemoLayer/ControlBar/BtnReplay

	# Move back button to top-left corner of DemoLayer
	btn_back_demo.reparent(demo_layer, false)
	btn_back_demo.text = "←"
	btn_back_demo.custom_minimum_size = Vector2(ThemeTokens.MENU_BUTTON_SIZE, ThemeTokens.MENU_BUTTON_SIZE)
	btn_back_demo.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	btn_back_demo.position = Vector2(44, 44)

	for state in ["normal", "hover", "pressed", "focus"]:
		btn_back_demo.add_theme_stylebox_override(state, ThemeTokens.sb_menu_button())
	btn_back_demo.add_theme_font_override("font", ThemeTokens.font_mono(700))
	btn_back_demo.add_theme_font_size_override("font_size", 34)
	btn_back_demo.add_theme_color_override("font_color", ThemeTokens.TEXT)

	# Replay stays at bottom center
	for state in ["normal", "hover", "pressed", "focus"]:
		btn_replay.add_theme_stylebox_override(state, ThemeTokens.sb_menu_button())
	btn_replay.add_theme_font_override("font", ThemeTokens.font_inter(700))
	btn_replay.add_theme_font_size_override("font_size", 26)
	btn_replay.add_theme_color_override("font_color", ThemeTokens.TEXT)


func _maybe_show_timer_warning():
	if get_parent() == get_tree().root:
		return
	if Global.selected_mode not in ["CLASSIC", "GRAVITY"]:
		return
	var lbl := Label.new()
	lbl.text = "⚠  Timer is still running!"
	lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 0.15))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var main_layout: VBoxContainer = card_list.get_parent()
	main_layout.add_child(lbl)
	main_layout.move_child(lbl, card_list.get_index())


# ══════════════════════════════════════════════
# LIST SCREEN
# ══════════════════════════════════════════════

func _populate_card_list():
	for t in TUTORIALS:
		card_list.add_child(_make_card(t))


func _make_card(t: Dictionary) -> Control:
	# Outer PanelContainer with card style
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeTokens.sb_card())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# ── Icon chip ──
	var chip_wrap := Control.new()
	chip_wrap.custom_minimum_size = Vector2(64, 64)
	chip_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(chip_wrap)

	var chip := Panel.new()
	chip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_chip := StyleBoxFlat.new()
	sb_chip.bg_color = t.accent
	sb_chip.corner_radius_top_left     = 18
	sb_chip.corner_radius_top_right    = 18
	sb_chip.corner_radius_bottom_right = 18
	sb_chip.corner_radius_bottom_left  = 18
	chip.add_theme_stylebox_override("panel", sb_chip)
	chip_wrap.add_child(chip)

	var icon_lbl := Label.new()
	icon_lbl.text = t.icon
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.add_theme_color_override("font_color", Color.WHITE)
	chip_wrap.add_child(icon_lbl)

	# ── Text ──
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	var tag_lbl := Label.new()
	tag_lbl.text = t.tag
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	tag_lbl.add_theme_font_size_override("font_size", 16)
	tag_lbl.add_theme_color_override("font_color", t.accent)
	vbox.add_child(tag_lbl)

	var name_lbl := Label.new()
	name_lbl.text = t.name
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_font_override("font", ThemeTokens.font_inter(800))
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = t.desc
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", ThemeTokens.font_inter(400))
	desc_lbl.add_theme_font_size_override("font_size", 18)
	desc_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(desc_lbl)

	# ── Chevron ──
	var arrow := Label.new()
	arrow.text = "›"
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_font_override("font", ThemeTokens.font_inter(400))
	arrow.add_theme_font_size_override("font_size", 36)
	arrow.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	hbox.add_child(arrow)

	var tid: String = t.id
	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_load_demo(tid)
	)
	return panel


func _on_btn_back_pressed():
	if get_parent() != get_tree().root:
		_demo_gen += 1
		close_requested.emit()
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")


# ══════════════════════════════════════════════
# DEMO SCREEN
# ══════════════════════════════════════════════

func _load_demo(id: String):
	_current_id = id
	_demo_gen  += 1
	var gen := _demo_gen

	list_layer.hide()
	demo_layer.show()
	_clear_board()
	selection_box.hide()
	cursor_dot.hide()

	var screen := get_viewport_rect().size
	board_container.position = Vector2(screen.x / 2.0, screen.y / 2.0 - 20.0)

	match id:
		"howtoplay": _run_howtoplay(gen)
		"virus":     _run_virus(gen)
		"negative":  _run_negative(gen)
		"mystery":   _run_mystery(gen)
		"joker":     _run_joker(gen)


func _on_btn_back_demo_pressed():
	_demo_gen += 1
	_clear_board()
	selection_box.hide()
	cursor_dot.hide()
	demo_layer.hide()
	list_layer.show()


func _on_btn_replay_pressed():
	if _current_id != "":
		_load_demo(_current_id)


# ══════════════════════════════════════════════
# BOARD HELPERS
# ══════════════════════════════════════════════

func _clear_board():
	for child in board_container.get_children():
		child.queue_free()
	_tile_rects.clear()
	_tile_labels.clear()
	_tile_styles.clear()
	_virus_dot_styles.clear()


func _spawn_tile(gpos: Vector2, value: int,
		bg: Color = ThemeTokens.TILE_WHITE,
		fg: Color = ThemeTokens.TEXT) -> void:
	var offset := (gpos - Vector2(1, 1)) * TILE_SIZE
	var sz := Vector2(TILE_SIZE - 8, TILE_SIZE - 8)

	var panel := Panel.new()
	panel.size = sz
	panel.position = offset - sz / 2.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left     = ThemeTokens.TILE_RADIUS
	sb.corner_radius_top_right    = ThemeTokens.TILE_RADIUS
	sb.corner_radius_bottom_right = ThemeTokens.TILE_RADIUS
	sb.corner_radius_bottom_left  = ThemeTokens.TILE_RADIUS
	sb.border_width_bottom = 2
	sb.border_color = Color(0.314, 0.275, 0.157, 0.06)
	sb.shadow_color = Color(0.314, 0.275, 0.157, 0.06)
	sb.shadow_size   = 1
	sb.shadow_offset = Vector2(0, 1)
	panel.add_theme_stylebox_override("panel", sb)
	board_container.add_child(panel)

	var lbl := Label.new()
	lbl.text = str(value) if value != 0 else ""
	lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", fg)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)

	_tile_rects[gpos]  = panel
	_tile_labels[gpos] = lbl
	_tile_styles[gpos] = sb


func _add_virus_dots(gpos: Vector2, count: int) -> void:
	if not _tile_rects.has(gpos):
		return
	var panel: Panel = _tile_rects[gpos]
	var sz := panel.size
	var dot_size := 8.0
	var dot_gap  := 5.0
	var total_w  := count * dot_size + (count - 1) * dot_gap
	var start_x  := (sz.x - total_w) * 0.5
	var y        := sz.y - 14.0
	var styles: Array = []
	for i in count:
		var dot := Panel.new()
		dot.size     = Vector2(dot_size, dot_size)
		dot.position = Vector2(start_x + i * (dot_size + dot_gap), y)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.corner_radius_top_left     = 999
		sb.corner_radius_top_right    = 999
		sb.corner_radius_bottom_right = 999
		sb.corner_radius_bottom_left  = 999
		sb.bg_color = ThemeTokens.VIRUS_DARK
		dot.add_theme_stylebox_override("panel", sb)
		panel.add_child(dot)
		styles.append(sb)
	_virus_dot_styles[gpos] = styles


func _set_virus_dots(gpos: Vector2, remaining: int) -> void:
	if not _virus_dot_styles.has(gpos):
		return
	var styles: Array = _virus_dot_styles[gpos]
	for i in styles.size():
		var sb: StyleBoxFlat = styles[i]
		sb.bg_color = ThemeTokens.VIRUS_DARK if i < remaining else Color(ThemeTokens.VIRUS_DARK.r, ThemeTokens.VIRUS_DARK.g, ThemeTokens.VIRUS_DARK.b, 0.25)


func _grid_px(gpos: Vector2) -> Vector2:
	return board_container.position + (gpos - Vector2(1, 1)) * TILE_SIZE


func _pop_tiles(positions: Array, gen: int) -> void:
	for pos in positions:
		if _tile_rects.has(pos):
			var tw := create_tween()
			tw.tween_property(_tile_rects[pos], "modulate:a", 0.0, 0.35)
	await get_tree().create_timer(0.45).timeout
	if gen != _demo_gen: return
	for pos in positions:
		if _tile_rects.has(pos):
			_tile_rects[pos].queue_free()
			_tile_rects.erase(pos)
			_tile_labels.erase(pos)
			_tile_styles.erase(pos)


func _float_text(msg: String, color: Color = ThemeTokens.MINT_DARK):
	var screen := get_viewport_rect().size
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(320, 80)
	lbl.position = Vector2(screen.x / 2.0 - 160.0, screen.y / 2.0 - 60.0)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position - Vector2(0, 90), 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)


func _animate_drag(start: Vector2, end: Vector2, duration: float) -> void:
	var px_start := _grid_px(start)
	var px_end   := _grid_px(end)
	var cols := int(abs(end.x - start.x)) + 1
	var rows := int(abs(end.y - start.y)) + 1
	var sel_tl := _grid_px(Vector2(min(start.x, end.x), min(start.y, end.y))) \
				  - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

	cursor_dot.size = Vector2(24, 24)
	cursor_dot.position = px_start - Vector2(12, 12)
	cursor_dot.modulate.a = 0.0
	cursor_dot.show()
	var tw_in := create_tween()
	tw_in.tween_property(cursor_dot, "modulate:a", 1.0, 0.25)
	await tw_in.finished

	selection_box.position = sel_tl
	selection_box.size = Vector2(TILE_SIZE, TILE_SIZE)
	selection_box.color = Color(0.498, 0.784, 0.663, 0.22)   # MINT translucent drag
	selection_box.show()

	var tw := create_tween().set_parallel(true)
	tw.tween_property(cursor_dot, "position", px_end - Vector2(16, 16),
		duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(selection_box, "size",
		Vector2(cols * TILE_SIZE, rows * TILE_SIZE),
		duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


# ══════════════════════════════════════════════
# TUTORIAL 1 — HOW TO PLAY
# Board:  2 3 5 / 1 4 6 / 7 8 9
# Target: (0,0)→(1,1) = 2+3+1+4 = 10
# ══════════════════════════════════════════════

func _run_howtoplay(gen: int):
	var vals   := [[2, 3, 5], [1, 4, 6], [7, 8, 9]]
	var target := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()
		for y in 3:
			for x in 3:
				_spawn_tile(Vector2(x, y), vals[y][x])

		step_label.text = "How to Play"
		instruction_label.text = "Drag to select a rectangle of tiles."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "The sum of all tiles inside must equal 10."
		for _i in 3:
			for pos in target:
				if _tile_styles.has(pos):
					var tw := create_tween()
					tw.tween_property(_tile_styles[pos], "bg_color", ThemeTokens.MINT_SOFT, 0.20)
					tw.tween_property(_tile_styles[pos], "bg_color", ThemeTokens.TILE_WHITE, 0.20)
			await get_tree().create_timer(0.55).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Drag from one corner to the other..."
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.306, 0.647, 0.518, 0.40)   # MINT_DARK solid
		instruction_label.text = "Sum = 10!  Tiles clear and you score."
		_float_text("+10")
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles(target, gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()
		await get_tree().create_timer(2.5).timeout


# ══════════════════════════════════════════════
# TUTORIAL 2 — VIRUS TILE
# Correct mechanic: each tick → change value + consume 1 HP dot.
# When HP dots = 0 → spreads to adjacent tile, -10 penalty.
# ══════════════════════════════════════════════

func _run_virus(gen: int):
	var VPOS  := Vector2(1, 1)
	var VPOS2 := Vector2(1, 2)   # spread target — tile below (value 6)

	while gen == _demo_gen:
		# ── PART 1: HP countdown + spread ──
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout1 := {
			Vector2(0,0):5, Vector2(1,0):2, Vector2(2,0):3,
			Vector2(0,1):4,
			Vector2(0,2):7, Vector2(1,2):6, Vector2(2,2):8,
		}
		for pos in layout1:
			_spawn_tile(pos, layout1[pos])
		_spawn_tile(VPOS, 3, ThemeTokens.VIRUS_BG, ThemeTokens.VIRUS_TEXT)
		_add_virus_dots(VPOS, 3)

		step_label.text = "Virus Tile  •  1 / 2"
		instruction_label.text = "The Virus has HP dots. Each tick: value changes + 1 dot consumed."
		await get_tree().create_timer(2.5).timeout
		if gen != _demo_gen: return

		# Tick 1: value 3→7, dots 3→2
		if _tile_styles.has(VPOS):
			var tw := create_tween()
			tw.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_GLOW, 0.18)
			tw.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_BG,   0.18)
			await tw.finished
		if gen != _demo_gen: return
		if _tile_labels.has(VPOS):
			_tile_labels[VPOS].text = "7"
		_set_virus_dots(VPOS, 2)
		instruction_label.text = "Tick! Value mutates, one dot consumed."
		await get_tree().create_timer(1.8).timeout
		if gen != _demo_gen: return

		# Tick 2: value 7→-2, dots 2→1
		if _tile_styles.has(VPOS):
			var tw := create_tween()
			tw.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_GLOW, 0.18)
			tw.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_BG,   0.18)
			await tw.finished
		if gen != _demo_gen: return
		if _tile_labels.has(VPOS):
			_tile_labels[VPOS].text = "-2"
		_set_virus_dots(VPOS, 1)
		instruction_label.text = "Last dot! Clear it before the next tick!"
		# Urgency pulses on last dot
		for _i in 3:
			if gen != _demo_gen: return
			if _tile_styles.has(VPOS):
				var tw := create_tween()
				tw.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_GLOW, 0.15)
				tw.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_BG,   0.15)
				await tw.finished
			await get_tree().create_timer(0.1).timeout
		if gen != _demo_gen: return

		await get_tree().create_timer(1.2).timeout
		if gen != _demo_gen: return

		# Tick 3: dots hit 0 → SPREAD
		_set_virus_dots(VPOS, 0)
		instruction_label.text = "HP depleted — Virus spreads to a neighbour!"
		await get_tree().create_timer(0.6).timeout
		if gen != _demo_gen: return

		# Original virus resets HP (stays in place)
		if _tile_styles.has(VPOS):
			var tw_flash := create_tween()
			tw_flash.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_GLOW, 0.15)
			tw_flash.tween_property(_tile_styles[VPOS], "bg_color", ThemeTokens.VIRUS_BG,   0.15)
			await tw_flash.finished
		_set_virus_dots(VPOS, 3)   # reset HP on original tile
		if _tile_labels.has(VPOS):
			_tile_labels[VPOS].text = "6"
		if gen != _demo_gen: return

		# Remove existing tile at spread target, then infect it
		if _tile_rects.has(VPOS2):
			_tile_rects[VPOS2].queue_free()
			_tile_rects.erase(VPOS2)
			_tile_labels.erase(VPOS2)
			_tile_styles.erase(VPOS2)
		_spawn_tile(VPOS2, 5, ThemeTokens.VIRUS_BG, ThemeTokens.VIRUS_TEXT)
		_add_virus_dots(VPOS2, 3)
		if _tile_rects.has(VPOS2):
			_tile_rects[VPOS2].modulate.a = 0.0
			var tw_in := create_tween()
			tw_in.tween_property(_tile_rects[VPOS2], "modulate:a", 1.0, 0.35)
			await tw_in.finished
		if gen != _demo_gen: return

		_float_text("-10", Color(0.769, 0.20, 0.20))
		instruction_label.text = "Original resets HP, neighbour infected!  −10 pts."
		await get_tree().create_timer(3.0).timeout
		if gen != _demo_gen: return

		# ── PART 2: clear before spread ──
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout2 := {
			Vector2(0,0):5, Vector2(1,0):2, Vector2(2,0):3,
			Vector2(0,1):8, Vector2(2,1):1,
			Vector2(0,2):7, Vector2(1,2):6, Vector2(2,2):8,
		}
		for pos in layout2:
			_spawn_tile(pos, layout2[pos])
		_spawn_tile(VPOS, 2, ThemeTokens.VIRUS_BG, ThemeTokens.VIRUS_TEXT)
		_add_virus_dots(VPOS, 2)

		step_label.text = "Virus Tile  •  2 / 2"
		instruction_label.text = "Include the Virus in a valid rectangle before it spreads."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "8 + 2 = 10  — select before the dots run out!"
		await get_tree().create_timer(1.2).timeout
		if gen != _demo_gen: return

		await _animate_drag(Vector2(0, 1), Vector2(1, 1), 0.85)
		if gen != _demo_gen: return

		await get_tree().create_timer(0.8).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.306, 0.647, 0.518, 0.40)
		instruction_label.text = "Virus cleared!  +10 bonus for the save."
		_float_text("+10", ThemeTokens.VIRUS_DARK)
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles([Vector2(0, 1), VPOS], gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()
		await get_tree().create_timer(2.5).timeout


# ══════════════════════════════════════════════
# TUTORIAL 3 — NEGATIVE TILE
# Board:  1 5 2 / 7 N 4 / 6 8 9   (N = -3)
# Target: (0,0)→(1,1) = 1+5+7+(−3) = 10
# ══════════════════════════════════════════════

func _run_negative(gen: int):
	var NPOS   := Vector2(1, 1)
	var target := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout := {
			Vector2(0,0): 1, Vector2(1,0): 5, Vector2(2,0): 2,
			Vector2(0,1): 7,                  Vector2(2,1): 4,
			Vector2(0,2): 6, Vector2(1,2): 8, Vector2(2,2): 9,
		}
		for pos in layout:
			_spawn_tile(pos, layout[pos])
		_spawn_tile(NPOS, -3, ThemeTokens.NEG_BG, ThemeTokens.NEG_DARK)

		step_label.text = "Negative Tile"
		instruction_label.text = "Red tiles carry a negative value."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "They look dangerous — but they're useful!"
		for _i in 3:
			if gen != _demo_gen: return
			if _tile_styles.has(NPOS):
				var tw := create_tween()
				tw.tween_property(_tile_styles[NPOS], "bg_color", Color(0.98, 0.70, 0.70), 0.20)
				tw.tween_property(_tile_styles[NPOS], "bg_color", ThemeTokens.NEG_BG,       0.20)
				await tw.finished
			await get_tree().create_timer(0.25).timeout
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "1 + 5 + 7 + (−3) = 10"
		for _i in 3:
			for pos in target:
				if _tile_styles.has(pos):
					var c_hi := Color(0.98, 0.70, 0.70) if pos == NPOS else ThemeTokens.MINT_SOFT
					var c_lo := ThemeTokens.NEG_BG       if pos == NPOS else ThemeTokens.TILE_WHITE
					var tw := create_tween()
					tw.tween_property(_tile_styles[pos], "bg_color", c_hi, 0.20)
					tw.tween_property(_tile_styles[pos], "bg_color", c_lo, 0.20)
			await get_tree().create_timer(0.55).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Include it in a rectangle to balance the sum..."
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.306, 0.647, 0.518, 0.40)
		instruction_label.text = "Sum = 10!  +3 bonus for using a Negative tile."
		_float_text("+10", ThemeTokens.NEG_DARK)
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles(target, gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()
		await get_tree().create_timer(2.5).timeout


# ══════════════════════════════════════════════
# TUTORIAL 4 — MYSTERY TILE
# Board:  2 3 5 / 4 ? 6 / 7 8 9   (? = 1)
# ══════════════════════════════════════════════

func _run_mystery(gen: int):
	var MPOS         := Vector2(1, 1)
	var hidden_value := 1
	var target       := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout := {
			Vector2(0,0): 2, Vector2(1,0): 3, Vector2(2,0): 5,
			Vector2(0,1): 4,                  Vector2(2,1): 6,
			Vector2(0,2): 7, Vector2(1,2): 8, Vector2(2,2): 9,
		}
		for pos in layout:
			_spawn_tile(pos, layout[pos])
		_spawn_tile(MPOS, 0, ThemeTokens.MYSTERY_BG, ThemeTokens.MYSTERY_TEXT)
		if _tile_labels.has(MPOS):
			_tile_labels[MPOS].text = "?"

		step_label.text = "Mystery Tile"
		instruction_label.text = "This tile hides its value behind a '?'."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Touch or drag over it to reveal the number!"
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		var px_m := _grid_px(MPOS)
		cursor_dot.size = Vector2(24, 24)
		cursor_dot.position = px_m - Vector2(12, 12)
		cursor_dot.modulate.a = 0.0
		cursor_dot.show()
		var tw_in := create_tween()
		tw_in.tween_property(cursor_dot, "modulate:a", 1.0, 0.25)
		await tw_in.finished
		if gen != _demo_gen: return

		if _tile_styles.has(MPOS):
			var tw_flash := create_tween()
			tw_flash.tween_property(_tile_styles[MPOS], "bg_color", Color(0.62, 0.68, 0.64), 0.15)
			tw_flash.tween_property(_tile_styles[MPOS], "bg_color", ThemeTokens.MYSTERY_REV_BG, 0.15)
			await tw_flash.finished
		if _tile_labels.has(MPOS):
			_tile_labels[MPOS].text = str(hidden_value)
			_tile_labels[MPOS].add_theme_color_override("font_color", ThemeTokens.MYSTERY_REV_TEXT)
		if gen != _demo_gen: return

		instruction_label.text = "Revealed!  Now you can plan your move."
		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		var tw_out := create_tween()
		tw_out.tween_property(cursor_dot, "modulate:a", 0.0, 0.20)
		await tw_out.finished
		cursor_dot.hide()
		if gen != _demo_gen: return

		await get_tree().create_timer(0.5).timeout
		if gen != _demo_gen: return

		instruction_label.text = "2 + 3 + 4 + 1 = 10"
		for _i in 3:
			for pos in target:
				if _tile_styles.has(pos):
					var c_hi := Color(0.55, 0.62, 0.58)      if pos == MPOS else ThemeTokens.MINT_SOFT
					var c_lo := ThemeTokens.MYSTERY_REV_BG   if pos == MPOS else ThemeTokens.TILE_WHITE
					var tw := create_tween()
					tw.tween_property(_tile_styles[pos], "bg_color", c_hi, 0.20)
					tw.tween_property(_tile_styles[pos], "bg_color", c_lo, 0.20)
			await get_tree().create_timer(0.55).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Select the rectangle..."
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.306, 0.647, 0.518, 0.40)
		instruction_label.text = "Sum = 10!  +2 bonus for the Mystery tile."
		_float_text("+10", ThemeTokens.MYSTERY_REV_BG)
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles(target, gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()
		await get_tree().create_timer(2.5).timeout


# ══════════════════════════════════════════════
# TUTORIAL 5 — JOKER TILE
# Board:  3 2 5 / J 1 8 / 7 6 9   (J at (0,1))
# ══════════════════════════════════════════════

func _run_joker(gen: int):
	var JPOS       := Vector2(0, 1)
	var joker_fill := 4
	var target     := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout := {
			Vector2(0,0): 3, Vector2(1,0): 2, Vector2(2,0): 5,
							 Vector2(1,1): 1, Vector2(2,1): 8,
			Vector2(0,2): 7, Vector2(1,2): 6, Vector2(2,2): 9,
		}
		for pos in layout:
			_spawn_tile(pos, layout[pos])
		_spawn_tile(JPOS, 0, ThemeTokens.JOKER_B, ThemeTokens.JOKER_INK)
		if _tile_labels.has(JPOS):
			_tile_labels[JPOS].text = "★"

		step_label.text = "Joker Tile"
		instruction_label.text = "The golden ★ tile is a Joker."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "While selecting, Joker counts as 0."
		if _tile_styles.has(JPOS):
			var tw := create_tween()
			tw.tween_property(_tile_styles[JPOS], "bg_color", ThemeTokens.JOKER_A, 0.18)
			tw.tween_property(_tile_styles[JPOS], "bg_color", ThemeTokens.JOKER_B, 0.18)
			await tw.finished
		if _tile_labels.has(JPOS):
			_tile_labels[JPOS].text = "0"
		if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		instruction_label.text = "3 + 2 + 0 + 1 = 6 — not 10 yet..."
		for _i in 2:
			for pos in target:
				if _tile_styles.has(pos):
					var c_hi := ThemeTokens.JOKER_A    if pos == JPOS else ThemeTokens.MINT_SOFT
					var c_lo := ThemeTokens.JOKER_B    if pos == JPOS else ThemeTokens.TILE_WHITE
					var tw := create_tween()
					tw.tween_property(_tile_styles[pos], "bg_color", c_hi, 0.20)
					tw.tween_property(_tile_styles[pos], "bg_color", c_lo, 0.20)
			await get_tree().create_timer(0.60).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.2).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Drag the rectangle — Joker fills the gap!"
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(0.8).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Gap detected: needs %d more to reach 10!" % joker_fill
		await get_tree().create_timer(1.2).timeout
		if gen != _demo_gen: return

		if _tile_rects.has(JPOS) and _tile_styles.has(JPOS):
			var tw_morph := create_tween().set_parallel(true)
			tw_morph.tween_property(_tile_styles[JPOS], "bg_color", ThemeTokens.JOKER_A, 0.15)
			tw_morph.tween_property(_tile_rects[JPOS],  "scale",    Vector2(1.25, 1.25), 0.15)
			await tw_morph.finished
			var tw_back := create_tween().set_parallel(true)
			tw_back.tween_property(_tile_styles[JPOS], "bg_color", ThemeTokens.JOKER_B, 0.20)
			tw_back.tween_property(_tile_rects[JPOS],  "scale",    Vector2(1.0, 1.0),   0.20)
			await tw_back.finished
		if _tile_labels.has(JPOS):
			_tile_labels[JPOS].text = str(joker_fill)
		if gen != _demo_gen: return

		await get_tree().create_timer(0.6).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.306, 0.647, 0.518, 0.40)
		instruction_label.text = "Joker becomes %d — Sum = 10!  +5 bonus." % joker_fill
		_float_text("+10", ThemeTokens.JOKER_STROKE)
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles(target, gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()
		await get_tree().create_timer(2.5).timeout
