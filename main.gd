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
var _prev_hint_count = -1
var _prev_shuffle_count = -1
var _prev_remove_count = -1

var score = 0
var max_combo = 1
var _selection_sum: int = 0
var _display_score: int = 0
var _score_tween: Tween = null
var _combo_ring = null  # ComboRing node, created in _setup_hud_visuals

# --- COMBO SYSTEM ---
var combo_count = 1
var last_score_time = 0.0
const COMBO_TIMEOUT = 5.0
const COMBO_MAX = 5
var _combo_x5_streak: int = 0  # hits while at x5 — for "Unstoppable" achievement

# --- TILE VISUAL ---
const BASE_TILE_SIZE  = 105.0
const TILE_VISUAL_RATIO = 0.90  # tiles render at 90% of cell → ~10% gap between tiles

# --- GRAVITY SYSTEM ---
var gravity_level = 1
var gravity_l4_dir = "DOWN"
const GRAVITY_LEVEL_SCORE = 50  # score needed to advance each level
const GRAVITY_TIME_PER_TILE = 1.0  # +seconds per tile eaten in Gravity mode
const VIRUS_SPREAD_PENALTY = 10

# --- DEBUG ---
const DEBUG_MODE = true

# --- ZEN MILESTONE REFILL ---
var zen_milestone_count = 0
const ZEN_REFILL_MILESTONE = 100

var current_mode = "RECTANGLE"

# --- ACHIEVEMENT TRACKING (per-game, reset in setup_mode_config) ---
var _mutation_types_cleared: Array = []

