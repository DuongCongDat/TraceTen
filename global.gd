extends Node

var selected_mode = "CLASSIC"
var load_save = false  # set true from mode_select when user picks "Continue"

var zen_current_level: int = 1
var zen_unlocked_levels: Array = [1]

# ── ACHIEVEMENT STATE ──────────────────────────────────────
signal achievement_unlocked(id: String)

const ACHIEVEMENT_PATH = "user://achievements.json"

var _achievements: Dictionary = {}  # {id: {unlocked, progress}}
var modes_played: Array = []        # persisted — for "all_modes" achievement
var hints_used_this_game: int = 0   # reset each game — for "no_hint" achievement
var last_played_mode: String = ""   # shown on PLAY button in main menu

const CONFIG_PATH = "user://config.json"

func save_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"last_played_mode": last_played_mode}))

func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH): return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file: return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		last_played_mode = parsed.get("last_played_mode", "")

const _SAVE_PATHS = {
	"ZEN":       "user://save_zen.json",
	"MUTATION":  "user://save_mutation.json",
	"CHALLENGE": "user://save_challenge.json",
}

func has_save(mode: String) -> bool:
	return _SAVE_PATHS.has(mode) and FileAccess.file_exists(_SAVE_PATHS[mode])

func save_game(data: Dictionary, mode: String):
	if not _SAVE_PATHS.has(mode): return
	var file = FileAccess.open(_SAVE_PATHS[mode], FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game(mode: String) -> Dictionary:
	if not _SAVE_PATHS.has(mode) or not FileAccess.file_exists(_SAVE_PATHS[mode]): return {}
	var file = FileAccess.open(_SAVE_PATHS[mode], FileAccess.READ)
	if not file: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func delete_save(mode: String):
	if _SAVE_PATHS.has(mode) and FileAccess.file_exists(_SAVE_PATHS[mode]):
		DirAccess.remove_absolute(_SAVE_PATHS[mode])

func get_save_preview(mode: String) -> Dictionary:
	var data = load_game(mode)
	if data.is_empty(): return {}
	return {
		"score": data.get("score", 0),
		"time": data.get("accumulated_time", 0.0),
	}

# ── HIGHSCORE ──────────────────────────────────────────────
const HIGHSCORE_PATH = "user://highscore.json"
const HIGHSCORE_TOP = 3

func load_highscore() -> Dictionary:
	if not FileAccess.file_exists(HIGHSCORE_PATH): return {}
	var file = FileAccess.open(HIGHSCORE_PATH, FileAccess.READ)
	if not file: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func save_highscore(data: Dictionary):
	var file = FileAccess.open(HIGHSCORE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func count_unlocked() -> int:
	var n := 0
	for v in _achievements.values():
		if v.get("unlocked", false): n += 1
	return n

func _ready():
	load_config()
	load_achievements()

func load_achievements():
	_achievements = {}
	modes_played = []
	if not FileAccess.file_exists(ACHIEVEMENT_PATH):
		return
	var file = FileAccess.open(ACHIEVEMENT_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	modes_played = parsed.get("_modes_played", [])
	parsed.erase("_modes_played")
	_achievements = parsed

func save_achievements():
	var data = _achievements.duplicate()
	data["_modes_played"] = modes_played
	var file = FileAccess.open(ACHIEVEMENT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _get_entry(id: String) -> Dictionary:
	if not _achievements.has(id):
		_achievements[id] = {"unlocked": false, "progress": 0}
	return _achievements[id]

func unlock_achievement(id: String):
	var entry = _get_entry(id)
	if entry["unlocked"]:
		return
	entry["unlocked"] = true
	_achievements[id] = entry
	save_achievements()
	achievement_unlocked.emit(id)

func reset_achievements():
	_achievements = {}
	modes_played = []
	if FileAccess.file_exists(ACHIEVEMENT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ACHIEVEMENT_PATH))

func update_achievement_progress(id: String, value: int):
	var entry = _get_entry(id)
	if entry["unlocked"]:
		return
	entry["progress"] = value
	_achievements[id] = entry
	var def = AchievementData.get_def(id)
	if not def.is_empty() and value >= def.get("target", 1):
		unlock_achievement(id)
	else:
		save_achievements()

func track_mode_played(mode: String):
	if mode in modes_played:
		return
	modes_played.append(mode)
	update_achievement_progress("all_modes", modes_played.size())

# ── HIGHSCORE ──────────────────────────────────────────────

func submit_score(mode: String, score: int, time_played: float, max_combo: int):
	var data = load_highscore()
	if not data.has(mode):
		data[mode] = []

	# Per-mode meta: games count + total score for avg
	var mk := mode + "_meta"
	if not data.has(mk):
		data[mk] = {"games": 0, "total_score": 0}
	data[mk]["games"]       = int(data[mk].get("games", 0))       + 1
	data[mk]["total_score"] = int(data[mk].get("total_score", 0)) + score

	# Short date string e.g. "Jun 2"
	var d := Time.get_date_dict_from_system()
	const MONTHS = ["","Jan","Feb","Mar","Apr","May","Jun",
	                "Jul","Aug","Sep","Oct","Nov","Dec"]
	var date_str := "%s %d" % [MONTHS[int(d["month"])], int(d["day"])]

	var entry = {"score": score, "time": time_played, "max_combo": max_combo, "date": date_str}
	data[mode].append(entry)
	data[mode].sort_custom(func(a, b): return a["score"] > b["score"])
	if data[mode].size() > HIGHSCORE_TOP:
		data[mode] = data[mode].slice(0, HIGHSCORE_TOP)
	save_highscore(data)
