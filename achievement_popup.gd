extends CanvasLayer

const POPUP_DURATION = 2.5
const SLIDE_TIME     = 0.3

@onready var _panel = $Panel

const CAT_COLORS = {
	"Beginner":      Color("#7fc8a9"),
	"Score":         Color("#e0a85c"),
	"Combo":         Color("#f08a5d"),
	"Mode":          Color("#5a9fd4"),
	"Special Tiles": Color("#8a7fc8"),
	"Quirky":        Color("#c97fa8"),
}

const CAT_IDS = {
	"Beginner":      ["first_ten", "first_powerup", "all_modes", "first_combo", "first_special"],
	"Score":         ["score_100", "score_500", "score_1000"],
	"Combo":         ["combo_5", "combo_10", "combo_classic"],
	"Mode":          ["classic_survive", "gravity_lv4", "gravity_3lives", "zen_refill3", "challenge_l6", "challenge_l12", "mutation_alltype"],
	"Special Tiles": ["virus_cleared", "joker_used", "negative_win"],
	"Quirky":        ["big_selection", "no_hint", "cancel_remove", "virus_explode"],
}

var _queue:    Array = []
var _showing:  bool  = false
var _chip_sb:  StyleBoxFlat
var _title_lbl: Label
var _name_lbl:  Label
var _desc_lbl:  Label

const PANEL_H = 68.0

func _ready():
	var sw := get_viewport().get_visible_rect().size.x

	_panel.position = Vector2(14, -(PANEL_H + 20))
	_panel.size     = Vector2(sw - 28, PANEL_H)

	var sb := StyleBoxFlat.new()
	sb.bg_color      = ThemeTokens.CARD_BG
	ThemeTokens._set_radius(sb, 16)
	sb.shadow_color  = Color(0, 0, 0, 0.38)
	sb.shadow_size   = 14
	sb.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", sb)

	for c in _panel.get_children():
		c.free()

	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left",  11)
	mc.add_theme_constant_override("margin_right", 14)
	mc.add_theme_constant_override("margin_top",   11)
	mc.add_theme_constant_override("margin_bottom",11)
	_panel.add_child(mc)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	mc.add_child(hbox)

	# Icon chip
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(46, 46)
	_chip_sb = StyleBoxFlat.new()
	_chip_sb.bg_color = ThemeTokens.MINT
	ThemeTokens._set_radius(_chip_sb, 13)
	chip.add_theme_stylebox_override("panel", _chip_sb)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var chip_mc := MarginContainer.new()
	chip_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip.add_child(chip_mc)

	var chip_lbl := Label.new()
	chip_lbl.text = "★"
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	chip_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip_lbl.add_theme_font_size_override("font_size", 22)
	chip_lbl.add_theme_color_override("font_color", Color.WHITE)
	chip_mc.add_child(chip_lbl)
	hbox.add_child(chip)

	# Text VBox
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.text = "ACHIEVEMENT UNLOCKED"
	_title_lbl.add_theme_font_override("font", ThemeTokens.font_inter(700))
	_title_lbl.add_theme_font_size_override("font_size", 10)
	_title_lbl.add_theme_color_override("font_color", ThemeTokens.MINT)
	vbox.add_child(_title_lbl)

	_name_lbl = Label.new()
	_name_lbl.text = ""
	_name_lbl.add_theme_font_override("font", ThemeTokens.font_inter(800))
	_name_lbl.add_theme_font_size_override("font_size", 15)
	_name_lbl.add_theme_color_override("font_color", ThemeTokens.TEXT)
	vbox.add_child(_name_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.text = ""
	_desc_lbl.add_theme_font_override("font", ThemeTokens.font_inter(400))
	_desc_lbl.add_theme_font_size_override("font_size", 11)
	_desc_lbl.add_theme_color_override("font_color", ThemeTokens.SUB_TEXT)
	vbox.add_child(_desc_lbl)

	Global.achievement_unlocked.connect(_on_achievement_unlocked)


func _get_cat_color(id: String) -> Color:
	for cat in CAT_IDS:
		if id in CAT_IDS[cat]:
			return CAT_COLORS.get(cat, ThemeTokens.MINT)
	return ThemeTokens.MINT


func _on_achievement_unlocked(id: String):
	var def = AchievementData.get_def(id)
	if def.is_empty():
		return
	_queue.append(id)
	if not _showing:
		_show_next()


func _show_next():
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var id           = _queue.pop_front()
	var def          = AchievementData.get_def(id)
	var cat_color    := _get_cat_color(id)

	# Update chip colour
	_chip_sb.bg_color     = cat_color
	_chip_sb.shadow_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.5)
	_chip_sb.shadow_size  = 10
	_chip_sb.shadow_offset = Vector2(0, 4)

	# Update labels
	_title_lbl.add_theme_color_override("font_color", cat_color)
	_name_lbl.text = def.get("name", "")
	_desc_lbl.text = def.get("desc", "")

	AudioManager.play_sfx("achievement")

	# Animate slide from top
	_panel.position.y = -(PANEL_H + 20)
	_panel.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(_panel, "position:y", 14.0, SLIDE_TIME)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(POPUP_DURATION)
	tween.tween_property(_panel, "modulate:a", 0.0, SLIDE_TIME)
	tween.tween_callback(_on_popup_done)


func _on_popup_done():
	_panel.modulate.a  = 1.0
	_panel.position.y  = -(PANEL_H + 20)
	_show_next()
