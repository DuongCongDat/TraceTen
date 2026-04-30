extends Node2D

var grid_cols = 8
var grid_rows = 12
var tile_size = 105
var start_pos = Vector2.ZERO

var tiles = {}

var gameplay_mode = ""
var game_start_time = 0.0
var total_duration = 120.0
var accumulated_time = 0.0
var is_game_over = false
var is_paused = false

# --- POWER-UPS (counts, stackable in Zen) ---
var hint_count = 1
var shuffle_count = 1   # Gravity: starts at 3 (lives)
var remove_count = 1
var is_remove_mode = false

var score = 0
var max_combo = 1

# --- COMBO SYSTEM ---
var combo_count = 1
var last_score_time = 0.0
const COMBO_TIMEOUT = 5.0

# --- TILE VISUAL ---
const BASE_TILE_SIZE  = 105.0
const TILE_VISUAL_RATIO = 0.90  # tiles render at 90% of cell → ~10% gap between tiles

# --- GRAVITY SYSTEM ---
var gravity_level = 1
const GRAVITY_LEVEL_SCORE = 50  # score needed to advance each level
const GRAVITY_TIME_PER_TILE = 1.0  # +seconds per tile eaten in Gravity mode

# --- DEBUG ---
const DEBUG_MODE = true

# --- ZEN MILESTONE REFILL ---
var zen_milestone_count = 0
const ZEN_REFILL_MILESTONE = 100

var current_mode = "RECTANGLE"

var unlocked_modes = ["CLASSIC"]
var seen_tutorials = {
	"CLASSIC": false,
	"GRAVITY": false,
	"ZEN": false,
	"MUTATION": false
}

var tutorial_texts = {
	"CLASSIC": [
		"Welcome to TraceTen!\n\nHow to play: Drag to select a rectangle of tiles. If the sum equals exactly 10, you score!",
		"You have 120 seconds!\nThe timer bar at the top drains down — keep moving!",
		"Power-ups (1 use each):\nHint — highlights a valid move.\nShuffle — scrambles the board.\nRemove — deletes one tile."
	],
	"GRAVITY": [
		"Gravity Mode!\n\nAfter each score, tiles fall to fill the gaps. No new tiles appear — plan carefully!",
		"3 lives (♥♥♥): each Shuffle costs 1 life.\nRun out of lives OR time = GAME OVER.\nGravity direction changes every 50 points.",
		"Levels: L1 Down → L2 Right → L3 Left → L4 Outward\nEat more tiles at once to earn bonus seconds!"
	],
	"MUTATION": [
		"Mutation Mode!\n\nRed tiles carry negative values — use them to balance large positives.",
		"Mystery tile (?): reveals its value when touched.\nJoker tile: adapts to make the sum exactly 10 (range −9 to 9).",
		"Virus (blue): changes value every 5 s. Hits 0 → explodes, leaving a permanent hole!"
	],
	"ZEN": [
		"Zen Mode!\n\nNo time limit. Play at your own pace and aim for a high score.",
		"Board refills automatically when 70% cleared.\nEvery 100 points, all power-ups restore once — and they stack!"
	]
}

var current_tutorial_step = 0
var is_tutorial_active = false

@onready var selection_box = $SelectionBox
@onready var trace_line = $DrawLine
@onready var pause_menu = $PauseMenuLayer
@onready var time_bar = $TimeBar
@onready var score_label = $ScoreLabel
@onready var combo_label = $ComboLabel
@onready var lives_label = $LivesLabel
@onready var gravity_level_label = $GravityLevelLabel

var is_dragging = false
var drag_start_grid = Vector2.ZERO
var selected_tiles = []
var vertex_path = []

# ==========================================
# INIT
# ==========================================
func _ready():
	gameplay_mode = Global.selected_mode
	print("Mode: ", gameplay_mode)

	if selection_box: selection_box.visible = false
	if trace_line: trace_line.clear_points()

	var screen_w = get_viewport_rect().size.x
	var screen_h = get_viewport_rect().size.y

	# Compute tile_size to fit within screen, leaving room for UI top/bottom
	var ui_top    = 130.0
	var ui_bottom = 60.0
	var avail_w   = screen_w * 0.90  # 10% horizontal margin (increased from 5%)
	var avail_h   = screen_h - ui_top - ui_bottom
	tile_size = int(min(floor(avail_w / grid_cols), floor(avail_h / grid_rows)))
	tile_size = min(tile_size, 105)  # cap at original size

	var total_w = grid_cols * tile_size
	var total_h = grid_rows * tile_size
	start_pos.x = (screen_w - total_w) / 2.0 + tile_size / 2.0
	start_pos.y = ui_top + (avail_h - total_h) / 2.0 + tile_size / 2.0

	score = 0
	update_score_ui()

	setup_mode_config()
	spawn_grid()
	$TutorialLayer.hide()
	start_time_attack_game()
	_init_debug_ui()