var unlocked_modes = ["CLASSIC"]
var seen_tutorials = {
	"CLASSIC": false,
	"GRAVITY": false,
	"ZEN": false,
	"MUTATION": false,
	"CHALLENGE": false,
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
		"Levels: L1 Down → L2 Right → L3 Left → L4 Random\nAt L4, gravity direction changes every move — watch the arrow!"
	],
	"MUTATION": [
		"Mutation Mode!\n\nRed tiles carry negative values — use them to balance large positives.",
		"Mystery tile (?): reveals its value when touched.\nJoker tile: adapts to make the sum exactly 10 (range −9 to 9).",
		"Virus (blue): changes value every 5 s. Hits 0 → explodes, leaving a permanent hole!"
	],
	"ZEN": [
		"Zen Mode!\n\nNo time limit. Play at your own pace and aim for a high score.",
		"Board refills automatically when 70% cleared.\nEvery 100 points, all power-ups restore once — and they stack!"
	],
	"CHALLENGE": [
		"Adventure Mode!\n\n12 levels, each with a unique shape constraint. Match the constraint AND sum to 10 to score!",
		"Each level unlocks at a score milestone.\nThe current constraint is shown at the top — drag the wrong shape and it won't count.",
		"No time limit. Power-ups refill every 100 points.\nProgress saves automatically when you pause."
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
@onready var challenge_level_label = $ChallengeLevelLabel
@onready var challenge_constraint_label = $ChallengeConstraintLabel
@onready var btn_change_level = $PauseMenuLayer/VBoxContainer/BtnChangeLevel
@onready var btn_change_level_hud = $BtnChangeLevelHUD

var _change_level_layer: CanvasLayer = null
var _settings_layer: CanvasLayer = null

# HUD nodes created dynamically in _setup_hud_visuals()
var _score_sub_lbl: Label = null
var _mode_chip_lbl: Label = null
var _badge_hint: Label = null
var _badge_shuffle: Label = null
var _badge_remove: Label = null

# Overlay refs (set in _setup_pause_overlay / _setup_game_over_overlay)
var _go_icon_sb: StyleBoxFlat = null
var _go_icon_lbl: Label = null
var _go_kind_label: Label = null
var _go_score_label: Label = null
var _go_stats_row: HBoxContainer = null
var _go_new_high: Control = null

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
	var ui_top    = 192.0  # 128px top bar + 64px sub-info bar
	var ui_bottom = 170.0  # power-up bar: button + name label + margins
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
	queue_redraw()

	setup_mode_config()
	$TutorialLayer.hide()
	AudioManager.play_bgm()
	start_time_attack_game()
	if Global.load_save and gameplay_mode in ["ZEN", "MUTATION", "CHALLENGE"]:
		_load_game_state()
		Global.load_save = false
	else:
		spawn_grid()
	_setup_hud_visuals()
	_init_debug_ui()


func setup_mode_config():
	hint_count   = 1
	remove_count = 1
	max_combo    = 1
	gravity_level      = 1
	gravity_l4_dir     = "DOWN"
	zen_milestone_count = 0
	Global.hints_used_this_game = 0
	if not Global.load_save:
		Global.zen_current_level   = 1
		Global.zen_unlocked_levels = [1]
	_mutation_types_cleared = []
	Global.track_mode_played(gameplay_mode)

	match gameplay_mode:
		"GRAVITY":
			shuffle_count = 3
			total_duration = 150.0
			time_bar.hide()
			time_bar.max_value = total_duration
			lives_label.show()
			gravity_level_label.show()
			update_lives_ui()
			update_gravity_level_ui()
		"CLASSIC":
			shuffle_count = 1
			total_duration = 120.0
			time_bar.hide()
			time_bar.max_value = total_duration
			lives_label.hide()
			gravity_level_label.hide()
		_:  # ZEN, MUTATION, CHALLENGE
			shuffle_count = 1
			total_duration = 120.0
			time_bar.hide()
			lives_label.hide()
			gravity_level_label.hide()

	if gameplay_mode == "CHALLENGE":
		challenge_level_label.show()
		challenge_constraint_label.show()
		btn_change_level.show()
		btn_change_level_hud.show()
		_update_challenge_hud()
	elif gameplay_mode == "ZEN":
		challenge_level_label.show()
		challenge_constraint_label.hide()
		btn_change_level.show()
		btn_change_level_hud.show()
		_update_challenge_hud()
	else:
		challenge_level_label.hide()
		challenge_constraint_label.hide()
		btn_change_level.hide()
		btn_change_level_hud.hide()

	update_power_up_ui()


# ==========================================
# BOARD GENERATION
# ==========================================
func _draw():
	var sw = get_viewport_rect().size.x
	var sh = get_viewport_rect().size.y

	# Full-screen base (phủ nền mặc định tối của Godot)
	draw_rect(Rect2(0.0, 0.0, sw, sh), ThemeTokens.APP_BG)

	# Power-up bar background
	draw_rect(Rect2(0.0, sh - 170.0, sw, 170.0), ThemeTokens.PHONE_BG)

	# Board background — full-width game area so side strips match center
	draw_rect(Rect2(0.0, 192.0, sw, sh - 192.0 - 170.0), ThemeTokens.BOARD_BG)
	if tile_size > 0:
		var pad = tile_size * 0.10
		var board_pos = Vector2(start_pos.x - tile_size * 0.5 - pad, start_pos.y - tile_size * 0.5 - pad)
		var board_size = Vector2(grid_cols * tile_size + pad * 2, grid_rows * tile_size + pad * 2)
		draw_rect(Rect2(board_pos, board_size), ThemeTokens.BOARD_INSET, false, 1.5)

	# Selection box visual (fill + border, colour depends on sum)
	if selection_box and selection_box.visible:
		var sel_rect = Rect2(selection_box.position, selection_box.size)
		if _selection_sum == 10:
			draw_rect(sel_rect, Color(ThemeTokens.MINT.r, ThemeTokens.MINT.g, ThemeTokens.MINT.b, 0.18))
			_draw_dashed_rect(sel_rect, ThemeTokens.MINT_DARK, 2.5, 10.0)
		elif _selection_sum > 10:
			draw_rect(sel_rect, Color(ThemeTokens.NEG_BG.r, ThemeTokens.NEG_BG.g, ThemeTokens.NEG_BG.b, 0.18))
			_draw_dashed_rect(sel_rect, ThemeTokens.NEG_DARK, 2.5, 10.0)
		else:
			draw_rect(sel_rect, Color(ThemeTokens.MINT_SOFT.r, ThemeTokens.MINT_SOFT.g, ThemeTokens.MINT_SOFT.b, 0.25))
			_draw_dashed_rect(sel_rect, ThemeTokens.MINT, 2.0, 10.0)

	# Top bar + sub-info bar (drawn last to cover any board bleed into UI zone)
	draw_rect(Rect2(0.0, 0.0, sw, 192.0), ThemeTokens.PHONE_BG)
	draw_line(Vector2(0, 192), Vector2(sw, 192), Color(ThemeTokens.BOARD_INSET.r, ThemeTokens.BOARD_INSET.g, ThemeTokens.BOARD_INSET.b, 0.5), 1.0)


func spawn_grid():
	if gameplay_mode == "CHALLENGE":
		_spawn_challenge_board()
		return

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


func _spawn_challenge_board():
	var board_data: Dictionary = ZenBoardGenerator.generate(Global.zen_current_level)
	for pos in board_data.keys():
		var data = board_data[pos]
		var new_tile = TileFactory.make(data["type"])
		new_tile.position = start_pos + Vector2(pos.x * tile_size, pos.y * tile_size)
		new_tile.scale = _tile_normal_scale()
		add_child(new_tile)
		new_tile.set_data(pos, data["val"], data["type"])
		tiles[pos] = new_tile


func spawn_single_tile(x, y):
	var spawn_pos = Vector2(x, y)
	var rolled = TileFactory.roll(gameplay_mode)
	var new_tile = TileFactory.make(rolled.type)
	new_tile.position = start_pos + Vector2(x * tile_size, y * tile_size)
	new_tile.scale = _tile_normal_scale()
	add_child(new_tile)
	new_tile.set_data(spawn_pos, rolled.val, rolled.type)
	tiles[spawn_pos] = new_tile
	_set_apple_dir(new_tile, false)
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
					AudioManager.play_sfx("tile_remove")
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
			queue_redraw()
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

	_selection_sum = current_sum
	queue_redraw()

	var sum_label = selection_box.get_node("SumLabel")
	sum_label.text = str(current_sum)
	var _sum_state := "exact" if current_sum == 10 else ("over" if current_sum > 10 else "under")
	sum_label.add_theme_stylebox_override("normal", ThemeTokens.sb_sum_bubble(_sum_state))
	sum_label.add_theme_color_override("font_color", Color.WHITE)
	sum_label.size = Vector2(88, 44)
	sum_label.position = Vector2((selection_box.size.x - 88.0) * 0.5, -54.0)


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
		if gameplay_mode == "CHALLENGE":
			var min_cx = selected_tiles[0].x; var max_cx = selected_tiles[0].x
			var min_cy = selected_tiles[0].y; var max_cy = selected_tiles[0].y
			for pos in selected_tiles:
				min_cx = min(min_cx, pos.x); max_cx = max(max_cx, pos.x)
				min_cy = min(min_cy, pos.y); max_cy = max(max_cy, pos.y)
			var bbox := Rect2i(min_cx, min_cy, max_cx - min_cx + 1, max_cy - min_cy + 1)
			var c_result = ZenLevelManager.validate_constraint(bbox, selected_tiles.size(), Global.zen_current_level)
			if not c_result["valid"]:
				combo_count = 1
				_combo_x5_streak = 0
				update_combo_ui()
				AudioManager.play_sfx("wrong")
				_flash_wrong_tiles()
				show_floating_text_center("Wrong shape!", Color.ORANGE_RED)
				await get_tree().create_timer(0.3).timeout
				for pos in selected_tiles:
					if tiles.has(pos): tiles[pos].deselect()
				selected_tiles.clear()
				return

		var used_combo = combo_count
		var points_earned = calculate_points(selected_tiles)
		score += points_earned
		update_score_ui()
		AudioManager.play_sfx("score", 1.0 + (combo_count - 1) * 0.05)
		show_floating_score(points_earned, used_combo)

		# Combo applies to ALL modes using real-time clock
		var now = Time.get_unix_time_from_system()
		if last_score_time > 0 and now - last_score_time <= COMBO_TIMEOUT:
			combo_count = min(combo_count + 1, COMBO_MAX)
			if combo_count == COMBO_MAX:
				_combo_x5_streak += 1
			AudioManager.play_sfx("combo")
		else:
			combo_count = 1
			_combo_x5_streak = 0
		last_score_time = now
		update_combo_ui()

		if combo_count > max_combo:
			max_combo = combo_count

		# ── Achievement: score ──
		Global.unlock_achievement("first_ten")
		Global.update_achievement_progress("score_100", score)
		Global.update_achievement_progress("score_500", score)
		Global.update_achievement_progress("score_1000", score)

		# ── Achievement: combo ──
		if combo_count >= 2:
			Global.unlock_achievement("first_combo")
		if combo_count >= COMBO_MAX:
			Global.unlock_achievement("combo_5")
			if gameplay_mode == "CLASSIC":
				Global.unlock_achievement("combo_classic")
		if _combo_x5_streak >= 5:
			Global.unlock_achievement("combo_10")

		# ── Achievement: tile types (check before freeing tiles) ──
		if selected_tiles.size() >= 20:
			Global.unlock_achievement("big_selection")
		if has_joker:
			Global.unlock_achievement("joker_used")
		for pos in selected_tiles:
			var _t = tiles[pos]
			match _t.tile_type:
				"NEGATIVE":
					Global.unlock_achievement("negative_win")
				"VIRUS":
					Global.unlock_achievement("virus_cleared")
			if gameplay_mode == "MUTATION" and _t.tile_type in ["JOKER", "NEGATIVE", "MYSTERY", "VIRUS"]:
				if _t.tile_type not in _mutation_types_cleared:
					_mutation_types_cleared.append(_t.tile_type)
					if _mutation_types_cleared.size() >= 4:
						Global.unlock_achievement("mutation_alltype")

		var eaten_count = selected_tiles.size()  # capture before clear

		for i in selected_tiles.size():
			var pos = selected_tiles[i]
			if tiles.has(pos):
				var t = tiles[pos]
				_spawn_tile_burst(t.position, t.tile_type)
				tiles.erase(pos)
				var delay := float(i) * 0.03
				var tw = t.create_tween()
				if delay > 0.0:
					tw.tween_interval(delay)
				tw.tween_property(t, "scale", Vector2(1.15, 1.15), 0.06).set_trans(Tween.TRANS_SINE)
				tw.tween_property(t, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw.tween_callback(t.queue_free)

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
				var cleared_pct = 1.0 - float(tiles.size()) / float(grid_rows * grid_cols)
				if cleared_pct >= 0.85:
					refill_empty_slots()
					return  # check_end_game called inside refill_empty_slots
				check_end_game()
			"ZEN", "MUTATION", "CHALLENGE":
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
		AudioManager.play_sfx("wrong")
		_flash_wrong_tiles()
		await get_tree().create_timer(0.3).timeout
		for pos in selected_tiles:
			if tiles.has(pos):
				tiles[pos].deselect()
		selected_tiles.clear()


func _check_zen_milestone():
	if gameplay_mode not in ["ZEN", "CHALLENGE"]: return
	var threshold = 50 if gameplay_mode == "CHALLENGE" else ZEN_REFILL_MILESTONE
	var milestone = score / threshold
	if milestone > zen_milestone_count:
		zen_milestone_count = milestone
		var gain = 3 if gameplay_mode == "CHALLENGE" else 1
		hint_count   += gain
		shuffle_count += gain
		remove_count  += gain
		AudioManager.play_sfx("powerup_gain")
		show_floating_text_center("Power-up +%d!" % gain, Color.LIME_GREEN)
		update_power_up_ui()
		if gameplay_mode == "ZEN":
			Global.update_achievement_progress("zen_refill3", zen_milestone_count)
	_check_zen_level_unlock()


func _check_zen_level_unlock():
	if gameplay_mode not in ["ZEN", "CHALLENGE"]: return
	if ZenLevelManager.is_last_level(Global.zen_current_level): return
	var next_level = Global.zen_current_level + 1
	if next_level > ZenLevels.LEVELS.size(): return
	var unlock_score = ZenLevelManager.get_unlock_score(next_level)
	if score >= unlock_score and not (next_level in Global.zen_unlocked_levels):
		Global.zen_unlocked_levels.append(next_level)
		var level_name = ZenLevelManager.get_level_name(next_level)
		show_floating_text_center("L%d %s unlocked!" % [next_level, level_name], Color.GOLD)
		Global.zen_current_level = next_level
		_update_challenge_hud()
		if gameplay_mode == "CHALLENGE":
			if next_level == 6:
				Global.unlock_achievement("challenge_l6")
			if next_level == 12:
				Global.unlock_achievement("challenge_l12")


# ==========================================
# END GAME
# ==========================================
func scan_board_for_valid_moves() -> bool:
	return find_hint_path().size() > 0


func check_end_game():
	if is_game_over: return
	if gameplay_mode == "GRAVITY":
		_check_gravity_end_game()
		return
	if hint_count > 0 or shuffle_count > 0 or remove_count > 0: return
	if not scan_board_for_valid_moves():
		if gameplay_mode == "CHALLENGE":
			_challenge_no_moves_rescue()
		else:
			trigger_end_game("NO_MOVES")


func _challenge_no_moves_rescue():
	AudioManager.play_sfx("shuffle")
	show_floating_text_center("No moves!  Auto-shuffling...", Color.CYAN)
	_challenge_auto_shuffle()


func _challenge_auto_shuffle():
	var tile_data = []
	for pos in tiles.keys():
		var t = tiles[pos]
		tile_data.append({"val": t.value, "type": t.tile_type})

	var _base = preload("res://tile.gd")
	var found = false
	for _attempt in range(5):
		tile_data.shuffle()
		var i = 0
		for pos in tiles.keys():
			var t = tiles[pos]
			var d = tile_data[i]
			var ns = TileFactory.SCRIPTS.get(d.type, _base)
			if t.get_script() != ns:
				t.set_script(ns)
			t.is_selected = false
			if d.type == "VIRUS": t.virus_timer = 0.0
			t.set_data(pos, d.val, d.type)
			i += 1
		if scan_board_for_valid_moves():
			found = true
			break

	if not found:
		for pos in tiles.keys():
			if is_instance_valid(tiles[pos]): tiles[pos].queue_free()
		tiles.clear()
		_spawn_challenge_board()
		show_floating_text_center("Board refreshed!", Color.GOLD)
		return

	for pos in tiles.keys():
		var t = tiles[pos]
		t.scale = Vector2.ZERO
		var tw = create_tween()
		tw.tween_property(t, "scale", _tile_normal_scale(), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _check_gravity_end_game():
	if scan_board_for_valid_moves(): return
	# No valid moves — check if non-life power-ups are available
	if hint_count > 0 or remove_count > 0:
		_flash_available_powerups()
		return
	# hint and remove exhausted — fall back to life penalty
	if shuffle_count > 0:
		shuffle_count -= 1
		update_lives_ui()
		update_power_up_ui()
		AudioManager.play_sfx("wrong")
		show_floating_text_center("-1 Life!  New board...", Color(1.0, 0.35, 0.35))
		if shuffle_count <= 0:
			trigger_end_game("NO_LIVES")
		else:
			_gravity_force_new_board()
	else:
		trigger_end_game("NO_LIVES")


func _flash_available_powerups():
	show_floating_text_center("No moves!  Use a power-up!", Color.YELLOW)
	var btns: Array = []
	if hint_count > 0:    btns.append($PowerUpContainer/BtnHint)
	if remove_count > 0:  btns.append($PowerUpContainer/BtnRemove)
	if shuffle_count > 0: btns.append($PowerUpContainer/BtnShuffle)
	if btns.is_empty(): return
	var btn: Button = btns[randi() % btns.size()]
	var tween = create_tween().set_loops(4)
	tween.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.12)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)


func _gravity_force_new_board():
	for pos in tiles.keys():
		if is_instance_valid(tiles[pos]):
			_spawn_tile_burst(tiles[pos].position, tiles[pos].tile_type)
			tiles[pos].queue_free()
	tiles.clear()
	await get_tree().create_timer(0.5).timeout
	for _attempt in range(5):
		for x in range(grid_cols):
			for y in range(grid_rows):
				spawn_single_tile(x, y)
		if scan_board_for_valid_moves():
			break
		for pos in tiles.keys():
			tiles[pos].queue_free()
		tiles.clear()
	await get_tree().create_timer(0.4).timeout
	check_end_game()


func trigger_end_game(reason: String):
	if is_game_over: return
	is_game_over = true
	AudioManager.stop_bgm(2.0)
	AudioManager.play_sfx("gameover")
	Global.delete_save(gameplay_mode)

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

	_update_game_over_ui(reason, score, time_played, max_combo)
	$GameOverLayer.show()

	Global.submit_score(gameplay_mode, score, time_played, max_combo)

	# ── Achievement: Classic end-game ──
	if gameplay_mode == "CLASSIC":
		var time_remaining = total_duration - time_played
		if time_remaining >= 60.0:
			Global.unlock_achievement("classic_survive")
		if Global.hints_used_this_game == 0:
			Global.unlock_achievement("no_hint")

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
		if gravity_level == 4:
			var dirs = ["DOWN", "UP", "LEFT", "RIGHT"]
			gravity_l4_dir = dirs[randi() % dirs.size()]
		update_gravity_level_ui()
		_show_level_up_banner(gravity_level)
		_refresh_apple_directions(true)
		# ── Achievement: gravity levels ──
		if gravity_level == 4:
			Global.unlock_achievement("gravity_lv4")
		if gravity_level >= 3 and shuffle_count == 3:
			Global.unlock_achievement("gravity_3lives")


func _show_level_up_banner(level: int):
	AudioManager.play_sfx("level_up")
	var dir_text = {2: "RIGHT  →", 3: "←  LEFT", 4: "RANDOM  ↯"}
	var colors   = {
		2: Color(0.25, 0.88, 1.0),
		3: Color(1.0,  0.55, 0.1),
		4: Color(1.0,  0.3,  0.65),
	}
	var screen = get_viewport_rect().size
	var color  = colors.get(level, Color.WHITE)

	var wrap = Control.new()
	wrap.position = Vector2.ZERO
	wrap.size = screen
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)

	var lbl_level = Label.new()
	lbl_level.text = "LEVEL %d" % level
	lbl_level.add_theme_font_size_override("font_size", 82)
	lbl_level.add_theme_color_override("font_color", color)
	lbl_level.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl_level.add_theme_constant_override("outline_size", 6)
	lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_level.size = Vector2(screen.x, 105)
	lbl_level.position = Vector2(0, screen.y / 2.0 - 85)
	wrap.add_child(lbl_level)

	var lbl_dir = Label.new()
	lbl_dir.text = dir_text.get(level, "")
	lbl_dir.add_theme_font_size_override("font_size", 42)
	lbl_dir.add_theme_color_override("font_color", color.lightened(0.15))
	lbl_dir.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl_dir.add_theme_constant_override("outline_size", 4)
	lbl_dir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dir.size = Vector2(screen.x, 60)
	lbl_dir.position = Vector2(0, screen.y / 2.0 + 28)
	wrap.add_child(lbl_dir)

	wrap.pivot_offset = screen / 2.0
	wrap.scale = Vector2(0.15, 0.15)

	var tween = create_tween()
	tween.tween_property(wrap, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(wrap, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.8)
	tween.tween_property(wrap, "modulate:a", 0.0, 0.35)
	tween.tween_callback(wrap.queue_free)


func get_gravity_direction() -> String:
	match gravity_level:
		1: return "DOWN"
		2: return "RIGHT"
		3: return "LEFT"
		_: return gravity_l4_dir


func apply_gravity():
	await get_tree().create_timer(0.2).timeout
	match get_gravity_direction():
		"DOWN":  _apply_gravity_down()
		"UP":    _apply_gravity_up()
		"RIGHT": _apply_gravity_horizontal(true)
		"LEFT":  _apply_gravity_horizontal(false)
	if gravity_level == 4:
		var dirs = ["DOWN", "UP", "LEFT", "RIGHT"]
		gravity_l4_dir = dirs[randi() % dirs.size()]
		update_gravity_level_ui()
	_refresh_apple_directions(true)


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


func _apply_gravity_up():
	for x in range(grid_cols):
		var empty = 0
		for y in range(grid_rows):
			var p = Vector2(x, y)
			if not tiles.has(p):
				empty += 1
			elif empty > 0:
				_move_tile(p, Vector2(x, y - empty))


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




# ==========================================
# VIRUS
# ==========================================
func kill_tile_from_virus(pos: Vector2):
	if not tiles.has(pos):
		return

	Global.unlock_achievement("virus_explode")
	AudioManager.play_sfx("virus_explode")

	# Original virus stays: re-roll value + reset timer
	var virus_tile = tiles[pos]
	virus_tile.value = randi_range(1, 9)
	virus_tile.virus_timer = 0.0
	virus_tile.update_visuals()
	var ns = _tile_normal_scale()
	var vt = create_tween()
	vt.tween_property(virus_tile, "scale", ns * 1.35, 0.1)
	vt.tween_property(virus_tile, "scale", ns, 0.1)

	# Find adjacent non-virus tiles to infect
	var candidates: Array = []
	for dir in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		var adj = pos + dir
		if tiles.has(adj) and tiles[adj].tile_type != "VIRUS":
			candidates.append(adj)

	if candidates.size() > 0:
		var target: Vector2 = candidates[randi() % candidates.size()]
		var old_tile = tiles[target]
		var px_pos = old_tile.position
		old_tile.queue_free()
		tiles.erase(target)
		var new_virus = TileFactory.make("VIRUS")
		new_virus.position = px_pos
		new_virus.scale = _tile_normal_scale()
		add_child(new_virus)
		new_virus.set_data(target, randi_range(1, 9), "VIRUS")
		tiles[target] = new_virus

	# Penalty always applies
	score = max(0, score - VIRUS_SPREAD_PENALTY)
	update_score_ui()
	_show_virus_penalty(virus_tile.position)
	_flash_screen_virus()


func _show_virus_penalty(pixel_pos: Vector2):
	var label = Label.new()
	label.text = "-%d" % VIRUS_SPREAD_PENALTY
	label.add_theme_font_size_override("font_size", 54)
	label.add_theme_color_override("font_color", Color.RED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(120, 60)
	label.position = pixel_pos - Vector2(60, 30)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0, 90), 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func _flash_screen_virus():
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0, 0, 0, 0)
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(0.85, 0, 0, 0.5), 0.07)
	tween.tween_property(flash, "color", Color(0, 0, 0, 0.55), 0.07)
	tween.tween_property(flash, "color", Color(0.85, 0, 0, 0.35), 0.07)
	tween.tween_property(flash, "color", Color(0, 0, 0, 0.0), 0.18)
	tween.tween_callback(flash.queue_free)


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
				_set_apple_dir(new_tile, false)
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
	_combo_x5_streak = 0
	last_score_time = 0.0
	combo_label.hide()
	$PauseMenuLayer.hide()


