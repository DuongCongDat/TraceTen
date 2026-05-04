extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_btn_play_pressed():
	get_tree().change_scene_to_file("res://mode_select.tscn")

func _on_btn_highscore_pressed():
	get_tree().change_scene_to_file("res://highscore.tscn")

func _on_btn_help_pressed():
	get_tree().change_scene_to_file("res://tutorial.tscn")

func _on_btn_quit_pressed():
	get_tree().quit()
