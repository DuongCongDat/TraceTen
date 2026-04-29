class_name TileFactory

const TILE_SCENE = preload("res://tile.tscn")
const SCRIPTS = {
	"VIRUS":    preload("res://tile_virus.gd"),
	"MYSTERY":  preload("res://tile_mystery.gd"),
	"JOKER":    preload("res://tile_joker.gd"),
	"NEGATIVE": preload("res://tile_negative.gd"),
}

# Trả về {type, val} dựa trên mode hiện tại.
static func roll(mode: String) -> Dictionary:
	if mode == "MUTATION":
		return _roll_mutation()
	return {"type": "NORMAL", "val": randi_range(1, 9)}

static func _roll_mutation() -> Dictionary:
	var type = "NORMAL"
	var val = randi_range(1, 9)

	var p = randf()
	if p <= 0.70:
		val = randi_range(1, 9)
	elif p <= 0.95:
		val = randi_range(-5, -1)
		type = "NEGATIVE"
	else:
		val = randi_range(-9, -6)
		type = "NEGATIVE"

	var r = randf()
	if r < 0.15:    type = "MYSTERY"
	elif r < 0.20:  type = "JOKER"
	elif r < 0.30:  type = "VIRUS"

	return {"type": type, "val": val}

# Tạo node tile với script đúng theo type. Caller tự add_child và set_data.
static func make(type: String) -> BaseTile:
	var tile = TILE_SCENE.instantiate()
	if SCRIPTS.has(type):
		tile.set_script(SCRIPTS[type])
	return tile
