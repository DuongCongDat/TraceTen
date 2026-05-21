extends Node

const SFX_DIR    = "res://audio/sfx/"
const POOL_SIZE  = 8
const BGM_PATH   = "res://assets/bgm/bgm_main.ogg"
const SETTINGS_PATH = "user://settings.json"

var _pool: Array      = []
var _pool_idx: int    = 0
var _streams: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween

# Linear volume 0.0–1.0  (1.0 = 0 dB)
var _sfx_volume: float = 1.0
var _bgm_volume: float = 0.25   # ≈ -12 dB default


func _ready() -> void:
	_load_settings()

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
		if ResourceLoader.exists(path):
			_streams[id] = load(path)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	if ResourceLoader.exists(BGM_PATH):
		_bgm_player.stream = load(BGM_PATH)


func play_sfx(id: String, pitch: float = 1.0) -> void:
	if not _streams.has(id):
		return
	var player = _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	player.stream      = _streams[id]
	player.pitch_scale = pitch
	player.volume_db   = linear_to_db(_sfx_volume) if _sfx_volume > 0.001 else -80.0
	player.play()


func play_bgm(fade_in: float = 1.5) -> void:
	if _bgm_player.stream == null or _bgm_player.playing:
		return
	var target_db = linear_to_db(_bgm_volume) if _bgm_volume > 0.001 else -80.0
	_bgm_player.volume_db = -80.0
	_bgm_player.play()
	_kill_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", target_db, fade_in)


func stop_bgm(fade_out: float = 2.0) -> void:
	if not _bgm_player.playing:
		return
	_kill_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, fade_out)
	_bgm_tween.tween_callback(_bgm_player.stop)


func pause_bgm() -> void:
	_bgm_player.stream_paused = true


func resume_bgm() -> void:
	_bgm_player.stream_paused = false


func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clamp(linear, 0.0, 1.0)
	_save_settings()


func set_bgm_volume(linear: float) -> void:
	_bgm_volume = clamp(linear, 0.0, 1.0)
	if _bgm_player.playing and not _bgm_player.stream_paused:
		_bgm_player.volume_db = linear_to_db(_bgm_volume) if _bgm_volume > 0.001 else -80.0
	_save_settings()


func get_sfx_volume() -> float:
	return _sfx_volume


func get_bgm_volume() -> float:
	return _bgm_volume


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		_sfx_volume = float(data.get("sfx_volume", 1.0))
		_bgm_volume = float(data.get("bgm_volume", 0.25))


func _save_settings() -> void:
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"sfx_volume": _sfx_volume, "bgm_volume": _bgm_volume}))
	f.close()


func _kill_bgm_tween() -> void:
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
