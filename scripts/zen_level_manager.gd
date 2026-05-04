class_name ZenLevelManager

static func validate_constraint(rect: Rect2i, tile_count: int, level: int) -> Dictionary:
	var rules = ZenLevels.LEVELS[level - 1]["constraints"]
	var bbox_w = rect.size.x
	var bbox_h = rect.size.y
	var bbox_area = bbox_w * bbox_h

	if rules.has("min_tiles") and tile_count < rules["min_tiles"]:
		return {"valid": false, "reason": "Need >= %d tiles" % rules["min_tiles"]}

	if rules.has("min_bbox_area") and bbox_area < rules["min_bbox_area"]:
		return {"valid": false, "reason": "Area too small (need >= %d)" % rules["min_bbox_area"]}

	if rules.has("min_square_size"):
		var ms = rules["min_square_size"]
		if bbox_w != bbox_h or bbox_w < ms:
			return {"valid": false, "reason": "Must be >= %dx%d square" % [ms, ms]}
	elif rules.has("must_be_square") and bbox_w != bbox_h:
		return {"valid": false, "reason": "Must be square"}

	if rules.has("min_bbox_size"):
		var ms = rules["min_bbox_size"]
		var ok = (bbox_w >= ms["x"] and bbox_h >= ms["y"]) or (bbox_w >= ms["y"] and bbox_h >= ms["x"])
		if not ok:
			return {"valid": false, "reason": "Region too small"}

	return {"valid": true}


static func get_constraint_text(level: int) -> String:
	return ZenLevels.LEVELS[level - 1]["constraint_text"]


static func get_level_name(level: int) -> String:
	return ZenLevels.LEVELS[level - 1]["name"]


static func get_unlock_score(level: int) -> int:
	return ZenLevels.LEVELS[level - 1]["unlock_score"]


static func is_last_level(level: int) -> bool:
	return level >= ZenLevels.LEVELS.size()
