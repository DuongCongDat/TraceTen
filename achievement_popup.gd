extends CanvasLayer

const POPUP_DURATION = 2.5
const SLIDE_TIME     = 0.3

@onready var panel  = $Panel
@onready var label  = $Panel/Label

var _queue: Array = []
var _showing: bool = false


func _ready():
	panel.position.x = 1200.0  # off-screen right
	Global.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(id: String):
	var def = AchievementData.get_def(id)
	if def.is_empty():
		return
	_queue.append(def["name"])
	if not _showing:
		_show_next()


func _show_next():
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var name_text = _queue.pop_front()
	label.text = "Achievement!\n" + name_text

	AudioManager.play_sfx("achievement")
	# Slide in from right
	var target_x = get_viewport().get_visible_rect().size.x - panel.size.x - 16.0
	panel.position.x = get_viewport().get_visible_rect().size.x
	var tween = create_tween()
	tween.tween_property(panel, "position:x", target_x, SLIDE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(POPUP_DURATION)
	tween.tween_property(panel, "modulate:a", 0.0, SLIDE_TIME)
	tween.tween_callback(_on_popup_done)


func _on_popup_done():
	panel.modulate.a = 1.0
	panel.position.x = get_viewport().get_visible_rect().size.x
	_show_next()
