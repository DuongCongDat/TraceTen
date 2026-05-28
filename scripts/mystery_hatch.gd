class_name MysteryHatch
extends Control

func _draw():
	var step := 12.0
	var w := size.x
	var h := size.y
	var color := Color(1, 1, 1, 0.12)
	# Diagonal lines at 45°, top-left to bottom-right
	var i := -int(h / step)
	while i <= int((w + h) / step):
		var x1 := i * step
		var y1 := 0.0
		var x2 := x1 + h
		var y2 := h
		draw_line(Vector2(x1, y1), Vector2(x2, y2), color, 1.0)
		i += 1
