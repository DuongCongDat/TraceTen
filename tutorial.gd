extends Control

signal close_requested

const TUTORIALS = [
	{
		"id": "howtoplay",
		"name": "How to Play",
		"desc": "Select a rectangle where tiles sum to 10",
		"thumb_color": Color(0.22, 0.50, 0.90),
		"thumb_icon": "▶",
	},
	{
		"id": "virus",
		"name": "Virus Tile",
		"desc": "Defuse the blue tile before it explodes!",
		"thumb_color": Color(0.12, 0.68, 0.42),
		"thumb_icon": "!",
	},
	{
		"id": "negative",
		"name": "Negative Tile",
		"desc": "Use minus values to balance the sum to 10",
		"thumb_color": Color(0.72, 0.15, 0.15),
		"thumb_icon": "−",
	},
	{
		"id": "mystery",
		"name": "Mystery Tile",
		"desc": "Touch it to reveal the hidden number",
		"thumb_color": Color(0.45, 0.28, 0.72),
		"thumb_icon": "?",
	},
	{
		"id": "joker",
		"name": "Joker Tile",
		"desc": "It morphs into whatever value you need",
		"thumb_color": Color(0.85, 0.65, 0.10),
		"thumb_icon": "★",
	},
]

const TILE_SIZE   := 100.0
const TILE_NORMAL := Color(0.18, 0.28, 0.42)
const TILE_VIRUS  := Color(0.10, 0.62, 0.38)

var _current_id   := ""
var _demo_gen     := 0  # incremented on every load/replay to cancel old coroutines

var _tile_rects: Dictionary = {}  # Vector2 → ColorRect
var _tile_labels: Dictionary = {}  # Vector2 → Label

@onready var list_layer:        Control    = $ListLayer
@onready var demo_layer:        Control    = $DemoLayer
@onready var card_list:         VBoxContainer = %CardList
@onready var step_label:        Label      = %StepLabel
@onready var instruction_label: Label      = %InstructionLabel
@onready var board_container:   Node2D     = %BoardContainer
@onready var selection_box:     ColorRect  = %SelectionBox
@onready var cursor_dot:        ColorRect  = %CursorDot


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_populate_card_list()
	_maybe_show_timer_warning()


func _maybe_show_timer_warning():
	if get_parent() == get_tree().root:
		return
	if Global.selected_mode not in ["CLASSIC", "GRAVITY"]:
		return
	var lbl := Label.new()
	lbl.text = "⚠  Timer is still running!"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
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
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 96)
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_theme_constant_override("separation", 16)

	# Thumbnail
	var thumb = ColorRect.new()
	thumb.custom_minimum_size = Vector2(80, 80)
	thumb.color = t.thumb_color
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon = Label.new()
	icon.text = t.thumb_icon
	icon.add_theme_font_size_override("font_size", 40)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_child(icon)
	hbox.add_child(thumb)

	# Text
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_lbl = Label.new()
	name_lbl.text = t.name
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var desc_lbl = Label.new()
	desc_lbl.text = t.desc
	desc_lbl.add_theme_font_size_override("font_size", 22)
	desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)
	vbox.add_child(desc_lbl)
	hbox.add_child(vbox)

	# Arrow
	var arrow = Label.new()
	arrow.text = " ›"
	arrow.add_theme_font_size_override("font_size", 40)
	arrow.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(arrow)

	var tid = t.id
	hbox.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_load_demo(tid)
	)
	return hbox


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
	var gen = _demo_gen

	list_layer.hide()
	demo_layer.show()
	_clear_board()
	selection_box.hide()
	cursor_dot.hide()

	# Center board on screen, leaving room for labels above and buttons below
	var screen = get_viewport_rect().size
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


# Spawns a visual tile at grid position (centered at board_container origin = grid center)
func _spawn_tile(gpos: Vector2, value: int, color: Color = TILE_NORMAL):
	var offset = (gpos - Vector2(1, 1)) * TILE_SIZE
	var rect = ColorRect.new()
	rect.size = Vector2(TILE_SIZE - 8, TILE_SIZE - 8)
	rect.position = offset - rect.size / 2.0
	rect.color = color
	board_container.add_child(rect)

	var lbl = Label.new()
	lbl.text = str(value)
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.add_child(lbl)

	_tile_rects[gpos]  = rect
	_tile_labels[gpos] = lbl


# Returns the screen-space center of a grid cell
func _grid_px(gpos: Vector2) -> Vector2:
	return board_container.position + (gpos - Vector2(1, 1)) * TILE_SIZE


