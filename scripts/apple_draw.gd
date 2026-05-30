class_name AppleDraw
extends Control

var selected: bool = false
# Stem angle in radians; -PI/2 = stem pointing up (DOWN fall direction)
var stem_rad: float = -PI * 0.5

# Apple silhouette — 22 points, centered at origin, stem/dimple pointing in -Y direction.
# Key feature: dimple at top center (y≈-20) is LOWER than the two bump peaks (y≈-28),
# giving the characteristic apple double-lobe top.
const APPLE_POLY := PackedVector2Array([
	Vector2(-4,  -21),  # left rim of dimple
	Vector2( 0,  -19),  # dimple bottom (deepest dip)
	Vector2( 4,  -21),  # right rim of dimple
	Vector2( 9,  -27),  # rising toward right bump
	Vector2(15,  -29),  # right bump peak
	Vector2(21,  -24),  # right bump outer shoulder
	Vector2(25,  -14),  # upper right body
	Vector2(27,   -3),  # right upper
	Vector2(27,    9),  # right widest
	Vector2(24,   21),  # right lower
	Vector2(17,   29),  # bottom-right curve
	Vector2( 8,   33),  # bottom-right corner
	Vector2( 0,   34),  # bottom center
	Vector2(-8,   33),  # bottom-left corner
	Vector2(-17,  29),  # bottom-left curve
	Vector2(-24,  21),  # left lower
	Vector2(-27,   9),  # left widest
	Vector2(-27,  -3),  # left upper
	Vector2(-25, -14),  # upper left body
	Vector2(-21, -24),  # left bump outer shoulder
	Vector2(-15, -29),  # left bump peak
	Vector2(-9,  -27),  # descending toward dimple
])

func _draw():
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
