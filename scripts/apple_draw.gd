class_name AppleDraw
extends Control

var selected: bool = false
# Stem angle in radians; -PI/2 = pointing up (DOWN fall), animated via Tween
var stem_rad: float = -PI * 0.5

const BODY_RADIUS := 27.0
const STEM_LEN    := 11.0
const STEM_WIDTH  := 3.2

func _draw():
	var cx := size.x * 0.5
	var cy := size.y * 0.5 + 2.0

	var fill := ThemeTokens.APPLE_SEL_FILL if selected else ThemeTokens.APPLE_FILL
	var line := ThemeTokens.APPLE_SEL_LINE if selected else ThemeTokens.APPLE_LINE

	# Body fill + outline
	draw_circle(Vector2(cx, cy), BODY_RADIUS, fill)
	draw_arc(Vector2(cx, cy), BODY_RADIUS, 0.0, TAU, 48, line, 2.5, true)

	# Stem: starts just outside the body edge, extends outward
	var dir_vec := Vector2(cos(stem_rad), sin(stem_rad))
	var stem_base := Vector2(cx, cy) + dir_vec * (BODY_RADIUS - 2.0)
	var stem_tip  := Vector2(cx, cy) + dir_vec * (BODY_RADIUS + STEM_LEN)
	draw_line(stem_base, stem_tip, ThemeTokens.APPLE_STEM, STEM_WIDTH, true)

	# Highlight — small arc on the side opposite the stem (inner glow feel)
	var hi_angle := stem_rad + PI  # opposite the stem
	var hi_center := Vector2(cx, cy) + Vector2(cos(hi_angle), sin(hi_angle)) * (BODY_RADIUS * 0.55)
	draw_arc(hi_center, BODY_RADIUS * 0.30,
		hi_angle + deg_to_rad(150), hi_angle + deg_to_rad(320),
		10, Color(1.0, 1.0, 1.0, 0.38), 2.5, true)
