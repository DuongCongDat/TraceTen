class_name TileFactory

const TILE_SCENE = preload("res://tile.tscn")
const SCRIPTS = {
	"VIRUS":    preload("res://tile_virus.gd"),
	"MYSTERY":  preload("res://tile_mystery.gd"),
	"JOKER":    preload("res://tile_joker.gd"),
	"NEGATIVE": preload("res://tile_negative.gd"),
}

static func roll(mode: String) -> Dictionary:
	if mode == "MUTATION":
		return _roll_mutation()
	return {"type": "NORMAL", "val": _weighted_normal_val()}

# Weighted 1-9: 1-5 appear more often → more valid sum-10 combinations
# 1:15% 2:15% 3:15% 4:13% 5:13% 6:10% 7:8% 8:6% 9:5%
static func _weighted_normal_val() -> int:
	var thresholds = [15, 30, 45, 58, 71, 81, 89, 95, 100]
	var r = randi() % 100
	for i in range(thresholds.size()):
		if r < thresholds[i]:
			return i + 1
	return 9

static func _roll_mutation() -> Dictionary:
	var type = "NORMAL"
	var val = _weighted_normal_val()

	var p = randf()
	if p > 0.70 and p <= 0.95:
		val = randi_range(-5, -1)
		type = "NEGATIVE"
	elif p > 0.95:
		val = randi_range(-9, -6)
		type = "NEGATIVE"

	var r = randf()
	if r < 0.15:    type = "MYSTERY"
	elif r < 0.20:  type = "JOKER"
	elif r < 0.30:  type = "VIRUS"

	return {"type": type, "val": val}

static func make(type: String) -> BaseTile:
	var tile = TILE_SCENE.instantiate()
	if SCRIPTS.has(type):
		tile.set_script(SCRIPTS[type])
	return tile
