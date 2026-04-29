extends BaseTile

func get_effective_value() -> int:
	return 0

func _update_type_visuals():
	$Background/Label.text = "★"
	$Background.modulate = Color.GOLD