func setup_mode_config():
	hint_count   = 1
	remove_count = 1
	max_combo    = 1
	gravity_level      = 1
	zen_milestone_count = 0

	match gameplay_mode:
		"GRAVITY":
			shuffle_count = 3
			total_duration = 150.0
			time_bar.show()
			time_bar.max_value = total_duration
			lives_label.show()
			gravity_level_label.show()
			update_lives_ui()
			update_gravity_level_ui()
		"CLASSIC":
			shuffle_count = 1
			total_duration = 120.0
			time_bar.show()
			time_bar.max_value = total_duration
			lives_label.hide()
			gravity_level_label.hide()
		_:  # ZEN, MUTATION
			shuffle_count = 1
			total_duration = 120.0
			time_bar.hide()
			lives_label.hide()
			gravity_level_label.hide()

	update_power_up_ui()


# ==========================================
# BOARD GENERATION
# ==========================================
func spawn_grid():
	# For Classic, retry until board has at least one valid move
	for attempt in range(5):
		for x in range(grid_cols):
			for y in range(grid_rows):
				spawn_single_tile(x, y)

		if gameplay_mode != "CLASSIC" or scan_board_for_valid_moves():
			return

		for pos in tiles.keys():
			tiles[pos].queue_free()
		tiles.clear()


func spawn_single_tile(x, y):
	var spawn_pos = Vector2(x, y)
	var rolled = TileFactory.roll(gameplay_mode)
	var new_tile = TileFactory.make(rolled.type)
	new_tile.position = start_pos + Vector2(x * tile_size, y * tile_size)
	new_tile.scale = _tile_normal_scale()
	add_child(new_tile)
	new_tile.set_data(spawn_pos, rolled.val, rolled.type)
	tiles[spawn_pos] = new_tile
	return new_tile


func _tile_normal_scale() -> Vector2:
	var s = (tile_size / BASE_TILE_SIZE) * TILE_VISUAL_RATIO
	return Vector2(s, s)


# ==========================================
# INPUT
# ==========================================
func _input(event):
	if is_game_over or is_paused: return
	if current_mode == "RECTANGLE":
		handle_rectangle_input(event)
	elif current_mode == "TRACE":
		handle_trace_input(event)


func handle_rectangle_input(event):
	if is_tutorial_active: return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			var touch_grid = pixel_to_grid(event.position)

			if is_remove_mode:
				if is_within_grid(touch_grid) and tiles.has(touch_grid):
					tiles[touch_grid].queue_free()
					tiles.erase(touch_grid)
					is_remove_mode = false
					remove_count -= 1
					if gameplay_mode == "GRAVITY":
						apply_gravity()
					update_power_up_ui()
					await get_tree().create_timer(0.5).timeout
					check_end_game()
				return

			if is_within_grid(touch_grid):
				is_dragging = true
				drag_start_grid = touch_grid
				selection_box.visible = true
				update_selection(event.position)
		else:
			is_dragging = false
			selection_box.visible = false
			evaluate_selection()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			update_selection(event.position)


func pixel_to_grid(pixel_pos: Vector2) -> Vector2:
	var top_left = start_pos - Vector2(tile_size / 2.0, tile_size / 2.0)
	return Vector2(
		floor((pixel_pos.x - top_left.x) / tile_size),
		floor((pixel_pos.y - top_left.y) / tile_size)
	)


