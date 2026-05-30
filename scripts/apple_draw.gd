class_name AppleDraw
extends Control

var selected: bool = false
# Stem angle in radians; -PI/2 = stem pointing up (DOWN fall direction)
var stem_rad: float = -PI * 0.5

# Apple silhouette — initialized in _ready() (PackedVector2Array can't be a GDScript const).
# 22 points, centered at origin, stem/dimple pointing in -Y direction.
# Dimple at top center (y≈-20) is LOWER than the two bump peaks (y≈-28).
var _poly: PackedVector2Array

func _ready() -> void:
	_poly = PackedVector2Array([
		Vector2(-4,  -21),
		Vector2( 0,  -19),
		Vector2( 4,  -21),
		Vector2( 9,  -27),
		Vector2(15,  -29),
		Vector2(21,  -24),
		Vector2(25,  -14),
		Vector2(27,   -3),
		Vector2(27,    9),
		Vector2(24,   21),
		Vector2(17,   29),
		Vector2( 8,   33),
		Vector2( 0,   34),
		Vector2(-8,   33),
		Vector2(-17,  29),
		Vector2(-24,  21),
		Vector2(-27,   9),
		Vector2(-27,  -3),
		Vector2(-25, -14),
		Vector2(-21, -24),
		Vector2(-15, -29),
		Vector2(-9,  -27),
	])

func _draw():
	if _poly.is_empty():
		return
	var cx := size.x * 0.5
	var cy := size.y * 0.5 + 2.0

	var fill := ThemeTokens.APPLE_SEL_FILL if selected else ThemeTokens.APPLE_FILL
	var line := ThemeTokens.APPLE_SEL_LINE if selected else ThemeTokens.APPLE_LINE

	# Rotate entire apple so stem points in stem_rad direction.
	# APPLE_POLY has stem pointing UP (-Y), which equals stem_rad = -PI/2 → rotation = 0.
	var rot := stem_rad + PI * 0.5
	draw_set_transform(Vector2(cx, cy), rot, Vector2.ONE)

	# Body fill
	draw_polygon(APPLE_POLY, PackedColorArray([fill]))

	# Outline — close the polygon by appending first point
	var outline := PackedVector2Array(APPLE_POLY)
	outline.append(APPLE_POLY[0])
	draw_polyline(outline, line, 2.5, true)

	# Stem — from the dimple bottom up, slightly curved (two-segment approximation)
	draw_line(Vector2(0, -19), Vector2(2, -30), ThemeTokens.APPLE_STEM, 3.2, true)
	draw_line(Vector2(2, -30), Vector2(5, -38), ThemeTokens.APPLE_STEM, 2.8, true)

	# Highlight — small arc in the inner upper-left area of the apple
	draw_arc(Vector2(-8, -4), 10.0,
		deg_to_rad(210), deg_to_rad(320), 8,
		Color(1.0, 1.0, 1.0, 0.40), 2.5, true)

	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
