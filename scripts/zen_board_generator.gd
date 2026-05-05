class_name ZenBoardGenerator

const GRID_COLS = 8
const GRID_ROWS = 12

# Returns a Dictionary: Vector2 -> {val, type}
# Positions not in the dict are intentional holes (for high-level sparse solutions).
static func generate(level: int) -> Dictionary:
	var rules: Dictionary = ZenLevels.LEVELS[level - 1]["constraints"]
	var min_tiles: int = rules.get("min_tiles", 3)

	var board: Dictionary = {}

	var sol_rect: Rect2i = _pick_solution_rect(rules, min_tiles)
	var sol_positions: Array = _pick_spanning_positions(sol_rect, min_tiles)
	var sol_values: Array = _generate_summing_to_10(min_tiles)

	for i in range(sol_positions.size()):
		board[sol_positions[i]] = {"val": sol_values[i], "type": "NORMAL"}

	# Fill board outside the solution rect with random tiles.
	# Positions inside the rect that are NOT solution tiles remain empty (holes),
	# which allows the player to drag the full rect and select exactly sol_positions.
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			var pos := Vector2(x, y)
			if board.has(pos) or _pos_in_rect(pos, sol_rect):
				continue
			board[pos] = {"val": _random_val(), "type": "NORMAL"}

	return board


static func _pick_solution_rect(rules: Dictionary, min_tiles: int) -> Rect2i:
	var w: int
	var h: int

	if rules.has("min_square_size"):
		var ms: int = rules["min_square_size"]
		w = ms
		h = ms
	elif rules.has("min_bbox_size"):
		var ms = rules["min_bbox_size"]
		w = ms["x"]
		h = ms["y"]
		if randf() < 0.5:
			var tmp = w; w = h; h = tmp
	elif rules.has("min_bbox_area"):
		var area: int = rules["min_bbox_area"]
		w = int(ceil(sqrt(float(area))))
		h = int(ceil(float(area) / float(w)))
		if randf() < 0.5:
			var tmp = w; w = h; h = tmp
	else:
		# Only min_tiles constraint — use a single-row (or column) rect.
		w = min(min_tiles, GRID_COLS)
		h = 1
		if randf() < 0.5:
			var tmp = w; w = h; h = tmp

	w = clampi(w, 1, GRID_COLS)
	h = clampi(h, 1, GRID_ROWS)

	var max_x := GRID_COLS - w
	var max_y := GRID_ROWS - h
	var x := randi() % (max_x + 1)
	var y := randi() % (max_y + 1)

	return Rect2i(x, y, w, h)


static func _pos_in_rect(pos: Vector2, rect: Rect2i) -> bool:
	return (pos.x >= rect.position.x and pos.x < rect.position.x + rect.size.x
		and pos.y >= rect.position.y and pos.y < rect.position.y + rect.size.y)


# Picks `count` positions inside `rect` whose bounding box spans the full rect.
# Uses two diagonal anchors to guarantee full span with just 2 tiles.
static func _pick_spanning_positions(rect: Rect2i, count: int) -> Array:
	var all_pos: Array = []
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			all_pos.append(Vector2(x, y))

	if all_pos.size() <= count:
		return all_pos

	var a1 := Vector2(rect.position.x, rect.position.y)
	var a2 := Vector2(rect.position.x + rect.size.x - 1, rect.position.y + rect.size.y - 1)

	var remaining: Array = all_pos.duplicate()
	remaining.erase(a1)
	remaining.erase(a2)
	remaining.shuffle()

	var result: Array = [a1, a2]
	for i in range(count - 2):
		if remaining.size() > 0:
			result.append(remaining.pop_front())

	result.shuffle()
	return result


# Generates `count` integers in [1,9] that sum to 10.
static func _generate_summing_to_10(count: int) -> Array:
	for _attempt in range(50):
		var nums: Array = []
		var remaining := 10
		var ok := true

		for i in range(count - 1):
			var max_val := mini(9, remaining - (count - i - 1))
			if max_val < 1:
				ok = false
				break
			var v := randi_range(1, max_val)
			nums.append(v)
			remaining -= v

		if ok and remaining >= 1 and remaining <= 9:
			nums.append(remaining)
			nums.shuffle()
			return nums

	# Fallback: all 1s, last tile absorbs the remainder.
	var nums: Array = []
	for i in range(count - 1):
		nums.append(1)
	nums.append(10 - (count - 1))
	nums.shuffle()
	return nums


# Same weighted distribution as TileFactory._weighted_normal_val().
static func _random_val() -> int:
	var thresholds := [15, 30, 45, 58, 71, 81, 89, 95, 100]
	var r := randi() % 100
	for i in range(thresholds.size()):
		if r < thresholds[i]:
			return i + 1
	return 9