func update_selection(touch_pos: Vector2):
	var cur = pixel_to_grid(touch_pos)
	var min_x = min(drag_start_grid.x, cur.x)
	var max_x = max(drag_start_grid.x, cur.x)
	var min_y = min(drag_start_grid.y, cur.y)
	var max_y = max(drag_start_grid.y, cur.y)

	var tl_pixel = start_pos + Vector2(min_x * tile_size, min_y * tile_size) - Vector2(tile_size / 2.0, tile_size / 2.0)
	selection_box.position = tl_pixel
	selection_box.size = Vector2((max_x - min_x + 1) * tile_size, (max_y - min_y + 1) * tile_size)

	for pos in selected_tiles:
		if tiles.has(pos): tiles[pos].deselect()
	selected_tiles.clear()

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2(x, y)
			if tiles.has(pos):
				selected_tiles.append(pos)
				tiles[pos].select()

	var current_sum = 0
	for pos in selected_tiles:
		current_sum += tiles[pos].get_effective_value()

	var sum_label = selection_box.get_node("SumLabel")
	sum_label.text = str(current_sum)
	sum_label.position.x = (selection_box.size.x - sum_label.size.x) / 2.0
	sum_label.position.y = -60

	if current_sum == 10:
		sum_label.add_theme_color_override("font_color", Color.GREEN)
	elif current_sum > 10:
		sum_label.add_theme_color_override("font_color", Color.RED)
	else:
		sum_label.add_theme_color_override("font_color", Color.WHITE)


# ==========================================
# SELECTION EVALUATION
# ==========================================
func evaluate_selection():
	if selected_tiles.size() == 0: return

	var total_sum = 0
	var has_joker = false

	for pos in selected_tiles:
		var t = tiles[pos]
		if t.tile_type == "JOKER":
			has_joker = true
		total_sum += t.get_effective_value()

	if has_joker and selected_tiles.size() > 1:
		var needed = 10 - total_sum
		if needed >= -9 and needed <= 9:
			total_sum = 10
		else:
			total_sum = 999
			show_floating_text_center("OVERLOAD")

	if total_sum == 10:
		var used_combo = combo_count
		var points_earned = calculate_points(selected_tiles)
		score += points_earned
		update_score_ui()
		show_floating_score(points_earned, used_combo)

		# Combo applies to ALL modes using real-time clock
		var now = Time.get_unix_time_from_system()
		if last_score_time > 0 and now - last_score_time <= COMBO_TIMEOUT:
			combo_count += 1
		else:
			combo_count = 1
		last_score_time = now
		update_combo_ui()

		if combo_count > max_combo:
			max_combo = combo_count

		var eaten_count = selected_tiles.size()  # capture before clear

		for pos in selected_tiles:
			if tiles.has(pos):
				tiles[pos].queue_free()
				tiles.erase(pos)

		selected_tiles.clear()

		match gameplay_mode:
			"GRAVITY":
				# Add time bonus: +1s per tile eaten
				var bonus = eaten_count * GRAVITY_TIME_PER_TILE
				total_duration += bonus
				if time_bar: time_bar.max_value = total_duration
				_show_time_bonus(bonus)
				check_gravity_level_up()
				apply_gravity()
				await get_tree().create_timer(0.6).timeout
				check_end_game()
			"ZEN", "MUTATION":
				var cleared_pct = 1.0 - float(tiles.size()) / float(grid_rows * grid_cols)
				if cleared_pct >= 0.70:
					_check_zen_milestone()
					refill_empty_slots()
					return  # check_end_game called inside refill_empty_slots
				_check_zen_milestone()
				await get_tree().create_timer(0.5).timeout
				check_end_game()
			_:  # CLASSIC
				await get_tree().create_timer(0.5).timeout
				check_end_game()
	else:
		await get_tree().create_timer(0.3).timeout
		for pos in selected_tiles:
			if tiles.has(pos):
				tiles[pos].deselect()
		selected_tiles.clear()


func _check_zen_milestone():
	if gameplay_mode != "ZEN": return
	var milestone = score / ZEN_REFILL_MILESTONE
	if milestone > zen_milestone_count:
		zen_milestone_count = milestone
		hint_count   += 1
		shuffle_count += 1
		remove_count  += 1
		show_floating_text_center("Power-up +1!", Color.LIME_GREEN)  # green = good news
		update_power_up_ui()


# ==========================================
# END GAME
# ==========================================
func scan_board_for_valid_moves() -> bool:
	return find_hint_path().size() > 0


func check_end_game():
	if gameplay_mode == "ZEN" or is_game_over: return
	if hint_count > 0 or shuffle_count > 0 or remove_count > 0: return
	if not scan_board_for_valid_moves():
		trigger_end_game("NO_MOVES")