func _process(delta):
	if is_game_over: return

	if gameplay_mode in ["CLASSIC", "GRAVITY"]:
		# Timer keeps running even when tutorial overlay is open
		var time_left = max(0.0, total_duration - (Time.get_unix_time_from_system() - game_start_time))
		update_timer_display(time_left)
		if time_bar:
			time_bar.value = time_left
		if time_left <= 0:
			on_time_up()

	if is_tutorial_active: return

	if gameplay_mode not in ["CLASSIC", "GRAVITY"]:
		if not is_paused:
			accumulated_time += delta
		update_timer_display(accumulated_time)

	# Combo countdown — all modes
	if combo_count > 1:
		var remaining = COMBO_TIMEOUT - (Time.get_unix_time_from_system() - last_score_time)
		if remaining <= 0:
			combo_count = 1
			_combo_x5_streak = 0
			combo_label.hide()
			if is_instance_valid(_combo_ring):
				_combo_ring.visible = false
		else:
			combo_label.show()
			combo_label.text = "×%d" % combo_count
			if is_instance_valid(_combo_ring):
				_combo_ring.visible = true
				_combo_ring.ratio = clampf(remaining / COMBO_TIMEOUT, 0.0, 1.0)
				_combo_ring.combo_count = combo_count
				_combo_ring.queue_redraw()


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
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_game_over:
			return
		if is_paused:
			_on_btn_continue_pressed()
		else:
			_on_pause_button_pressed()


