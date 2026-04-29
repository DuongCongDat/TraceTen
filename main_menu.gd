extends Control

func _ready():
	# Đảm bảo khi quay lại Menu, chuột/cảm ứng không bị khóa bởi tutorial cũ
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Hàm dùng chung để cài đặt mode và chuyển cảnh
func _on_mode_button_pressed(mode_name: String):
	# Lưu lựa chọn vào file Global (Autoload)
	Global.selected_mode = mode_name
	
	# Chuyển sang scene game chính
	get_tree().change_scene_to_file("res://main.tscn")

# Nối các Signal từ nút bấm vào đây
func _on_btn_classic_pressed():
	_on_mode_button_pressed("CLASSIC")

func _on_btn_gravity_pressed():
	_on_mode_button_pressed("GRAVITY")

func _on_btn_mutation_pressed():
	_on_mode_button_pressed("MUTATION")

func _on_btn_zen_pressed():
	_on_mode_button_pressed("ZEN")

func _on_btn_quit_pressed():
	get_tree().quit() # Thoát game (chỉ có tác dụng trên Android/PC)
