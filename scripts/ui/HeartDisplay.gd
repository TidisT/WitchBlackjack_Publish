class_name HeartDisplay
extends Control
## 生命值显示：5 颗 38×38 的爱心，x=20、y=320 起、纵向间隔 45（原版布局）。
## 只负责显示与简单反馈，不含生命规则逻辑。

const MAX_LIVES := 5
const HEART_SIZE := Vector2(38, 38)
const HEART_SPACING := 45.0

var _hearts: Array[TextureRect] = []
var _current_lives: int = MAX_LIVES


func _ready() -> void:
	custom_minimum_size = Vector2(HEART_SIZE.x, HEART_SPACING * (MAX_LIVES - 1) + HEART_SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var full: Texture2D = AssetManager.get_texture("res://assets/ui/Fullheart.png")
	var empty: Texture2D = AssetManager.get_texture("res://assets/ui/Emheart.png")
	for i in MAX_LIVES:
		var heart := TextureRect.new()
		# 先 expand_mode 再 size，避免被纹理原始尺寸钳制
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_SCALE
		heart.custom_minimum_size = HEART_SIZE
		heart.size = HEART_SIZE
		heart.position = Vector2(0, HEART_SPACING * i)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.set_meta("full", full)
		heart.set_meta("empty", empty)
		heart.texture = full
		add_child(heart)
		_hearts.append(heart)
	set_lives(MAX_LIVES, false)


## 设置当前生命数。lost=true 时对刚刚失去的那颗心做脉冲反馈。
func set_lives(lives: int, lost: bool = false) -> void:
	_current_lives = clampi(lives, 0, MAX_LIVES)
	for i in MAX_LIVES:
		var heart := _hearts[i]
		heart.texture = heart.get_meta("full") if i < _current_lives else heart.get_meta("empty")
	if lost and _current_lives < MAX_LIVES:
		var lost_heart := _hearts[_current_lives]
		var tw := create_tween()
		lost_heart.pivot_offset = HEART_SIZE / 2.0
		lost_heart.scale = Vector2(1.5, 1.5)
		tw.tween_property(lost_heart, "scale", Vector2.ONE, 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