func _on_pause_button_pressed():
	if is_game_over: return
	is_paused = true
	AudioManager.pause_bgm()
	pause_menu.show()


func _on_btn_continue_pressed():
	is_paused = false
	AudioManager.resume_bgm()
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
		AudioManager.stop_bgm(1.0)
		Global.submit_score(gameplay_mode, score, accumulated_time, max_combo)
		_save_game_state()
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_btn_change_level_pressed():
	if _change_level_layer == null:
		_build_change_level_panel()
	_populate_level_list()
	_change_level_layer.show()


func _on_btn_settings_pressed():
	if is_game_over: return
	if _settings_layer == null:
		_build_settings_panel()
	is_paused = true
	AudioManager.pause_bgm()
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

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var btn_back := Button.new()
	btn_back.text = "<-- Back"
	btn_back.custom_minimum_size = Vector2(0, 60)
	btn_back.add_theme_font_size_override("font_size", 36)
	btn_back.pressed.connect(func():
		_settings_layer.hide()
		is_paused = false
		AudioManager.resume_bgm()
	)
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


func _build_change_level_panel():
	_change_level_layer = CanvasLayer.new()
	_change_level_layer.layer = 3
	add_child(_change_level_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.92)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_change_level_layer.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 50)
	_change_level_layer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Change Level"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "LevelList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var btn_back := Button.new()
	btn_back.text = "<-- Back"
	btn_back.add_theme_font_size_override("font_size", 34)
	btn_back.custom_minimum_size = Vector2(0, 55)
	btn_back.pressed.connect(func(): _change_level_layer.hide())
	vbox.add_child(btn_back)


func _populate_level_list():
	var list := _change_level_layer.find_child("LevelList", true, false) as VBoxContainer
	for child in list.get_children():
		child.queue_free()

	for i in range(ZenLevels.LEVELS.size()):
		var lv_data = ZenLevels.LEVELS[i]
		var lv_id: int = lv_data["id"]
		var is_unlocked: bool = lv_id in Global.zen_unlocked_levels
		var is_current: bool = lv_id == Global.zen_current_level

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 52)
		btn.add_theme_font_size_override("font_size", 28 if not is_current else 30)

		if is_current:
			btn.text = "L%d  %s  <--" % [lv_id, lv_data["name"]]
			btn.add_theme_color_override("font_color", Color.GOLD)
		elif is_unlocked:
			btn.text = "L%d  %s" % [lv_id, lv_data["name"]]
		else:
			btn.text = "L%d  %s  [%d pts]" % [lv_id, lv_data["name"], lv_data["unlock_score"]]
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 1.0)

		if is_unlocked and not is_current:
			btn.pressed.connect(_on_level_selected.bind(lv_id))

		list.add_child(btn)


func _on_level_selected(lv_id: int):
	Global.zen_current_level = lv_id
	_change_level_layer.hide()
	is_paused = false
	pause_menu.hide()

	for pos in tiles.keys():
		if is_instance_valid(tiles[pos]):
			tiles[pos].queue_free()
	tiles.clear()

	_spawn_challenge_board()
	_update_challenge_hud()
	check_end_game()


func _on_btn_restart_over_pressed():
	$GameOverLayer.hide()
	_reset_game()


func _on_btn_quit_over_pressed():
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _reset_game():
	var overlay = get_node_or_null("TutorialOverlay")
	if overlay:
		overlay.queue_free()
	is_tutorial_active = false

	Global.delete_save(gameplay_mode)
	score = 0
	_display_score = 0
	is_game_over = false
	accumulated_time = 0.0
	max_combo = 1
	combo_count = 1
	_combo_x5_streak = 0
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

	AudioManager.play_sfx("powerup_use")
	hint_count -= 1
	update_power_up_ui()
	Global.hints_used_this_game += 1
	Global.unlock_achievement("first_powerup")

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

	AudioManager.play_sfx("shuffle")
	shuffle_count -= 1
	Global.unlock_achievement("first_powerup")

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

	var _base_tile_script = preload("res://tile.gd")
	var max_attempts = 5 if gameplay_mode == "CHALLENGE" else 1
	var attempt = 0
	var found_valid = false
	while attempt < max_attempts:
		tile_data.shuffle()
		var i = 0
		for pos in tiles.keys():
			var t = tiles[pos]
			var d = tile_data[i]
			var new_script = TileFactory.SCRIPTS.get(d.type, _base_tile_script)
			if t.get_script() != new_script:
				t.set_script(new_script)
			t.is_selected = false
			if d.type == "VIRUS":
				t.virus_timer = 0.0
			t.set_data(pos, d.val, d.type)
			i += 1
		attempt += 1
		if gameplay_mode != "CHALLENGE" or scan_board_for_valid_moves():
			found_valid = true
			break

	if gameplay_mode == "CHALLENGE" and not found_valid:
		# Shuffle không tìm được nước hợp lệ → refill board mới (guaranteed valid)
		for pos in tiles.keys():
			if is_instance_valid(tiles[pos]):
				tiles[pos].queue_free()
		tiles.clear()
		_spawn_challenge_board()
		show_floating_text_center("Board refreshed!", Color.GOLD)
	else:
		for pos in tiles.keys():
			var t = tiles[pos]
			t.scale = Vector2.ZERO
			var tween = create_tween()
			tween.tween_property(t, "scale", _tile_normal_scale(), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	check_end_game()


func _on_btn_remove_pressed():
	# Click again while in remove mode → cancel
	if is_remove_mode:
		is_remove_mode = false
		update_power_up_ui()
		Global.unlock_achievement("cancel_remove")
		return

	if remove_count <= 0: return
	AudioManager.play_sfx("powerup_use")
	is_remove_mode = true
	update_power_up_ui()
	Global.unlock_achievement("first_powerup")


# ==========================================
# UI UPDATE
# ==========================================
func update_power_up_ui():
	var hint_btn    = $PowerUpContainer/BtnHint
	var shuffle_btn = $PowerUpContainer/BtnShuffle
	var remove_btn  = $PowerUpContainer/BtnRemove

	# Button disabled state — icon stays constant
	hint_btn.disabled    = hint_count <= 0
	shuffle_btn.disabled = shuffle_count <= 0
	remove_btn.disabled  = remove_count <= 0 and not is_remove_mode

	# Badge pills — show count; hide when 0
	if _badge_hint:
		_badge_hint.text    = "×%d" % hint_count
		_badge_hint.visible = hint_count > 0
	if _badge_shuffle:
		_badge_shuffle.text    = "×%d" % shuffle_count
		_badge_shuffle.visible = shuffle_count > 0
	if _badge_remove:
		if is_remove_mode:
			_badge_remove.text    = "cancel"
			_badge_remove.visible = true
			var sb_cancel := ThemeTokens.sb_powerup_badge()
			sb_cancel.bg_color = ThemeTokens.NEG_DARK
			_badge_remove.add_theme_stylebox_override("normal", sb_cancel)
		else:
			_badge_remove.text    = "×%d" % remove_count
			_badge_remove.visible = remove_count > 0
			_badge_remove.add_theme_stylebox_override("normal", ThemeTokens.sb_powerup_badge())

	_animate_powerup_change(hint_btn,    _prev_hint_count,    hint_count)
	_animate_powerup_change(shuffle_btn, _prev_shuffle_count, shuffle_count)
	_animate_powerup_change(remove_btn,  _prev_remove_count,  remove_count)
	_prev_hint_count    = hint_count
	_prev_shuffle_count = shuffle_count
	_prev_remove_count  = remove_count


func _animate_powerup_change(btn: Button, prev: int, curr: int) -> void:
	if prev < 0:
		return
	var tween = create_tween().set_trans(Tween.TRANS_BACK)
	if curr <= 0 and prev > 0:
		tween.tween_property(btn, "scale", Vector2(0.8, 0.8), 0.08)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
	elif curr > 0 and prev <= 0:
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)