func trigger_end_game(reason: String):
	if is_game_over: return
	is_game_over = true

	var reason_text: String
	match reason:
		"TIME_UP":   reason_text = "Time's Up!"
		"NO_MOVES":  reason_text = "No Moves Left!"
		"NO_LIVES":  reason_text = "No Lives Left!"
		"LEFT":      reason_text = "You Left"
		_:           reason_text = "Game Over"

	var time_played: float
	if gameplay_mode in ["CLASSIC", "GRAVITY"]:
		time_played = min(Time.get_unix_time_from_system() - game_start_time, total_duration)
	else:
		time_played = accumulated_time

	$GameOverLayer/VBoxContainer/ResultLabel.text     = reason_text
	$GameOverLayer/VBoxContainer/FinalScoreLabel.text = "Score: " + str(score)
	$GameOverLayer/VBoxContainer/TimePlayedLabel.text = "Time: " + format_time_mmss(time_played)
	$GameOverLayer/VBoxContainer/MaxComboLabel.text   = "Best Combo: x" + str(max_combo)
	$GameOverLayer.show()

	if gameplay_mode == "CLASSIC" and score >= 100:
		if not "GRAVITY" in unlocked_modes:
			unlocked_modes.append("GRAVITY")
			print("Đã mở khóa Gravity mode!")


func on_time_up():
	trigger_end_game("TIME_UP")


# ==========================================
# GRAVITY LEVELS
# ==========================================
func check_gravity_level_up():
	if gameplay_mode != "GRAVITY": return
	var new_level = min(4, 1 + score / GRAVITY_LEVEL_SCORE)
	if new_level > gravity_level:
		gravity_level = new_level
		show_floating_text_center("LEVEL " + str(gravity_level) + "!")
		update_gravity_level_ui()


func get_gravity_direction() -> String:
	match gravity_level:
		1: return "DOWN"
		2: return "RIGHT"
		3: return "LEFT"
		_: return "RADIAL"


func apply_gravity():
	await get_tree().create_timer(0.2).timeout
	match get_gravity_direction():
		"DOWN":   _apply_gravity_down()
		"RIGHT":  _apply_gravity_horizontal(true)
		"LEFT":   _apply_gravity_horizontal(false)
		"RADIAL": _apply_gravity_radial()


