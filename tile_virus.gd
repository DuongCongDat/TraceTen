extends BaseTile

func _update_type_visuals():
	$Background/Label.text = str(value)
	$Background.modulate = Color.GREEN_YELLOW

func _process(delta):
	if is_selected or get_parent().is_paused:
		return
	virus_timer += delta
	if virus_timer < 10.0:
		return
	virus_timer = 0.0

	var p = randf()
	if p <= 0.65:
		value = randi_range(1, 9)
		#value = 0 test
	elif p <= 0.95:
		value = randi_range(-5, -1)
	elif p <= 0.99:
		value = randi_range(-9, -6)
	else:
		value = 0

	if value == 0:
		if get_parent().has_method("kill_tile_from_virus"):
			get_parent().kill_tile_from_virus(grid_pos)
	else:
		update_visuals()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
