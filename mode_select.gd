extends Control

var _pending_mode = ""

@onready var save_sub_menu = $SaveSubMenu
@onready var save_title    = $SaveSubMenu/OuterMargin/InnerBox/Title
@onready var save_info     = $SaveSubMenu/OuterMargin/InnerBox/LblInfo

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	save_sub_menu.hide()

func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _start_mode(mode_name: String):
	Global.selected_mode = mode_name
	if Global.has_save(mode_name):
		_show_save_menu(mode_name)
	else:
		_go_to_game(false)

func _show_save_menu(mode_name: String):
	_pending_mode = mode_name
	save_title.text = "Resume " + mode_name.capitalize() + "?"
	var preview = Global.get_save_preview(mode_name)
	var t = int(preview.get("time", 0))
	save_info.text = "Score: %d  |  Time: %02d:%02d" % [preview.get("score", 0), t / 60, t % 60]
	save_sub_menu.show()

func _go_to_game(load: bool):
	Global.load_save = load
	get_tree().change_scene_to_file("res://main.tscn")

func _on_btn_continue_pressed():
	save_sub_menu.hide()
	_go_to_game(true)

func _on_btn_new_game_pressed():
	save_sub_menu.hide()
	Global.delete_save(_pending_mode)
	_go_to_game(false)

func _on_btn_cancel_pressed():
	save_sub_menu.hide()
	_pending_mode = ""

func _on_btn_classic_pressed():
	_start_mode("CLASSIC")

func _on_btn_zen_pressed():
	_start_mode("ZEN")

func _on_btn_gravity_pressed():
	_start_mode("GRAVITY")

func _on_btn_mutation_pressed():
	_start_mode("MUTATION")