func _move_tile(from_pos: Vector2, to_pos: Vector2):
	if not tiles.has(from_pos): return
	var tile = tiles[from_pos]
	tiles.erase(from_pos)
	tiles[to_pos] = tile
	tile.set_data(to_pos, tile.value, tile.tile_type)
	var target_pixel = start_pos + Vector2(to_pos.x * tile_size, to_pos.y * tile_size)
	var tween = get_tree().create_tween()
	tween.tween_property(tile, "position", target_pixel, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _apply_gravity_down():
	for x in range(grid_cols):
		var empty = 0
		for y in range(grid_rows - 1, -1, -1):
			var p = Vector2(x, y)
			if not tiles.has(p):
				empty += 1
			elif empty > 0:
				_move_tile(p, Vector2(x, y + empty))


func _apply_gravity_horizontal(fall_right: bool):
	for y in range(grid_rows):
		var empty = 0
		if fall_right:
			for x in range(grid_cols - 1, -1, -1):
				var p = Vector2(x, y)
				if not tiles.has(p):
					empty += 1
				elif empty > 0:
					_move_tile(p, Vector2(x + empty, y))
		else:
			for x in range(grid_cols):
				var p = Vector2(x, y)
				if not tiles.has(p):
					empty += 1
				elif empty > 0:
					_move_tile(p, Vector2(x - empty, y))


func _apply_gravity_radial():
	# Left half (x < 4): tiles fall left toward x=0
	# Right half (x >= 4): tiles fall right toward x=grid_cols-1
	var cx = grid_cols / 2
	for y in range(grid_rows):
		var empty = 0
		for x in range(cx):
			var p = Vector2(x, y)
			if not tiles.has(p):
				empty += 1
			elif empty > 0:
				_move_tile(p, Vector2(x - empty, y))
		empty = 0
		for x in range(grid_cols - 1, cx - 1, -1):
			var p = Vector2(x, y)
			if not tiles.has(p):
				empty += 1
			elif empty > 0:
				_move_tile(p, Vector2(x + empty, y))


# ==========================================
# VIRUS
# ==========================================
func kill_tile_from_virus(pos: Vector2):
	if tiles.has(pos):
		tiles[pos].queue_free()
		tiles.erase(pos)
		print("Virus exploded at ", pos)


# ==========================================
# REFILL (ZEN / MUTATION)
# ==========================================
func refill_empty_slots():
	await get_tree().create_timer(0.4).timeout

	for x in range(grid_cols):
		for y in range(grid_rows):
			var check_pos = Vector2(x, y)
			if not tiles.has(check_pos):
				var rolled = TileFactory.roll(gameplay_mode)
				var new_tile = TileFactory.make(rolled.type)
				new_tile.position = start_pos + Vector2(x * tile_size, y * tile_size)
				new_tile.scale = Vector2(0.05, 0.05)
				add_child(new_tile)
				new_tile.set_data(check_pos, rolled.val, rolled.type)
				tiles[check_pos] = new_tile
				var tween = get_tree().create_tween()
				tween.tween_property(new_tile, "scale", _tile_normal_scale(), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	vertex_path.clear()
	trace_line.clear_points()
	check_end_game()


# ==========================================
# TIMER & PROCESS
# ==========================================
func start_time_attack_game():
	is_game_over = false
	is_paused = false
	game_start_time = Time.get_unix_time_from_system()
	accumulated_time = 0.0
	combo_count = 1
	last_score_time = 0.0
	combo_label.hide()
	$PauseMenuLayer.hide()


func _process(delta):
	if is_game_over or is_tutorial_active: return

	if gameplay_mode in ["CLASSIC", "GRAVITY"]:
		var time_left = max(0.0, total_duration - (Time.get_unix_time_from_system() - game_start_time))
		update_timer_display(time_left)
		if time_bar:
			time_bar.value = time_left
		if time_left <= 0:
			on_time_up()
	else:
		if not is_paused:
			accumulated_time += delta
		update_timer_display(accumulated_time)

	# Combo countdown — all modes
	if combo_count > 1:
		var remaining = COMBO_TIMEOUT - (Time.get_unix_time_from_system() - last_score_time)
		if remaining <= 0:
			combo_count = 1
			combo_label.hide()
		else:
			combo_label.show()
			combo_label.text = "x%d  %.0fs" % [combo_count, ceil(remaining)]


func update_timer_display(seconds: float):
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	$TimeLabel.text = "%02d:%02d" % [mins, secs]


func format_time_mmss(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]


# ==========================================
# PAUSE MENU
# ==========================================
func _on_pause_button_pressed():
	if is_game_over: return
	is_paused = true
	pause_menu.show()


func _on_btn_continue_pressed():
	is_paused = false
	pause_menu.hide()


func _on_btn_restart_pressed():
	is_paused = false
	$PauseMenuLayer.hide()
	_reset_game()


func _on_btn_quit_pressed():
	is_paused = false
	pause_menu.hide()
	if gameplay_mode in ["CLASSIC", "GRAVITY"]:
		trigger_end_game("LEFT")
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_btn_restart_over_pressed():
	$GameOverLayer.hide()
	_reset_game()


func _on_btn_quit_over_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _reset_game():
	score = 0
	is_game_over = false
	accumulated_time = 0.0
	max_combo = 1
	combo_count = 1
	is_remove_mode = false

	for pos in tiles.keys():
		if is_instance_valid(tiles[pos]):
			tiles[pos].queue_free()
	tiles.clear()

	setup_mode_config()
	spawn_grid()
	update_score_ui()
	start_time_attack_game()


# ==========================================
# POWER-UP HANDLERS
# ==========================================
func _on_btn_hint_pressed():
	if hint_count <= 0 or tiles.is_empty(): return

	hint_count -= 1
	update_power_up_ui()

	var found_path = find_hint_path()
	if found_path.size() > 0:
		for pos in found_path:
			if tiles.has(pos):
				var t = tiles[pos]
				var tween = create_tween().set_loops(4)
				tween.tween_property(t, "modulate", Color.CYAN, 0.15)
				tween.parallel().tween_property(t, "scale", _tile_normal_scale() * 1.2, 0.15)
				tween.tween_property(t, "modulate", Color.WHITE, 0.15)
				tween.parallel().tween_property(t, "scale", _tile_normal_scale(), 0.15)
	else:
		show_floating_text_center("NO MOVES LEFT!")

	check_end_game()


func _on_btn_shuffle_pressed():
	if shuffle_count <= 0 or tiles.is_empty(): return

	shuffle_count -= 1

	if gameplay_mode == "GRAVITY":
		update_lives_ui()
		update_power_up_ui()
		if shuffle_count <= 0:
			trigger_end_game("NO_LIVES")
			return
	else:
		update_power_up_ui()

	var tile_data = []
	for pos in tiles.keys():
		var t = tiles[pos]
		tile_data.append({"val": t.value, "type": t.tile_type})
	tile_data.shuffle()

	var i = 0
	for pos in tiles.keys():
		var t = tiles[pos]
		t.set_data(pos, tile_data[i].val, tile_data[i].type)
		i += 1
		t.scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_property(t, "scale", _tile_normal_scale(), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	check_end_game()


func _on_btn_remove_pressed():
	# Click again while in remove mode → cancel
	if is_remove_mode:
		is_remove_mode = false
		update_power_up_ui()
		return

	if remove_count <= 0: return
	is_remove_mode = true
	update_power_up_ui()


# ==========================================
# UI UPDATE
# ==========================================
func update_power_up_ui():
	var hint_btn   = $PowerUpContainer/BtnHint
	var shuffle_btn = $PowerUpContainer/BtnShuffle
	var remove_btn = $PowerUpContainer/BtnRemove

	hint_btn.disabled = hint_count <= 0
	hint_btn.text = "Hint" if hint_count <= 1 else "Hint x%d" % hint_count

	if gameplay_mode == "GRAVITY":
		# Shuffle acts as lives button in Gravity
		shuffle_btn.disabled = shuffle_count <= 0
		shuffle_btn.text = "♥x%d" % max(shuffle_count, 0)
	else:
		shuffle_btn.disabled = shuffle_count <= 0
		shuffle_btn.text = "Shuffle" if shuffle_count <= 1 else "Shuffle x%d" % shuffle_count

	if is_remove_mode:
		remove_btn.text = "Cancel"
		remove_btn.disabled = false
	else:
		remove_btn.disabled = remove_count <= 0
		remove_btn.text = "Remove" if remove_count <= 1 else "Remove x%d" % remove_count


func update_lives_ui():
	if gameplay_mode != "GRAVITY": return
	var hearts = ""
	for i in range(shuffle_count):
		hearts += "♥"
	for i in range(3 - shuffle_count):
		hearts += "♡"
	lives_label.text = hearts


func update_gravity_level_ui():
	if gameplay_mode != "GRAVITY": return
	gravity_level_label.text = "Lv." + str(gravity_level)


func update_score_ui():
	$ScoreLabel.text = "Score: " + str(score)


# ==========================================
# SCORING
# ==========================================
func calculate_points(sel_tiles: Array) -> int:
	var base: int
	if gameplay_mode in ["ZEN", "MUTATION"]:
		var min_x = sel_tiles[0].x; var max_x = sel_tiles[0].x
		var min_y = sel_tiles[0].y; var max_y = sel_tiles[0].y
		for pos in sel_tiles:
			min_x = min(min_x, pos.x); max_x = max(max_x, pos.x)
			min_y = min(min_y, pos.y); max_y = max(max_y, pos.y)
		base = int((max_x - min_x + 1) * (max_y - min_y + 1))
	else:
		base = sel_tiles.size()

	# Mutation-only tile bonuses
	var bonuses = 0
	if gameplay_mode == "MUTATION":
		for pos in sel_tiles:
			match tiles[pos].tile_type:
				"JOKER":    bonuses += 5
				"NEGATIVE": bonuses += 3
				"MYSTERY":  bonuses += 2
				"VIRUS":    bonuses += 10

	return (base + bonuses) * combo_count  # combo applies to all modes


func update_combo_ui():
	if combo_count <= 1:
		combo_label.hide()
		return
	combo_label.show()
	combo_label.add_theme_color_override("font_color",
		Color.ORANGE_RED if combo_count >= 4 else Color.YELLOW)
	var tween = create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.08)


func show_floating_score(points: int, used_combo: int):
	var label = Label.new()
	label.text = "+" + str(points) + (" x%d!" % used_combo if used_combo > 1 else "")
	label.add_theme_font_size_override("font_size", 55)
	var color = Color.ORANGE_RED if used_combo >= 4 else (Color.YELLOW if used_combo >= 2 else Color.WHITE)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(260, 80)
	var box_center = selection_box.position + selection_box.size / 2.0
	label.position = box_center - Vector2(130, 40)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0, 100), 0.9).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


