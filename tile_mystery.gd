extends BaseTile

func _update_type_visuals():
	$Background/Label.text = str(value) if is_selected else "?"
	$Background.modulate = Color.DARK_GRAY

func select():
	is_selected = true
	$Background.modulate = $Background.modulate.darkened(0.2)
	update_visuals()
