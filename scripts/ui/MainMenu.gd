extends Control
## 主菜单：Start / Rules / Exit 三个原版图片按钮（中心 380,330 / 380,400 / 470）。

@onready var start_button: TextureButton = $StartButton
@onready var rules_button: TextureButton = $RulesButton
@onready var exit_button: TextureButton = $ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	# 悬停视觉反馈（保持原按钮图片，只调亮度）
	for btn: TextureButton in [start_button, rules_button, exit_button]:
		btn.mouse_entered.connect(func() -> void: btn.self_modulate = Color(1.25, 1.25, 1.25))
		btn.mouse_exited.connect(func() -> void: btn.self_modulate = Color.WHITE)
		btn.button_down.connect(func() -> void: btn.self_modulate = Color(0.8, 0.8, 0.8))
		btn.button_up.connect(func() -> void: btn.self_modulate = Color(1.25, 1.25, 1.25))


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


func _on_rules_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rules/Rules.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