# ==========================================
# HINT ALGORITHM
# ==========================================
func find_hint_path() -> Array:
	if tiles.is_empty(): return []

	var min_x = 999; var max_x = -999
	var min_y = 999; var max_y = -999
	for pos in tiles.keys():
		min_x = min(min_x, int(pos.x)); max_x = max(max_x, int(pos.x))
		min_y = min(min_y, int(pos.y)); max_y = max(max_y, int(pos.y))

	for x1 in range(min_x, max_x + 1):
		for y1 in range(min_y, max_y + 1):
			for x2 in range(x1, max_x + 1):
				for y2 in range(y1, max_y + 1):
					var rect_tiles = []
					for rx in range(x1, x2 + 1):
						for ry in range(y1, y2 + 1):
							var p = Vector2(rx, ry)
							if tiles.has(p):
								rect_tiles.append(p)
					if rect_tiles.size() > 1 and is_valid_sum_10(rect_tiles):
						return rect_tiles
	return []


func is_valid_sum_10(rect_tiles: Array) -> bool:
	var total = 0
	var has_joker = false
	for pos in rect_tiles:
		var t = tiles[pos]
		if t.tile_type == "JOKER":
			has_joker = true
		total += t.get_effective_value()
	if has_joker:
		var needed = 10 - total
		return needed >= -9 and needed <= 9
	return total == 10


