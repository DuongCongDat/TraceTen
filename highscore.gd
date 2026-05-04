extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
