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
		# Dimple (top center — stem attaches here)
		Vector2(-4,  -21),
		Vector2( 0,  -19),
		Vector2( 4,  -21),
		# Right bump
		Vector2(10,  -26),
		Vector2(17,  -28),  # right bump peak — wider bump
		Vector2(23,  -22),  # bump outer shoulder — wider
		# Right body — widest zone shifted UP to ~1/3 from top
		Vector2(30,  -13),  # upper-right shoulder
		Vector2(33,   -6),  # widest point (shifted up)
		Vector2(32,    4),  # still wide, tapering begins
		Vector2(27,   17),  # lower-right narrows faster
		Vector2(19,   28),  # bottom-right curve
		Vector2( 9,   33),
		Vector2( 0,   34),  # bottom center
		Vector2(-9,   33),
		Vector2(-19,  28),  # bottom-left curve
		Vector2(-27,  17),
		Vector2(-32,   4),  # still wide
		Vector2(-33,  -6),  # widest point (shifted up)
		Vector2(-30, -13),
		Vector2(-23, -22),
		Vector2(-17, -28),  # left bump peak
		Vector2(-10, -26),
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
	draw_polygon(_poly, PackedColorArray([fill]))

	# Outline — close the polygon by appending first point
	var outline := PackedVector2Array(_poly)
	outline.append(_poly[0])
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
