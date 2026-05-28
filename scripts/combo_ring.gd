class_name ComboRing
extends Control

var combo_count: int = 0
var ratio: float = 1.0  # 1.0 = full, 0.0 = expired

func _draw():
	if combo_count <= 1:
		return
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.5 - 2.0
	var colors = ThemeTokens.combo_color(combo_count)
	# Filled background circle
	draw_circle(center, radius - 2.0, colors["bg"])
	# Track arc (faint)
	draw_arc(center, radius, 0.0, TAU, 64,
		Color(colors["stroke"].r, colors["stroke"].g, colors["stroke"].b, 0.3), 4.0, true)
	# Countdown arc (depletes clockwise from top)
	if ratio > 0.01:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * ratio, 64,
			colors["stroke"], 4.0, true)