# ==========================================
# TRACE MODE (unchanged)
# ==========================================
func handle_trace_input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_dragging = true
			vertex_path.clear()
			trace_line.clear_points()
			try_snap_to_vertex(event.position)
		else:
			is_dragging = false
			vertex_path.clear()
			trace_line.clear_points()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			try_snap_to_vertex(event.position)


func try_snap_to_vertex(touch_pos: Vector2):
	var top_left = start_pos - Vector2(tile_size / 2.0, tile_size / 2.0)

	if vertex_path.is_empty():
		var vx = round((touch_pos.x - top_left.x) / tile_size)
		var vy = round((touch_pos.y - top_left.y) / tile_size)
		if vx >= 0 and vx <= grid_cols and vy >= 0 and vy <= grid_rows:
			var vp = top_left + Vector2(vx * tile_size, vy * tile_size)
			if touch_pos.distance_to(vp) < 40:
				add_vertex_to_line(Vector2(vx, vy), vp)
		return

	var last_coord = vertex_path.back()
	var last_pixel = top_left + Vector2(last_coord.x * tile_size, last_coord.y * tile_size)
	var drag_vec = touch_pos - last_pixel

	if drag_vec.length() > tile_size * 0.77:
		var next = last_coord
		if abs(drag_vec.x) > abs(drag_vec.y):
			next.x += sign(drag_vec.x)
		else:
			next.y += sign(drag_vec.y)

		if next.x < 0 or next.x > grid_cols or next.y < 0 or next.y > grid_rows:
			return
		if vertex_path.size() > 1 and next == vertex_path[vertex_path.size() - 2]:
			vertex_path.pop_back()
			trace_line.remove_point(trace_line.get_point_count() - 1)
			return
		if next != last_coord:
			var np = top_left + Vector2(next.x * tile_size, next.y * tile_size)
			add_vertex_to_line(next, np)
			check_closed_loop()


func add_vertex_to_line(coord: Vector2, pixel_pos: Vector2):
	vertex_path.append(coord)
	trace_line.add_point(pixel_pos)


func check_closed_loop():
	if vertex_path.size() > 3:
		var cur = vertex_path.back()
		for i in range(vertex_path.size() - 2):
			if vertex_path[i] == cur:
				var loop = vertex_path.slice(i, vertex_path.size())
				is_dragging = false
				evaluate_polygon(loop)
				return


func evaluate_polygon(loop_coords: Array):
	var logical_polygon = PackedVector2Array(loop_coords)
	var enclosed = []
	var total_sum = 0

	for pos in tiles.keys():
		var logical_center = pos + Vector2(0.5, 0.5)
		if Geometry2D.is_point_in_polygon(logical_center, logical_polygon):
			enclosed.append(pos)
			total_sum += tiles[pos].value
			tiles[pos].select()

	if total_sum == 10:
		for pos in enclosed:
			tiles[pos].queue_free()
			tiles.erase(pos)
	else:
		await get_tree().create_timer(0.5).timeout
		for pos in enclosed:
			if tiles.has(pos): tiles[pos].deselect()


# ==========================================
# TUTORIAL
# ==========================================
func check_and_start_tutorial():
	if not seen_tutorials[gameplay_mode]:
		start_tutorial()