# Animate-fade tiles at given positions, then remove them
func _pop_tiles(positions: Array, gen: int) -> void:
	for pos in positions:
		if _tile_rects.has(pos):
			var tw = create_tween()
			tw.tween_property(_tile_rects[pos], "modulate:a", 0.0, 0.35)
	await get_tree().create_timer(0.45).timeout
	if gen != _demo_gen: return
	for pos in positions:
		if _tile_rects.has(pos):
			_tile_rects[pos].queue_free()
			_tile_rects.erase(pos)
			_tile_labels.erase(pos)


# Floating text burst (in demo screen space)
func _float_text(msg: String, color: Color = Color.YELLOW):
	var screen = get_viewport_rect().size
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(320, 80)
	lbl.position = Vector2(screen.x / 2.0 - 160.0, screen.y / 2.0 - 60.0)
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position", lbl.position - Vector2(0, 90), 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)


# ── Cursor drag animation helper ──
# Animates cursor + selection box growing from start to end grid cells
func _animate_drag(start: Vector2, end: Vector2, duration: float) -> void:
	var px_start = _grid_px(start)
	var px_end   = _grid_px(end)
	var cols = int(abs(end.x - start.x)) + 1
	var rows = int(abs(end.y - start.y)) + 1
	var sel_tl = _grid_px(Vector2(min(start.x, end.x), min(start.y, end.y))) \
				 - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

	# Place cursor at start, fade in
	cursor_dot.size = Vector2(24, 24)
	cursor_dot.position = px_start - Vector2(12, 12)
	cursor_dot.modulate.a = 0.0
	cursor_dot.show()
	var tw_in = create_tween()
	tw_in.tween_property(cursor_dot, "modulate:a", 1.0, 0.25)
	await tw_in.finished

	# Init selection box at start tile
	selection_box.position = sel_tl
	selection_box.size = Vector2(TILE_SIZE, TILE_SIZE)
	selection_box.color = Color(1, 1, 0.467, 0.392)
	selection_box.show()

	# Drag
	var tw = create_tween().set_parallel(true)
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
	var vals = [[2, 3, 5], [1, 4, 6], [7, 8, 9]]
	var target = [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		# Spawn board
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

		# Flash target tiles blue to hint them
		instruction_label.text = "The sum of all tiles inside must equal 10."
		for _i in 3:
			for pos in target:
				if _tile_rects.has(pos):
					var tw = create_tween()
					tw.tween_property(_tile_rects[pos], "color", Color(0.35, 0.55, 0.90), 0.20)
					tw.tween_property(_tile_rects[pos], "color", TILE_NORMAL, 0.20)
			await get_tree().create_timer(0.55).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		# Animate drag
		instruction_label.text = "Drag from one corner to the other..."
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		# Success flash
		selection_box.color = Color(0.20, 1.0, 0.45, 0.50)
		instruction_label.text = "Sum = 10!  Tiles clear and you score."
		_float_text("+10")
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		# Pop tiles
		await _pop_tiles(target, gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()

		await get_tree().create_timer(2.5).timeout


# ══════════════════════════════════════════════
# TUTORIAL 2 — VIRUS TILE
# Part 1: 3→2→1→0 countdown then explosion
# Part 2: save it before it explodes
#
# Part-1 board:  5 2 3 / 4 V 1 / 7 6 8   (V starts at 3)
# Part-2 board:  5 2 3 / 8 V 1 / 7 6 8   (V=2, 8+2=10)
# ══════════════════════════════════════════════

func _run_virus(gen: int):
	var VPOS = Vector2(1, 1)

	while gen == _demo_gen:
		# ── PART 1: countdown + explosion ──
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout1 = {
			Vector2(0,0):5, Vector2(1,0):2, Vector2(2,0):3,
			Vector2(0,1):4, Vector2(2,1):1,
			Vector2(0,2):7, Vector2(1,2):6, Vector2(2,2):8,
		}
		for pos in layout1:
			_spawn_tile(pos, layout1[pos])
		_spawn_tile(VPOS, 3, TILE_VIRUS)

		step_label.text = "Virus Tile  •  1 / 2"
		instruction_label.text = "Every 10s, the Virus changes to a random value."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		# Show random value changes: 3 → 7 → -2 → 0 (BOOM)
		# Each change: pulse green → update number
		var changes = [7, -2, 0]
		var change_msgs = [
			"Could be any number — positive...",
			"...or negative.",
			"If it hits 0 — it EXPLODES!",
		]
		for i in changes.size():
			if gen != _demo_gen: return
			if _tile_rects.has(VPOS):
				var tw = create_tween()
				tw.tween_property(_tile_rects[VPOS], "color", Color(0.4, 1.0, 0.6), 0.18)
				tw.tween_property(_tile_rects[VPOS], "color", TILE_VIRUS, 0.18)
				await tw.finished
			if gen != _demo_gen: return

			if _tile_labels.has(VPOS):
				_tile_labels[VPOS].text = str(changes[i])
			instruction_label.text = change_msgs[i]

			if changes[i] == 0:
				await get_tree().create_timer(0.8).timeout
				if gen != _demo_gen: return

				if _tile_rects.has(VPOS):
					var expl = create_tween()
					expl.tween_property(_tile_rects[VPOS], "scale", Vector2(2.0, 2.0), 0.18)
					expl.tween_property(_tile_rects[VPOS], "modulate:a", 0.0, 0.22)
					await expl.finished
					_tile_rects[VPOS].queue_free()
					_tile_rects.erase(VPOS)
					_tile_labels.erase(VPOS)

				var hole = ColorRect.new()
				hole.size = Vector2(TILE_SIZE - 8, TILE_SIZE - 8)
				hole.position = -hole.size / 2.0
				hole.color = Color(0.05, 0.05, 0.08)
				board_container.add_child(hole)
				var x_lbl = Label.new()
				x_lbl.text = "✕"
				x_lbl.add_theme_font_size_override("font_size", 38)
				x_lbl.add_theme_color_override("font_color", Color(0.75, 0.18, 0.18))
				x_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				x_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				x_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				hole.add_child(x_lbl)

				instruction_label.text = "Leaves a permanent hole in the board!"
				await get_tree().create_timer(3.0).timeout
				if gen != _demo_gen: return
			else:
				await get_tree().create_timer(1.8).timeout

		if gen != _demo_gen: return
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		# ── PART 2: clear it in time ──
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout2 = {
			Vector2(0,0):5, Vector2(1,0):2, Vector2(2,0):3,
			Vector2(0,1):8, Vector2(2,1):1,
			Vector2(0,2):7, Vector2(1,2):6, Vector2(2,2):8,
		}
		for pos in layout2:
			_spawn_tile(pos, layout2[pos])
		_spawn_tile(VPOS, 2, TILE_VIRUS)

		step_label.text = "Virus Tile  •  2 / 2"
		instruction_label.text = "Clear it in time — include it in a valid rectangle!"
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		# Urgency pulses
		for _i in 4:
			if gen != _demo_gen: return
			if _tile_rects.has(VPOS):
				var tw = create_tween()
				tw.tween_property(_tile_rects[VPOS], "color", Color(0.7, 1.0, 0.3), 0.18)
				tw.tween_property(_tile_rects[VPOS], "color", TILE_VIRUS, 0.18)
				await tw.finished
			await get_tree().create_timer(0.15).timeout
		if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Select it with tiles that make the sum 10."
		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		await _animate_drag(Vector2(0, 1), Vector2(1, 1), 0.85)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.20, 1.0, 0.45, 0.50)
		instruction_label.text = "Virus cleared!  +10 bonus for the save."
		_float_text("+10", Color(0.3, 1.0, 0.5))
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles([Vector2(0, 1), VPOS], gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()

		await get_tree().create_timer(2.5).timeout


# ══════════════════════════════════════════════
# TUTORIAL 3 — NEGATIVE TILE
# Board:  1 5 2 / 7 N 4 / 6 8 9   (N = -3, red)
# Target: (0,0)→(1,1) = 1+5+7+(-3) = 10
# ══════════════════════════════════════════════

func _run_negative(gen: int):
	const TILE_NEGATIVE := Color(0.72, 0.15, 0.15)
	var NPOS   := Vector2(1, 1)
	var target := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout = {
			Vector2(0,0): 1, Vector2(1,0): 5, Vector2(2,0): 2,
			Vector2(0,1): 7,                  Vector2(2,1): 4,
			Vector2(0,2): 6, Vector2(1,2): 8, Vector2(2,2): 9,
		}
		for pos in layout:
			_spawn_tile(pos, layout[pos])
		_spawn_tile(NPOS, -3, TILE_NEGATIVE)

		step_label.text = "Negative Tile"
		instruction_label.text = "Red tiles carry a negative value."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		# Pulse the negative tile to draw attention
		instruction_label.text = "They look dangerous — but they're useful!"
		for _i in 3:
			if gen != _demo_gen: return
			if _tile_rects.has(NPOS):
				var tw = create_tween()
				tw.tween_property(_tile_rects[NPOS], "color", Color(1.0, 0.4, 0.4), 0.20)
				tw.tween_property(_tile_rects[NPOS], "color", TILE_NEGATIVE, 0.20)
				await tw.finished
			await get_tree().create_timer(0.25).timeout
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		# Flash the whole target group and show the sum
		instruction_label.text = "1 + 5 + 7 + (−3) = 10"
		for _i in 3:
			for pos in target:
				if _tile_rects.has(pos):
					var c_hi = Color(1.0, 0.4, 0.4) if pos == NPOS else Color(0.35, 0.55, 0.90)
					var c_lo = TILE_NEGATIVE        if pos == NPOS else TILE_NORMAL
					var tw = create_tween()
					tw.tween_property(_tile_rects[pos], "color", c_hi, 0.20)
					tw.tween_property(_tile_rects[pos], "color", c_lo, 0.20)
			await get_tree().create_timer(0.55).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		# Animate drag
		instruction_label.text = "Include it in a rectangle to balance the sum..."
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.20, 1.0, 0.45, 0.50)
		instruction_label.text = "Sum = 10!  +3 bonus for using a Negative tile."
		_float_text("+10", Color(1.0, 0.55, 0.55))
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
# Touch ? to reveal → Target: (0,0)→(1,1) = 2+3+4+1 = 10
# ══════════════════════════════════════════════

func _run_mystery(gen: int):
	const TILE_MYSTERY := Color(0.45, 0.28, 0.72)
	var MPOS          := Vector2(1, 1)
	var hidden_value  := 1
	var target        := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout = {
			Vector2(0,0): 2, Vector2(1,0): 3, Vector2(2,0): 5,
			Vector2(0,1): 4,                  Vector2(2,1): 6,
			Vector2(0,2): 7, Vector2(1,2): 8, Vector2(2,2): 9,
		}
		for pos in layout:
			_spawn_tile(pos, layout[pos])
		_spawn_tile(MPOS, 0, TILE_MYSTERY)
		if _tile_labels.has(MPOS):
			_tile_labels[MPOS].text = "?"

		step_label.text = "Mystery Tile"
		instruction_label.text = "This tile hides its value behind a '?'."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		instruction_label.text = "Touch or drag over it to reveal the number!"
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		# Move cursor to mystery tile (no selection box)
		var px_m = _grid_px(MPOS)
		cursor_dot.size = Vector2(24, 24)
		cursor_dot.position = px_m - Vector2(12, 12)
		cursor_dot.modulate.a = 0.0
		cursor_dot.show()
		var tw_in = create_tween()
		tw_in.tween_property(cursor_dot, "modulate:a", 1.0, 0.25)
		await tw_in.finished
		if gen != _demo_gen: return

		# Flash and reveal
		if _tile_rects.has(MPOS):
			var tw_flash = create_tween()
			tw_flash.tween_property(_tile_rects[MPOS], "color", Color(0.85, 0.75, 1.0), 0.15)
			tw_flash.tween_property(_tile_rects[MPOS], "color", TILE_MYSTERY, 0.15)
			await tw_flash.finished
		if _tile_labels.has(MPOS):
			_tile_labels[MPOS].text = str(hidden_value)
		if gen != _demo_gen: return

		instruction_label.text = "Revealed!  Now you can plan your move."
		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		# Fade out cursor before dragging
		var tw_out = create_tween()
		tw_out.tween_property(cursor_dot, "modulate:a", 0.0, 0.20)
		await tw_out.finished
		cursor_dot.hide()
		if gen != _demo_gen: return

		await get_tree().create_timer(0.5).timeout
		if gen != _demo_gen: return

		# Flash target group + show sum
		instruction_label.text = "2 + 3 + 4 + 1 = 10"
		for _i in 3:
			for pos in target:
				if _tile_rects.has(pos):
					var c_hi = Color(0.75, 0.55, 1.0) if pos == MPOS else Color(0.35, 0.55, 0.90)
					var c_lo = TILE_MYSTERY           if pos == MPOS else TILE_NORMAL
					var tw = create_tween()
					tw.tween_property(_tile_rects[pos], "color", c_hi, 0.20)
					tw.tween_property(_tile_rects[pos], "color", c_lo, 0.20)
			await get_tree().create_timer(0.55).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		# Animate drag
		instruction_label.text = "Select the rectangle..."
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(1.0).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.20, 1.0, 0.45, 0.50)
		instruction_label.text = "Sum = 10!  +2 bonus for the Mystery tile."
		_float_text("+10", Color(0.75, 0.55, 1.0))
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
# Phase 1: Joker shows "J" → counts as 0 while selecting
# Phase 2: after drag (0,0)→(1,1), Joker morphs 0→4, sum = 10
# ══════════════════════════════════════════════

