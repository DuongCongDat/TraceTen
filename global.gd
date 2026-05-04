extends Node

var selected_mode = "CLASSIC"
var load_save = false  # set true from mode_select when user picks "Continue"

var zen_current_level: int = 1
var zen_unlocked_levels: Array = [1]

const _SAVE_PATHS = {
	"ZEN":      "user://save_zen.json",
	"MUTATION": "user://save_mutation.json",
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