func update_lives_ui():
	if gameplay_mode != "GRAVITY": return
	var hearts = ""
	for i in range(shuffle_count):
		hearts += "♥"
	for i in range(3 - shuffle_count):
		hearts += "♡"
	lives_label.text = hearts
	lives_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))


func update_gravity_level_ui():
	if gameplay_mode != "GRAVITY": return
	if gravity_level == 4:
		var arrows = {"DOWN": "↓", "UP": "↑", "LEFT": "←", "RIGHT": "→"}
		gravity_level_label.text = "Lv.4 " + arrows.get(gravity_l4_dir, "")
	else:
		gravity_level_label.text = "Lv." + str(gravity_level)


func _update_challenge_hud():
	if gameplay_mode not in ["ZEN", "CHALLENGE"]: return
	var lv := Global.zen_current_level
	challenge_level_label.text = "L%d %s" % [lv, ZenLevelManager.get_level_name(lv)]
	challenge_constraint_label.text = ZenLevelManager.get_constraint_text(lv)


func update_score_ui():
	if _score_tween and _score_tween.is_running():
		_score_tween.kill()
	_score_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_score_tween.tween_method(_set_display_score, float(_display_score), float(score), 0.35)

func _set_display_score(val: float):
	_display_score = int(val)
	$ScoreLabel.text = _fmt_score(_display_score)


func _fmt_score(n: int) -> String:
	if n >= 1000:
		return "%d,%03d" % [n / 1000, n % 1000]
	return str(n)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash: float) -> void:
	var p := rect.position
	var e := rect.end
	draw_dashed_line(p,                  Vector2(e.x, p.y), color, width, dash)
	draw_dashed_line(Vector2(e.x, p.y),  e,                 color, width, dash)
	draw_dashed_line(e,                  Vector2(p.x, e.y), color, width, dash)
	draw_dashed_line(Vector2(p.x, e.y),  p,                 color, width, dash)


func _setup_hud_visuals():
	var sw := get_viewport_rect().size.x
	var sh := get_viewport_rect().size.y

	# ── TOP BAR (0–128 px) ──────────────────────────────────────────────────

	# Menu button (left, 88×88)
	var mb_sz := float(ThemeTokens.MENU_BUTTON_SIZE)
	$PauseButton.position = Vector2(12, (128.0 - mb_sz) * 0.5)
	$PauseButton.size = Vector2(mb_sz, mb_sz)
	$PauseButton.custom_minimum_size = Vector2(mb_sz, mb_sz)
	$PauseButton.text = "≡"
	$PauseButton.add_theme_stylebox_override("normal",  ThemeTokens.sb_menu_button())
	$PauseButton.add_theme_stylebox_override("hover",   ThemeTokens.sb_menu_button())
	$PauseButton.add_theme_stylebox_override("pressed", ThemeTokens.sb_menu_button())
	$PauseButton.add_theme_color_override("font_color", ThemeTokens.TEXT)
	$PauseButton.add_theme_font_size_override("font_size", 38)

	# Score — "SCORE" sub-label + big number, stacked vertically, centered
	var score_sub_h := 26.0
	var score_num_h := 56.0
	var score_total := score_sub_h + 6.0 + score_num_h
	var score_top   := (128.0 - score_total) * 0.5
	var score_x     := mb_sz + 16.0
	var score_w     := sw - (mb_sz + 16.0) * 2.0

	_score_sub_lbl = Label.new()
	_score_sub_lbl.text = "SCORE"
	_score_sub_lbl.size = Vector2(score_w, score_sub_h)
	_score_sub_lbl.position = Vector2(score_x, score_top)
	_score_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_sub_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_score_sub_lbl.add_theme_font_override("font", ThemeTokens.font_mono(500))
	_score_sub_lbl.add_theme_font_size_override("font_size", 22)
	_score_sub_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	add_child(_score_sub_lbl)

	$ScoreLabel.position = Vector2(score_x, score_top + score_sub_h + 6.0)
	$ScoreLabel.size = Vector2(score_w, score_num_h)
	$ScoreLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$ScoreLabel.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	$ScoreLabel.add_theme_font_override("font", ThemeTokens.font_mono(700))
	$ScoreLabel.add_theme_font_size_override("font_size", 44)
	$ScoreLabel.add_theme_color_override("font_color", ThemeTokens.TEXT)

	# Combo badge (right of top bar, same height as menu button)
	combo_label.position = Vector2(sw - mb_sz - 12.0, (128.0 - mb_sz) * 0.5)
	combo_label.size = Vector2(mb_sz, mb_sz)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_override("font", ThemeTokens.font_mono(800))
	combo_label.add_theme_font_size_override("font_size", 26)

	var ring := ComboRing.new()
	ring.name = "ComboRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = combo_label.position
	ring.size = combo_label.size
	ring.visible = false
	add_child(ring)
	move_child(ring, combo_label.get_index())
	_combo_ring = ring

	$TimeBar.hide()

	# ── SUB-INFO BAR (128–192 px) ───────────────────────────────────────────

	var sub_y    := 136.0
	var sub_h    := 48.0
	var chip_w   := 140.0

	# Mode chip (right) — always visible
	_mode_chip_lbl = Label.new()
	var _chip_labels = {"CLASSIC":"CLASSIC","GRAVITY":"GRAVITY","MUTATION":"MUTATION","ZEN":"ZEN","CHALLENGE":"ADVENTURE"}
	_mode_chip_lbl.text = _chip_labels.get(gameplay_mode, gameplay_mode)
	_mode_chip_lbl.size = Vector2(chip_w, sub_h)
	_mode_chip_lbl.position = Vector2(sw - chip_w - 12.0, sub_y)
	_mode_chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_chip_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_mode_chip_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	_mode_chip_lbl.add_theme_font_size_override("font_size", 20)
	_mode_chip_lbl.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)
	_mode_chip_lbl.add_theme_stylebox_override("normal", ThemeTokens.sb_mode_chip())
	add_child(_mode_chip_lbl)

	# Timer / Level (left)
	$TimeLabel.position = Vector2(16.0, sub_y)
	$TimeLabel.size = Vector2(240.0, sub_h)
	$TimeLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	$TimeLabel.add_theme_font_override("font", ThemeTokens.font_mono(600))
	$TimeLabel.add_theme_font_size_override("font_size", 26)
	$TimeLabel.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)

	# Gravity-specific labels
	gravity_level_label.position = Vector2(260.0, sub_y)
	gravity_level_label.size = Vector2(200.0, sub_h)
	gravity_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gravity_level_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	gravity_level_label.add_theme_font_override("font", ThemeTokens.font_mono(700))
	gravity_level_label.add_theme_font_size_override("font_size", 26)
	gravity_level_label.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)

	lives_label.position = Vector2(sw - chip_w - 170.0, sub_y)
	lives_label.size = Vector2(150.0, sub_h)
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lives_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lives_label.add_theme_font_size_override("font_size", 26)

	# Challenge/Zen: 2-line below score, aligned with score column (same x/width)
	var line1_h := 28.0
	var line2_h := 22.0
	# Line 1 — level name
	challenge_level_label.position = Vector2(score_x, sub_y)
	challenge_level_label.size = Vector2(score_w, line1_h)
	challenge_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_level_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	challenge_level_label.add_theme_font_size_override("font_size", 22)
	challenge_level_label.add_theme_color_override("font_color", ThemeTokens.TEXT)
	# Line 2 — constraint text
	challenge_constraint_label.position = Vector2(score_x, sub_y + line1_h + 2.0)
	challenge_constraint_label.size = Vector2(score_w, line2_h)
	challenge_constraint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_constraint_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	challenge_constraint_label.add_theme_font_size_override("font_size", 17)
	challenge_constraint_label.add_theme_color_override("font_color", ThemeTokens.MINT_DARK)

	btn_change_level_hud.visible = gameplay_mode in ["ZEN", "CHALLENGE"]

	# ── SELECTION BOX ───────────────────────────────────────────────────────
	selection_box.color = Color(0, 0, 0, 0)
	var _sum_lbl = selection_box.get_node("SumLabel")
	_sum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sum_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_sum_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	_sum_lbl.add_theme_font_size_override("font_size", 36)

	# ── POWER-UP BAR (bottom) ───────────────────────────────────────────────
	var btn_size := float(ThemeTokens.POWERUP_BUTTON_SIZE)  # 96
	var btn_gap  := 32.0
	var total_btn_w := 3.0 * btn_size + 2.0 * btn_gap
	var bx   := (sw - total_btn_w) * 0.5
	var by   := sh - 170.0 + 18.0    # 18px top padding within 170px PU zone
	var nm_y := by + btn_size + 8.0   # name-label row y

	$PowerUpContainer.position = Vector2(bx, by)
	$PowerUpContainer.size = Vector2(total_btn_w, btn_size)
	$PowerUpContainer.add_theme_constant_override("separation", int(btn_gap))

	var sb_pu_dis := StyleBoxFlat.new()
	ThemeTokens._set_radius(sb_pu_dis, ThemeTokens.POWERUP_RADIUS)
	sb_pu_dis.bg_color = Color(0.78, 0.74, 0.66, 0.55)

	var btn_icons  := ["?", "↺", "✕"]
	var btn_names  := ["HINT", "SHUFFLE", "REMOVE"]
	var pu_btns    := [$PowerUpContainer/BtnHint, $PowerUpContainer/BtnShuffle, $PowerUpContainer/BtnRemove]

	for i in 3:
		var btn: Button = pu_btns[i]
		btn.custom_minimum_size = Vector2(btn_size, btn_size)
		btn.text = btn_icons[i]
		btn.add_theme_stylebox_override("normal",   ThemeTokens.sb_powerup_button())
		btn.add_theme_stylebox_override("hover",    ThemeTokens.sb_powerup_button())
		btn.add_theme_stylebox_override("pressed",  ThemeTokens.sb_powerup_button())
		btn.add_theme_stylebox_override("disabled", sb_pu_dis)
		btn.add_theme_font_override("font", ThemeTokens.font_mono(700))
		btn.add_theme_font_size_override("font_size", 36)
		btn.add_theme_color_override("font_color", ThemeTokens.TEXT)
		btn.add_theme_color_override("font_disabled_color", Color(0.60, 0.55, 0.48))

		# Badge pill (top-right of button, count)
		var badge := Label.new()
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_override("font", ThemeTokens.font_mono(700))
		badge.add_theme_font_size_override("font_size", 22)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.add_theme_stylebox_override("normal", ThemeTokens.sb_powerup_badge())
		badge.size = Vector2(52.0, 32.0)
		badge.position = Vector2(bx + i * (btn_size + btn_gap) + btn_size - 36.0, by - 14.0)
		badge.z_index = 5
		add_child(badge)

		# Name label (below button)
		var nm := Label.new()
		nm.text = btn_names[i]
		nm.size = Vector2(btn_size, 30.0)
		nm.position = Vector2(bx + i * (btn_size + btn_gap), nm_y)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_override("font", ThemeTokens.font_inter(600))
		nm.add_theme_font_size_override("font_size", 20)
		nm.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
		add_child(nm)

		match i:
			0: _badge_hint    = badge
			1: _badge_shuffle = badge
			2: _badge_remove  = badge

	queue_redraw()
	update_power_up_ui()
	_setup_pause_overlay()
	_setup_game_over_overlay()