func start_tutorial():
	is_tutorial_active = true
	current_tutorial_step = 0
	$TutorialLayer.show()
	update_tutorial_ui()


func update_tutorial_ui():
	var texts = tutorial_texts[gameplay_mode]
	%TutorialText.text = texts[current_tutorial_step]
	%BtnNext.text = "Let's Play!" if current_tutorial_step == texts.size() - 1 else "Next"


func close_tutorial():
	$TutorialLayer.hide()
	is_tutorial_active = false
	seen_tutorials[gameplay_mode] = true


func _on_btn_next_pressed():
	var texts = tutorial_texts[gameplay_mode]
	if current_tutorial_step < texts.size() - 1:
		current_tutorial_step += 1
		update_tutorial_ui()
	else:
		close_tutorial()


func _on_btn_skip_pressed():
	close_tutorial()


func _on_btn_help_pressed():
	start_tutorial()


# ==========================================
# UTILITY
# ==========================================
func is_within_grid(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_cols and grid_pos.y >= 0 and grid_pos.y < grid_rows


func _show_time_bonus(seconds: float):
	var label = Label.new()
	label.text = "+%.0fs" % seconds
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.LIME_GREEN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.size = Vector2(200, 60)
	# Float up from the timer area (top-left)
	label.position = Vector2(get_viewport_rect().size.x - 220, 15)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0, 50), 1.0).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)


# ==========================================
# DEBUG TOOLS
# ==========================================
func _init_debug_ui():
	if not DEBUG_MODE: return

	var sw = get_viewport_rect().size.x

	var layer = CanvasLayer.new()
	layer.name = "DebugLayer"
	layer.layer = 99
	add_child(layer)

	# Debug panel (initially hidden), anchored top-right below pause button
	var panel = VBoxContainer.new()
	panel.name = "DebugPanel"
	panel.add_theme_constant_override("separation", 4)
	panel.visible = false
	layer.add_child(panel)

	var button_defs = [
		{"label": "Time Up",   "method": "_debug_time_up",        "modes": ["CLASSIC", "GRAVITY"]},
		{"label": "Next Lv",   "method": "_debug_next_level",     "modes": ["GRAVITY"]},
		{"label": "+200 pts",  "method": "_debug_add_score",      "modes": []},
		{"label": "Reset PU",  "method": "_debug_reset_powerups", "modes": []},
	]

	for b in button_defs:
		var skip = b["modes"].size() > 0 and not (gameplay_mode in b["modes"])
		if skip: continue
		var btn = Button.new()
		btn.text = b["label"]
		btn.custom_minimum_size = Vector2(90, 30)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.modulate = Color(1.0, 0.85, 0.1, 0.95)
		btn.pressed.connect(Callable(self, b["method"]))
		panel.add_child(btn)

	# Position panel to top-right, below pause button (~y=55)
	panel.position = Vector2(sw - 100, 55)

	# Toggle button "TEST" — sits below pause, above panel
	var toggle = Button.new()
	toggle.text = "TEST"
	toggle.custom_minimum_size = Vector2(50, 26)
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.add_theme_color_override("font_color", Color.BLACK)
	toggle.modulate = Color(1.0, 0.85, 0.1, 0.95)
	toggle.position = Vector2(sw - 60, 52)
	toggle.pressed.connect(func(): panel.visible = not panel.visible)
	layer.add_child(toggle)


func _debug_time_up():
	if gameplay_mode in ["CLASSIC", "GRAVITY"]:
		trigger_end_game("TIME_UP")


func _debug_next_level():
	if gameplay_mode != "GRAVITY": return
	gravity_level = min(gravity_level + 1, 4)
	show_floating_text_center("LEVEL " + str(gravity_level) + "!")
	update_gravity_level_ui()


func _debug_add_score():
	score += 200
	update_score_ui()
	if gameplay_mode == "ZEN":
		_check_zen_milestone()


func _debug_reset_powerups():
	hint_count = 1
	remove_count = 1
	shuffle_count = 3 if gameplay_mode == "GRAVITY" else 1
	if gameplay_mode == "GRAVITY":
		update_lives_ui()
	update_power_up_ui()
	show_floating_text_center("Power-ups reset!", Color.CYAN)


func show_floating_text_center(msg: String, color: Color = Color.RED):
	var label = Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 60)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var screen_size = get_viewport_rect().size
	label.size = Vector2(screen_size.x, 100)
	label.position = Vector2(0, screen_size.y / 2.0)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0, 100), 1.0).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
