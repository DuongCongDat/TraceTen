class_name AppleDraw
extends Control

var selected: bool = false
var stem_rad: float = -PI * 0.5

# Smooth apple polygon built from cubic bezier curves, stored after _ready().
var _poly: PackedVector2Array

func _ready() -> void:
	_poly = _build_apple_poly()


# 8 cubic bezier segments, 8 samples each = 64-point smooth polygon.
# Shape is centered at origin, stem/dimple at -Y (top).
func _build_apple_poly() -> PackedVector2Array:
	# Control points per segment [p0, p1, p2, p3] — clockwise from dimple.
	# C1 continuity at widest & bottom keeps the outline smooth.
	var segs: Array = [
		# ── Right half ──
		# 1. Dimple → right bump peak
		[[ 0,-19], [ 5,-23], [11,-27], [17,-28]],
		# 2. Right bump → widest
		[[17,-28], [23,-26], [31,-17], [33, -6]],
		# 3. Widest → lower right
		[[33, -6], [33,  5], [27, 17], [19, 28]],
		# 4. Lower right → bottom center
		[[19, 28], [13, 33], [ 6, 34], [ 0, 34]],
		# ── Left half (mirror) ──
		# 5. Bottom center → lower left
		[[ 0, 34], [-6, 34], [-13,33], [-19,28]],
		# 6. Lower left → widest left
		[[-19,28], [-27,17], [-33, 5], [-33,-6]],
		# 7. Widest left → left bump peak
		[[-33,-6], [-31,-17], [-23,-26], [-17,-28]],
		# 8. Left bump peak → dimple
		[[-17,-28], [-11,-27], [-5,-23], [0,-19]],
	]

	var pts := PackedVector2Array()
	for seg in segs:
		var p0 := Vector2(seg[0][0], seg[0][1])
		var p1 := Vector2(seg[1][0], seg[1][1])
		var p2 := Vector2(seg[2][0], seg[2][1])
		var p3 := Vector2(seg[3][0], seg[3][1])
		for i in 8:
			pts.append(_cbez(float(i) / 8.0, p0, p1, p2, p3))
	return pts


static func _cbez(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3.0*u*u*t*p1 + 3.0*u*t*t*p2 + t*t*t*p3


func _draw():
	if _poly.is_empty():
		return
	var cx := size.x * 0.5
	var cy := size.y * 0.5 + 2.0

	var fill := ThemeTokens.APPLE_SEL_FILL if selected else ThemeTokens.APPLE_FILL
	var line := ThemeTokens.APPLE_SEL_LINE if selected else ThemeTokens.APPLE_LINE

	# Rotate entire apple: stem_rad=-PI/2 (stem up) → rotation=0
	draw_set_transform(Vector2(cx, cy), stem_rad + PI * 0.5, Vector2.ONE)

	# Filled body
	draw_polygon(_poly, PackedColorArray([fill]))

	# Smooth outline — close by appending first point
	var outline := PackedVector2Array(_poly)
	outline.append(_poly[0])
	draw_polyline(outline, line, 2.5, true)

	# Stem — two-segment slight curve
	draw_line(Vector2(0, -19), Vector2(2, -30), ThemeTokens.APPLE_STEM, 3.2, true)
	draw_line(Vector2(2, -30), Vector2(5, -38), ThemeTokens.APPLE_STEM, 2.8, true)

	# Highlight arc (upper-left of body)
	draw_arc(Vector2(-8, -4), 10.0,
		deg_to_rad(210), deg_to_rad(320), 8,
		Color(1.0, 1.0, 1.0, 0.40), 2.5, true)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
