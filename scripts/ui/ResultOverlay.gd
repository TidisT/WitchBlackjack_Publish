class_name ResultOverlay
extends Control
## 结果反馈层：本轮结果文字（WIN/LOSE/PUSH/BUST/BLACKJACK）、
## 最终游戏结束界面（YOU WIN / YOU LOSE + One More / Exit）。

signal restart_requested

const COLOR_GOOD := Color(0, 1, 0.47)      # 原版 (0,255,120)
const COLOR_BAD := Color(1, 0.31, 0.31)    # 原版 (255,80,80)
const COLOR_NEUTRAL := Color(0.86, 0.86, 0.47)  # 原版 (220,220,120)

@onready var result_label: Label = $ResultLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var one_more_button: Button = $OneMoreButton
@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_label.visible = false
	game_over_label.visible = false
	one_more_button.visible = false
	exit_button.visible = false
	one_more_button.pressed.connect(func() -> void: restart_requested.emit())
	exit_button.pressed.connect(func() -> void: get_tree().quit())


## 显示本轮结算文字（淡入 + 轻微缩放），1.2 秒后由 GameScreen 控制隐藏。
func show_result(text: String, color_kind: String) -> void:
	result_label.text = text
	result_label.visible = true
	match color_kind:
		"good":
			result_label.add_theme_color_override("font_color", COLOR_GOOD)
		"bad":
			result_label.add_theme_color_override("font_color", COLOR_BAD)
		_:
			result_label.add_theme_color_override("font_color", COLOR_NEUTRAL)
	result_label.pivot_offset = result_label.size / 2.0
	result_label.modulate.a = 0.0
	result_label.scale = Vector2(1.25, 1.25)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(result_label, "modulate:a", 1.0, 0.2)
	tw.tween_property(result_label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_result() -> void:
	result_label.visible = false


## 显示最终游戏结束界面（原版：YOU WIN/YOU LOSE 居中 380,220 + 两个按钮）。
func show_game_over(victory: bool) -> void:
	hide_result()
	game_over_label.visible = true
	game_over_label.text = "YOU WIN" if victory else "YOU LOSE"
	game_over_label.add_theme_color_override(
		"font_color", COLOR_GOOD if victory else COLOR_BAD)
	game_over_label.pivot_offset = game_over_label.size / 2.0
	game_over_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(game_over_label, "modulate:a", 1.0, 0.35)
	one_more_button.visible = true
	exit_button.visible = true
	one_more_button.disabled = false
	exit_button.disabled = false


## 回到进行中状态：隐藏全部结束元素。
func reset() -> void:
	hide_result()
	game_over_label.visible = false
	one_more_button.visible = false
	exit_button.visible = false