# ==========================================
# OVERLAY THEMING (Pause + Game Over)
# ==========================================

func _make_overlay_card_sb() -> StyleBoxFlat:
	var sb := ThemeTokens.sb_card()
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 28
	sb.shadow_offset = Vector2(0, 10)
	return sb

func _make_go_gap(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

func _make_go_stat_cell(value_text: String, label_text: String) -> Panel:
	var cell := Panel.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 68)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe7d5")
	ThemeTokens._set_radius(sb, 12)
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_color = Color("e3d8c0")
	cell.add_theme_stylebox_override("panel", sb)

	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_top", 11)
	mc.add_theme_constant_override("margin_bottom", 11)
	mc.add_theme_constant_override("margin_left", 6)
	mc.add_theme_constant_override("margin_right", 6)
	cell.add_child(mc)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 5)
	mc.add_child(vb)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_override("font", ThemeTokens.font_mono(700))
	val_lbl.add_theme_font_size_override("font_size", 22)
	val_lbl.add_theme_color_override("font_color", Color("2f3a36"))
	vb.add_child(val_lbl)

	var sub_font := ThemeTokens.font_inter(600)
	sub_font.spacing_glyph = 5
	var sub_lbl := Label.new()
	sub_lbl.text = label_text
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", sub_font)
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color("8a9590"))
	vb.add_child(sub_lbl)

	return cell

func _style_overlay_btn_primary(btn: Button, label: String) -> void:
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 60)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := ThemeTokens.font_inter(700); f.spacing_glyph = 4
	btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(sb, 16)
	sb.shadow_color = Color(ThemeTokens.MINT_DARK, 0.53)
	sb.shadow_size = 6; sb.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = ThemeTokens.MINT_DARK
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)

func _style_overlay_btn_secondary(btn: Button, label: String) -> void:
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := ThemeTokens.font_inter(700); f.spacing_glyph = 3
	btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", ThemeTokens.TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe7d5")
	ThemeTokens._set_radius(sb, 16)
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_color = Color("e3d8c0")
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color("dfd6c5")
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)

func _style_overlay_btn_ghost(btn: Button, label: String) -> void:
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := ThemeTokens.font_inter(700); f.spacing_glyph = 5
	btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	ThemeTokens._set_radius(sb, 14)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _setup_pause_overlay() -> void:
	var layer := $PauseMenuLayer
	var sw := get_viewport_rect().size.x

	# Restyle dim
	var dim := layer.get_node("ColorRect") as ColorRect
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.11, 0.125, 0.118, 0.48)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	# Grab button nodes before dismantling old vbox
	var old_vbox := layer.get_node("VBoxContainer") as VBoxContainer
	var btn_c  := old_vbox.get_node("BtnContinue")    as Button
	var btn_r  := old_vbox.get_node("BtnRestart")     as Button
	var btn_ch := old_vbox.get_node("BtnChangeLevel") as Button
	var btn_q  := old_vbox.get_node("BtnQuit")        as Button
	for b in [btn_c, btn_r, btn_ch, btn_q]:
		old_vbox.remove_child(b)
	old_vbox.queue_free()

	# Centered card
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(sw * 0.78, 0)
	card.add_theme_stylebox_override("panel", _make_overlay_card_sb())
	center.add_child(card)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 28)
	mc.add_theme_constant_override("margin_right", 28)
	mc.add_theme_constant_override("margin_top", 36)
	mc.add_theme_constant_override("margin_bottom", 28)
	card.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	mc.add_child(vbox)

	# Pause icon chip
	var ic := CenterContainer.new()
	vbox.add_child(ic)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(56, 56)
	var sb_chip := StyleBoxFlat.new()
	sb_chip.bg_color = Color("cde9da")
	ThemeTokens._set_radius(sb_chip, 18)
	sb_chip.border_width_left = 2; sb_chip.border_width_right = 2
	sb_chip.border_width_top = 2; sb_chip.border_width_bottom = 2
	sb_chip.border_color = Color(ThemeTokens.MINT_DARK, 0.27)
	chip.add_theme_stylebox_override("panel", sb_chip)
	ic.add_child(chip)
	var icon_lbl := Label.new()
	icon_lbl.text = "⏸"
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	chip.add_child(icon_lbl)

	vbox.add_child(_make_go_gap(14))

	# "PAUSED" title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tf := ThemeTokens.font_inter(700); tf.spacing_glyph = 7
	title.add_theme_font_override("font", tf)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vbox.add_child(title)

	vbox.add_child(_make_go_gap(24))

	# Buttons
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_vbox)

	_style_overlay_btn_primary(btn_c, "CONTINUE")
	_style_overlay_btn_secondary(btn_r, "RESTART")
	_style_overlay_btn_secondary(btn_ch, "CHANGE LEVEL")
	_style_overlay_btn_ghost(btn_q, "LEAVE")
	btn_vbox.add_child(btn_c)
	btn_vbox.add_child(btn_r)
	btn_vbox.add_child(btn_ch)
	btn_vbox.add_child(btn_q)

