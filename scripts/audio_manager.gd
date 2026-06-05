extends Node

const SFX_DIR      = "res://audio/sfx/"
const POOL_SIZE    = 8
const SETTINGS_PATH = "user://settings.json"

const BGM_TRACKS = {
	"MENU":     "res://assets/bgm/menu.ogg",
	"CLASSIC":  "res://assets/bgm/classic.ogg",
	"GRAVITY":  "res://assets/bgm/gravity.ogg",
	"MUTATION": "res://assets/bgm/mutation.ogg",
}

const ZEN_TRACKS = [
	"res://assets/bgm/zen_01.ogg",
	"res://assets/bgm/zen_02.ogg",
	"res://assets/bgm/zen_03.ogg",
	"res://assets/bgm/zen_04.ogg",
	"res://assets/bgm/zen_05.ogg",
	"res://assets/bgm/zen_06.ogg",
	"res://assets/bgm/zen_07.ogg",
	"res://assets/bgm/zen_08.ogg",
]

var _pool: Array      = []
var _pool_idx: int    = 0
var _streams: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween

var _sfx_volume: float = 1.0
var _bgm_volume: float = 0.25

var _current_mode: String = ""
var _zen_playlist: Array  = []
var _zen_index: int       = 0


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
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)


func play_bgm(mode: String, fade_in: float = 1.5) -> void:
	if _current_mode == mode and _bgm_player.playing:
		return

	_current_mode = mode
	_kill_bgm_tween()
	_bgm_player.stop()

	var stream: AudioStream
	if mode in ["ZEN", "CHALLENGE"]:
		_build_zen_playlist()
		stream = _zen_stream_at(_zen_index)
	elif BGM_TRACKS.has(mode):
		stream = _load_stream(BGM_TRACKS[mode])

	if stream == null:
		return

	var target_db = linear_to_db(_bgm_volume) if _bgm_volume > 0.001 else -80.0
	_bgm_player.stream    = stream
	_bgm_player.volume_db = -80.0
	_bgm_player.play()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", target_db, fade_in)


func stop_bgm(fade_out: float = 2.0) -> void:
	if not _bgm_player.playing:
		return
	_current_mode = ""
	_kill_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, fade_out)
	_bgm_tween.tween_callback(_bgm_player.stop)


func pause_bgm() -> void:
	_bgm_player.stream_paused = true


func resume_bgm() -> void:
	_bgm_player.stream_paused = false


func play_sfx(id: String, pitch: float = 1.0) -> void:
	if not _streams.has(id):
		return
	var player = _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	player.stream      = _streams[id]
	player.pitch_scale = pitch
	player.volume_db   = linear_to_db(_sfx_volume) if _sfx_volume > 0.001 else -80.0
	player.play()


func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clamp(linear, 0.0, 1.0)
	_save_settings()


func set_bgm_volume(linear: float) -> void:
	_bgm_volume = clamp(linear, 0.0, 1.0)
	_kill_bgm_tween()
	_bgm_player.volume_db = linear_to_db(_bgm_volume) if _bgm_volume > 0.001 else -80.0
	_save_settings()


func get_sfx_volume() -> float:
	return _sfx_volume


func get_bgm_volume() -> float:
	return _bgm_volume


func _build_zen_playlist() -> void:
	_zen_playlist = ZEN_TRACKS.duplicate()
	_zen_playlist.shuffle()
	_zen_index = 0


func _zen_stream_at(idx: int) -> AudioStream:
	if _zen_playlist.is_empty():
		return null
	return _load_stream(_zen_playlist[idx])


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var s = load(path)
	if s is AudioStreamOggVorbis:
		s.loop = true
	return s


func _on_bgm_finished() -> void:
	if _current_mode not in ["ZEN", "CHALLENGE"]:
		return
	_zen_index += 1
	if _zen_index >= _zen_playlist.size():
		_zen_playlist.shuffle()
		_zen_index = 0
	var stream = _zen_stream_at(_zen_index)
	if stream == null:
		return
	_bgm_player.stream    = stream
	_bgm_player.volume_db = linear_to_db(_bgm_volume) if _bgm_volume > 0.001 else -80.0
	_bgm_player.play()


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
