extends Node

const SFX_DIR = "res://audio/sfx/"
const POOL_SIZE = 8

# Đặt file nhạc vào res://assets/bgm/ và đổi tên thành bgm_main.ogg (hoặc .mp3)
const BGM_PATH = "res://assets/bgm/bgm_main.ogg"
const BGM_VOLUME_DB = -12.0

var _pool: Array = []
var _pool_idx: int = 0
var _streams: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween


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

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	if ResourceLoader.exists(BGM_PATH):
		_bgm_player.stream = load(BGM_PATH)


func play_sfx(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(id):
		return
	var player = _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	player.stream = _streams[id]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func play_bgm(fade_in: float = 1.5) -> void:
	if _bgm_player.stream == null:
		return
	if _bgm_player.playing:
		return
	_bgm_player.volume_db = -80.0
	_bgm_player.play()
	_kill_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", BGM_VOLUME_DB, fade_in)


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


func _kill_bgm_tween() -> void:
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