func _setup_game_over_overlay() -> void:
	var layer := $GameOverLayer
	var sw := get_viewport_rect().size.x

	# Restyle dim
	var dim := layer.get_node("ColorRect") as ColorRect
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.11, 0.125, 0.118, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	# Grab button nodes
	var old_vbox := layer.get_node("VBoxContainer") as VBoxContainer
	var btn_r := old_vbox.get_node("BtnRestartOver") as Button
	var btn_q := old_vbox.get_node("BtnQuitOver")    as Button
	old_vbox.remove_child(btn_r)
	old_vbox.remove_child(btn_q)
	old_vbox.queue_free()

	# Centered card
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(sw * 0.78, 0)
	card.add_theme_stylebox_override("panel", _make_overlay_card_sb())
	center.add_child(card)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 22)
	mc.add_theme_constant_override("margin_right", 22)
	mc.add_theme_constant_override("margin_top", 30)
	mc.add_theme_constant_override("margin_bottom", 22)
	card.add_child(mc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	mc.add_child(vbox)

	# NEW HIGH badge row (hidden by default)
	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(badge_row)
	var badge_panel := Panel.new()
	badge_panel.custom_minimum_size = Vector2(0, 26)
	var sb_badge := StyleBoxFlat.new()
	sb_badge.bg_color = ThemeTokens.MINT_DARK
	ThemeTokens._set_radius(sb_badge, 999)
	sb_badge.content_margin_left = 10; sb_badge.content_margin_right = 10
	sb_badge.content_margin_top = 5; sb_badge.content_margin_bottom = 5
	badge_panel.add_theme_stylebox_override("panel", sb_badge)
	badge_row.add_child(badge_panel)
	var badge_lbl := Label.new()
	badge_lbl.text = "★  NEW HIGH"
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var bf := ThemeTokens.font_inter(800); bf.spacing_glyph = 5
	badge_lbl.add_theme_font_override("font", bf)
	badge_lbl.add_theme_font_size_override("font_size", 9)
	badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge_panel.add_child(badge_lbl)
	_go_new_high = badge_row
	_go_new_high.hide()

	vbox.add_child(_make_go_gap(10))

	# Icon chip
	var ic := CenterContainer.new()
	vbox.add_child(ic)
	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(56, 56)
	_go_icon_sb = StyleBoxFlat.new()
	_go_icon_sb.bg_color = Color("fde8c4")
	ThemeTokens._set_radius(_go_icon_sb, 18)
	icon_panel.add_theme_stylebox_override("panel", _go_icon_sb)
	ic.add_child(icon_panel)
	_go_icon_lbl = Label.new()
	_go_icon_lbl.text = "⏱"
	_go_icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_go_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_go_icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_panel.add_child(_go_icon_lbl)

	vbox.add_child(_make_go_gap(12))

	# Kind label ("TIME'S UP" etc)
	_go_kind_label = Label.new()
	_go_kind_label.text = "TIME'S UP"
	_go_kind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kf := ThemeTokens.font_inter(700); kf.spacing_glyph = 6
	_go_kind_label.add_theme_font_override("font", kf)
	_go_kind_label.add_theme_font_size_override("font_size", 18)
	_go_kind_label.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vbox.add_child(_go_kind_label)

	vbox.add_child(_make_go_gap(16))

	# Divider
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color("e3d8c0")
	vbox.add_child(divider)

	vbox.add_child(_make_go_gap(14))

	# Score
	_go_score_label = Label.new()
	_go_score_label.text = "0"
	_go_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_score_label.add_theme_font_override("font", ThemeTokens.font_mono(800))
	_go_score_label.add_theme_font_size_override("font_size", 46)
	_go_score_label.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vbox.add_child(_go_score_label)

	vbox.add_child(_make_go_gap(7))

	var score_sub := Label.new()
	score_sub.text = "SCORE"
	score_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sf := ThemeTokens.font_inter(600); sf.spacing_glyph = 7
	score_sub.add_theme_font_override("font", sf)
	score_sub.add_theme_font_size_override("font_size", 12)
	score_sub.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(score_sub)

	vbox.add_child(_make_go_gap(18))

	# Stats row (children rebuilt each time in _update_game_over_ui)
	_go_stats_row = HBoxContainer.new()
	_go_stats_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_go_stats_row)

	vbox.add_child(_make_go_gap(18))

	# Buttons
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_vbox)

	_style_overlay_btn_primary(btn_r, "RESTART")
	_style_overlay_btn_ghost(btn_q, "LEAVE")
	btn_vbox.add_child(btn_r)
	btn_vbox.add_child(btn_q)

func _update_game_over_ui(reason: String, final_score: int, time_played: float, max_combo_val: int) -> void:
	var icon_meta := {
		"TIME_UP":  {icon = "⏱", title = "TIME'S UP", chip = Color("fde8c4")},
		"NO_MOVES": {icon = "✕", title = "NO MOVES",  chip = Color("e5d4ee")},
		"NO_LIVES": {icon = "♡", title = "NO LIVES",  chip = Color("f7c8c8")},
		"LEFT":     {icon = "←", title = "LEFT",       chip = Color("d8dfe5")},
	}
	var meta: Dictionary = icon_meta.get(reason, {icon = "◉", title = "GAME OVER", chip = Color("dceee2")})

	_go_icon_sb.bg_color = meta["chip"]
	_go_icon_lbl.text    = meta["icon"]
	_go_kind_label.text  = meta["title"]
	_go_score_label.text = str(final_score)

	# NEW HIGH check (before submit_score is called)
	var hs := Global.load_highscore()
	var entries: Array = hs.get(gameplay_mode, [])
	var is_new_high := entries.is_empty() or final_score > int(entries[0].get("score", 0))
	_go_new_high.visible = is_new_high

	# Rebuild stats cells
	for child in _go_stats_row.get_children():
		child.queue_free()
	_go_stats_row.add_child(_make_go_stat_cell(format_time_mmss(time_played), "TIME"))
	_go_stats_row.add_child(_make_go_stat_cell("×" + str(max_combo_val), "BEST COMBO"))


# ==========================================
# SCORING
# ==========================================
func calculate_points(sel_tiles: Array) -> int:
	var base: int
	if gameplay_mode in ["ZEN", "MUTATION", "CHALLENGE"]:
		var min_x = sel_tiles[0].x; var max_x = sel_tiles[0].x
		var min_y = sel_tiles[0].y; var max_y = sel_tiles[0].y
		for pos in sel_tiles:
			min_x = min(min_x, pos.x); max_x = max(max_x, pos.x)
			min_y = min(min_y, pos.y); max_y = max(max_y, pos.y)
		var bbox_area = (max_x - min_x + 1) * (max_y - min_y + 1)
		var tile_count = sel_tiles.size()
		var density = float(tile_count) / float(bbox_area)
		if density < 0.3:
			base = tile_count
		else:
			base = bbox_area
		if DEBUG_MODE:
			print("[ZEN/MUT density] density=%.2f  tile=%d  bbox=%d  base=%d" % [density, tile_count, bbox_area, base])
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
		if is_instance_valid(_combo_ring):
			_combo_ring.visible = false
		return
	combo_label.show()
	var colors = ThemeTokens.combo_color(combo_count)
	combo_label.add_theme_color_override("font_color", colors["text"])
	# Transparent bg — ring draws the background circle behind
	combo_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if is_instance_valid(_combo_ring):
		_combo_ring.visible = true
		_combo_ring.combo_count = combo_count
		_combo_ring.queue_redraw()
	var peak: float = 1.2 + min(combo_count - 2, 3) * 0.1  # x2=1.2 x3=1.3 x4=1.4 x5+=1.5
	var tween = create_tween()
	tween.tween_property(combo_label, "scale", Vector2(peak, peak), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_CUBIC)


func show_floating_score(points: int, used_combo: int):
	var label = Label.new()
	label.text = "+%d" % points
	label.add_theme_font_override("font", ThemeTokens.font_mono(700))
	label.add_theme_font_size_override("font_size", 24)
	var colors = ThemeTokens.combo_color(used_combo)
	label.add_theme_color_override("font_color", colors["text"])
	label.add_theme_stylebox_override("normal", ThemeTokens.sb_score_chip(used_combo))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	var pill_w := float(label.text.length()) * 15.0 + 40.0
	label.size = Vector2(pill_w, 36)
	var box_center = selection_box.position + selection_box.size / 2.0
	label.position = box_center - Vector2(pill_w * 0.5, 18)
	label.scale = Vector2(1.4, 1.4)
	label.pivot_offset = Vector2(pill_w * 0.5, 18.0)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position", label.position - Vector2(0, 80), 1.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.3)
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
						if gameplay_mode == "CHALLENGE":
							# Bbox từ vị trí tile thực (giống evaluate_selection)
							var tc_min_x = int(rect_tiles[0].x); var tc_max_x = int(rect_tiles[0].x)
							var tc_min_y = int(rect_tiles[0].y); var tc_max_y = int(rect_tiles[0].y)
							for tp in rect_tiles:
								tc_min_x = min(tc_min_x, int(tp.x)); tc_max_x = max(tc_max_x, int(tp.x))
								tc_min_y = min(tc_min_y, int(tp.y)); tc_max_y = max(tc_max_y, int(tp.y))
							var tile_bbox := Rect2i(tc_min_x, tc_min_y, tc_max_x - tc_min_x + 1, tc_max_y - tc_min_y + 1)
							if not ZenLevelManager.validate_constraint(tile_bbox, rect_tiles.size(), Global.zen_current_level)["valid"]:
								continue
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
	if is_tutorial_active: return
	is_tutorial_active = true
	var layer := CanvasLayer.new()
	layer.name = "TutorialOverlay"
	var tut: Control = load("res://tutorial.tscn").instantiate()
	layer.add_child(tut)
	add_child(layer)
	tut.close_requested.connect(_on_tutorial_overlay_closed.bind(layer))


