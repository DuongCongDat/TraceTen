extends Node

const SFX_DIR = "res://audio/sfx/"
const POOL_SIZE = 8

var _pool: Array = []
var _pool_idx: int = 0
var _streams: Dictionary = {}


func _ready() -> void:
	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

	var ids = [
		"score", "wrong", "combo", "powerup_use", "powerup_gain",
		"shuffle", "tile_remove", "virus_explode", "gameover",
		"achievement", "level_up"
	]
	for id in ids:
		var path = SFX_DIR + "sfx_" + id + ".ogg"
		_streams[id] = load(path)


func play_sfx(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(id):
		return
	var player = _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	player.stream = _streams[id]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