func _run_joker(gen: int):
	const TILE_JOKER := Color(0.85, 0.65, 0.10)
	var JPOS         := Vector2(0, 1)
	var joker_fill   := 4
	var target       := [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]

	while gen == _demo_gen:
		_clear_board()
		selection_box.hide()
		cursor_dot.hide()

		var layout = {
			Vector2(0,0): 3, Vector2(1,0): 2, Vector2(2,0): 5,
							 Vector2(1,1): 1, Vector2(2,1): 8,
			Vector2(0,2): 7, Vector2(1,2): 6, Vector2(2,2): 9,
		}
		for pos in layout:
			_spawn_tile(pos, layout[pos])
		_spawn_tile(JPOS, 0, TILE_JOKER)
		if _tile_labels.has(JPOS):
			_tile_labels[JPOS].text = "★"

		step_label.text = "Joker Tile"
		instruction_label.text = "The golden ★ tile is a Joker."
		await get_tree().create_timer(2.0).timeout
		if gen != _demo_gen: return

		# Phase 1: reveal it counts as 0
		instruction_label.text = "While selecting, Joker counts as 0."
		if _tile_rects.has(JPOS):
			var tw = create_tween()
			tw.tween_property(_tile_rects[JPOS], "color", Color(1.0, 0.95, 0.5), 0.18)
			tw.tween_property(_tile_rects[JPOS], "color", TILE_JOKER, 0.18)
			await tw.finished
		if _tile_labels.has(JPOS):
			_tile_labels[JPOS].text = "0"
		if gen != _demo_gen: return

		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		# Show formula with Joker as 0
		instruction_label.text = "3 + 2 + 0 + 1 = 6 — not 10 yet..."
		for _i in 2:
			for pos in target:
				if _tile_rects.has(pos):
					var c_hi = Color(1.0, 0.95, 0.5) if pos == JPOS else Color(0.35, 0.55, 0.90)
					var c_lo = TILE_JOKER             if pos == JPOS else TILE_NORMAL
					var tw = create_tween()
					tw.tween_property(_tile_rects[pos], "color", c_hi, 0.20)
					tw.tween_property(_tile_rects[pos], "color", c_lo, 0.20)
			await get_tree().create_timer(0.60).timeout
			if gen != _demo_gen: return

		await get_tree().create_timer(1.2).timeout
		if gen != _demo_gen: return

		# Animate drag
		instruction_label.text = "Drag the rectangle — Joker fills the gap!"
		await _animate_drag(Vector2(0, 0), Vector2(1, 1), 1.0)
		if gen != _demo_gen: return

		await get_tree().create_timer(0.8).timeout
		if gen != _demo_gen: return

		# Phase 2: Joker morphs to fill value
		instruction_label.text = "Gap detected: needs %d more to reach 10!" % joker_fill
		await get_tree().create_timer(1.2).timeout
		if gen != _demo_gen: return

		# Morph animation: scale punch + color flash simultaneously
		if _tile_rects.has(JPOS):
			var tw_morph = create_tween().set_parallel(true)
			tw_morph.tween_property(_tile_rects[JPOS], "color", Color(1.0, 1.0, 0.6), 0.15)
			tw_morph.tween_property(_tile_rects[JPOS], "scale", Vector2(1.25, 1.25), 0.15)
			await tw_morph.finished
			var tw_back = create_tween().set_parallel(true)
			tw_back.tween_property(_tile_rects[JPOS], "color", TILE_JOKER, 0.20)
			tw_back.tween_property(_tile_rects[JPOS], "scale", Vector2(1.0, 1.0), 0.20)
			await tw_back.finished
		if _tile_labels.has(JPOS):
			_tile_labels[JPOS].text = str(joker_fill)
		if gen != _demo_gen: return

		await get_tree().create_timer(0.6).timeout
		if gen != _demo_gen: return

		selection_box.color = Color(0.20, 1.0, 0.45, 0.50)
		instruction_label.text = "Joker becomes %d — Sum = 10!  +5 bonus." % joker_fill
		_float_text("+10", Color(1.0, 0.88, 0.3))
		await get_tree().create_timer(1.5).timeout
		if gen != _demo_gen: return

		await _pop_tiles(target, gen)
		if gen != _demo_gen: return

		cursor_dot.hide()
		selection_box.hide()

		await get_tree().create_timer(2.5).timeout