func _on_tutorial_overlay_closed(layer: CanvasLayer):
	layer.queue_free()
	is_tutorial_active = false


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
# SAVE / LOAD (ZEN & MUTATION)
# ==========================================
func _save_game_state():
	if not (gameplay_mode in ["ZEN", "MUTATION", "CHALLENGE"]): return
	var tile_list = []
	for pos in tiles.keys():
		var t = tiles[pos]
		tile_list.append({"x": int(pos.x), "y": int(pos.y), "value": t.value, "type": t.tile_type})
	var save_data = {
		"mode": gameplay_mode,
		"score": score,
		"accumulated_time": accumulated_time,
		"hint_count": hint_count,
		"shuffle_count": shuffle_count,
		"remove_count": remove_count,
		"zen_milestone_count": zen_milestone_count,
		"tiles": tile_list,
	}
	if gameplay_mode in ["ZEN", "CHALLENGE"]:
		save_data["current_level"] = Global.zen_current_level
		save_data["unlocked_levels"] = Global.zen_unlocked_levels
	Global.save_game(save_data, gameplay_mode)


func _load_game_state():
	var data = Global.load_game(gameplay_mode)
	if data.is_empty(): return

	score               = int(data.get("score", 0))
	accumulated_time    = float(data.get("accumulated_time", 0.0))
	hint_count          = int(data.get("hint_count", 1))
	shuffle_count       = int(data.get("shuffle_count", 1))
	remove_count        = int(data.get("remove_count", 1))
	zen_milestone_count = int(data.get("zen_milestone_count", 0))
	if gameplay_mode in ["ZEN", "CHALLENGE"]:
		Global.zen_current_level   = int(data.get("current_level", 1))
		Global.zen_unlocked_levels = data.get("unlocked_levels", [1])

	for td in data.get("tiles", []):
		var pos = Vector2(int(td["x"]), int(td["y"]))
		var new_tile = TileFactory.make(td["type"])
		new_tile.position = start_pos + Vector2(int(td["x"]) * tile_size, int(td["y"]) * tile_size)
		new_tile.scale = _tile_normal_scale()
		add_child(new_tile)
		new_tile.set_data(pos, int(td["value"]), td["type"])
		tiles[pos] = new_tile

	update_score_ui()
	update_power_up_ui()
	_update_challenge_hud()


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
		{"label": "Time Up",   "method": "_debug_time_up",                 "modes": ["CLASSIC", "GRAVITY"]},
		{"label": "Next Lv",   "method": "_debug_next_level",              "modes": ["GRAVITY"]},
		{"label": "Next Lv",   "method": "_debug_challenge_next_level",    "modes": ["CHALLENGE"]},
		{"label": "+200 pts",  "method": "_debug_add_score",               "modes": []},
		{"label": "+10 PU",    "method": "_debug_add_powerups",            "modes": []},
		{"label": "Reset PU",  "method": "_debug_reset_powerups",          "modes": []},
		{"label": "Reset ACH", "method": "_debug_reset_achievements",       "modes": []},
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

	var speed_btn = Button.new()
	speed_btn.text = "x1 Speed"
	speed_btn.custom_minimum_size = Vector2(90, 30)
	speed_btn.add_theme_font_size_override("font_size", 13)
	speed_btn.add_theme_color_override("font_color", Color.BLACK)
	speed_btn.modulate = Color(1.0, 0.85, 0.1, 0.95)
	speed_btn.pressed.connect(func():
		var scales = [1.0, 2.0, 4.0]
		var labels = ["x1 Speed", "x2 Speed", "x4 Speed"]
		var idx = 0
		for i in scales.size():
			if abs(Engine.time_scale - scales[i]) < 0.1:
				idx = i
				break
		idx = (idx + 1) % scales.size()
		Engine.time_scale = scales[idx]
		speed_btn.text = labels[idx]
	)
	panel.add_child(speed_btn)

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
	if gravity_level == 4:
		var dirs = ["DOWN", "UP", "LEFT", "RIGHT"]
		gravity_l4_dir = dirs[randi() % dirs.size()]
	update_gravity_level_ui()
	_show_level_up_banner(gravity_level)
	_refresh_apple_directions(true)


func _debug_challenge_next_level():
	if gameplay_mode != "CHALLENGE": return
	var next := Global.zen_current_level + 1
	if next > ZenLevels.LEVELS.size(): return
	Global.zen_current_level = next
	if not (next in Global.zen_unlocked_levels):
		Global.zen_unlocked_levels.append(next)
	_update_challenge_hud()
	show_floating_text_center("L%d %s" % [next, ZenLevelManager.get_level_name(next)], Color.GOLD)


func _debug_add_score():
	score += 200
	update_score_ui()
	if gameplay_mode in ["ZEN", "CHALLENGE"]:
		_check_zen_milestone()


func _debug_add_powerups():
	hint_count   += 10
	shuffle_count += 10
	remove_count  += 10
	update_power_up_ui()


func _debug_reset_powerups():
	hint_count = 1
	remove_count = 1
	shuffle_count = 3 if gameplay_mode == "GRAVITY" else 1
	if gameplay_mode == "GRAVITY":
		update_lives_ui()
	update_power_up_ui()
	show_floating_text_center("Power-ups reset!", Color.CYAN)


# ==========================================
# GRAVITY APPLE HELPERS
# ==========================================
func _set_apple_dir(tile: BaseTile, animate: bool) -> void:
	if gameplay_mode != "GRAVITY": return
	if tile.has_method("set_direction"):
		tile.set_direction(get_gravity_direction(), animate)


func _refresh_apple_directions(animate: bool) -> void:
	if gameplay_mode != "GRAVITY": return
	var dir := get_gravity_direction()
	for tile in tiles.values():
		if tile.has_method("set_direction"):
			tile.set_direction(dir, animate)


func _debug_reset_achievements():
	Global.reset_achievements()
	show_floating_text_center("Achievements reset!", Color.ORANGE)


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


func _flash_wrong_tiles() -> void:
	for pos in selected_tiles:
		if not tiles.has(pos): continue
		var t = tiles[pos]
		var tween = create_tween()
		tween.tween_property(t, "modulate", Color.RED, 0.07)
		tween.tween_property(t, "modulate", Color.WHITE, 0.07)
		tween.tween_property(t, "modulate", Color.RED, 0.07)
		tween.tween_property(t, "modulate", Color.WHITE, 0.07)


func _spawn_tile_burst(pos: Vector2, tile_type: String) -> void:
	var burst = CPUParticles2D.new()
	burst.position = pos
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 18
	burst.lifetime = 0.55
	burst.initial_velocity_min = 110.0
	burst.initial_velocity_max = 230.0
	burst.spread = 180.0
	burst.gravity = Vector2(0, 360)
	burst.scale_amount_min = 5.0
	burst.scale_amount_max = 11.0
	match tile_type:
		"NEGATIVE": burst.color = ThemeTokens.NEG_DARK
		"VIRUS":    burst.color = ThemeTokens.VIRUS_DARK
		"JOKER":    burst.color = ThemeTokens.JOKER_STROKE
		"MYSTERY":  burst.color = ThemeTokens.MYSTERY_REV_BG
		_:          burst.color = ThemeTokens.MINT
	add_child(burst)
	burst.finished.connect(burst.queue_free)
	burst.emitting = true

	var sparkle = CPUParticles2D.new()
	sparkle.position = pos
	sparkle.one_shot = true
	sparkle.explosiveness = 1.0
	sparkle.amount = 8
	sparkle.lifetime = 0.30
	sparkle.initial_velocity_min = 55.0
	sparkle.initial_velocity_max = 130.0
	sparkle.spread = 180.0
	sparkle.gravity = Vector2(0, 80)
	sparkle.scale_amount_min = 2.0
	sparkle.scale_amount_max = 4.0
	sparkle.color = Color(1.0, 1.0, 1.0, 0.9)
	add_child(sparkle)
	sparkle.finished.connect(sparkle.queue_free)
	sparkle.emitting = true
