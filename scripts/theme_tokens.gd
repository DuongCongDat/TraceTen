class_name ThemeTokens

# =============================================================================
# Colors — Mint Cream palette
# =============================================================================
const APP_BG       = Color(0.961, 0.941, 0.902)
const PHONE_BG     = Color(0.922, 0.890, 0.824)
const BOARD_BG     = Color(0.937, 0.906, 0.835)
const BOARD_INSET  = Color(0.890, 0.847, 0.753)
const TEXT         = Color(0.184, 0.227, 0.212)
const SUB_TEXT     = Color(0.541, 0.584, 0.565)
const TILE_WHITE   = Color(1.0,   1.0,   1.0  )
const MINT         = Color(0.498, 0.784, 0.663)
const MINT_DARK    = Color(0.306, 0.647, 0.518)
const MINT_SOFT    = Color(0.804, 0.914, 0.855)
const CHIP_BG      = Color(1.0,   1.0,   1.0  )

const JOKER_A      = Color(1.000, 0.902, 0.659)
const JOKER_B      = Color(1.000, 0.780, 0.522)
const JOKER_STROKE = Color(0.851, 0.600, 0.251)
const JOKER_INK    = Color(0.353, 0.216, 0.071)

const VIRUS_BG     = Color(0.780, 0.855, 0.698)
const VIRUS_DARK   = Color(0.478, 0.616, 0.365)
const VIRUS_GLOW   = Color(0.659, 0.769, 0.549)
const VIRUS_TEXT   = Color(0.239, 0.310, 0.161)

const MYSTERY_BG       = Color(0.239, 0.290, 0.267)
const MYSTERY_TEXT     = Color(0.937, 0.906, 0.835)
const MYSTERY_REV_BG   = Color(0.420, 0.463, 0.439)
const MYSTERY_REV_TEXT = Color(0.941, 0.933, 0.894)

const NEG_BG       = Color(0.961, 0.769, 0.769)
const NEG_DARK     = Color(0.769, 0.416, 0.416)

# =============================================================================
# Spacing & radii (all ×2 from 360dp reference — project viewport = 720px)
# =============================================================================
const TILE_RADIUS    = 12
const BOARD_RADIUS   = 44
const BOARD_PADDING  = 20
const CHIP_RADIUS    = 28
const POWERUP_RADIUS = 44
const TILE_GAP       = 8
const BADGE_RADIUS   = 999

# =============================================================================
# Helpers: corner radius — safe for all Godot 4.x versions
# =============================================================================
static func _set_radius(sb: StyleBoxFlat, r: int) -> void:
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left  = r

# =============================================================================
# Font helpers
# =============================================================================
static func font_inter(weight: int = 400) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load("res://assets/fonts/Inter-Variable.ttf")
	fv.variation_opentype = {&"wght": float(weight)}
	return fv

static func font_mono(weight: int = 700) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load("res://assets/fonts/JetBrainsMono-Variable.ttf")
	fv.variation_opentype = {&"wght": float(weight)}
	return fv

# =============================================================================
# StyleBox helpers
# =============================================================================
static func sb_tile_idle() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = TILE_WHITE
	_set_radius(sb, TILE_RADIUS)
	sb.border_width_bottom = 2
	sb.border_color = Color(0.314, 0.275, 0.157, 0.06)
	sb.shadow_color = Color(0.314, 0.275, 0.157, 0.06)
	sb.shadow_size  = 1
	sb.shadow_offset = Vector2(0, 1)
	return sb

static func sb_tile_selected() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MINT
	_set_radius(sb, TILE_RADIUS)
	sb.border_width_bottom = 2
	sb.border_color = Color(0, 0, 0, 0.06)
	sb.shadow_color = Color(0.306, 0.647, 0.518, 0.5)
	sb.shadow_size  = 12
	sb.shadow_offset = Vector2(0, 4)
	return sb

static func sb_board() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BOARD_BG
	_set_radius(sb, BOARD_RADIUS)
	sb.border_width_bottom = 2
	sb.border_width_top    = 2
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_color = BOARD_INSET
	return sb

static func sb_mode_chip() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MINT_SOFT
	_set_radius(sb, BADGE_RADIUS)
	sb.content_margin_left   = 20.0
	sb.content_margin_right  = 20.0
	sb.content_margin_top    = 8.0
	sb.content_margin_bottom = 8.0
	return sb

static func sb_powerup_button() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CHIP_BG
	_set_radius(sb, POWERUP_RADIUS)
	sb.border_width_bottom = 2
	sb.border_color = Color(0, 0, 0, 0.04)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size  = 8
	sb.shadow_offset = Vector2(0, 2)
	return sb

static func sb_powerup_badge() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MINT
	_set_radius(sb, BADGE_RADIUS)
	sb.content_margin_left   = 14.0
	sb.content_margin_right  = 14.0
	sb.content_margin_top    = 4.0
	sb.content_margin_bottom = 4.0
	return sb

static func sb_sum_bubble(valid: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MINT_DARK if valid else Color(0.239, 0.290, 0.267)
	_set_radius(sb, BADGE_RADIUS)
	sb.content_margin_left   = 28.0
	sb.content_margin_right  = 28.0
	sb.content_margin_top    = 8.0
	sb.content_margin_bottom = 8.0
	return sb

# Returns combo color dict for a given combo_count.
static func combo_color(count: int) -> Dictionary:
	if count >= 5:
		return {
			"bg":     Color(0.886, 0.361, 0.361),
			"stroke": Color(0.659, 0.188, 0.180),
			"text":   Color.WHITE
		}
	elif count >= 3:
		return {
			"bg":     Color(0.941, 0.541, 0.365),
			"stroke": Color(0.749, 0.353, 0.188),
			"text":   Color.WHITE
		}
	elif count >= 2:
		return {
			"bg":     Color(0.957, 0.788, 0.365),
			"stroke": Color(0.718, 0.561, 0.165),
			"text":   Color(0.239, 0.149, 0.086)
		}
	else:
		return {
			"bg":     Color(0.498, 0.784, 0.663),
			"stroke": Color(0.306, 0.647, 0.518),
			"text":   Color.WHITE
		}
