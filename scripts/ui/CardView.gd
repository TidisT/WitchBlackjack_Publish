class_name CardView
extends TextureRect
## 单张卡牌的显示：只负责贴图与翻转/入场动画，不含任何规则逻辑。

const CARD_SIZE := Vector2(71, 96)
## 牌堆位置（发牌动画起点，桌面右侧中部）
const DECK_POS := Vector2(695, 222)
const FLY_DURATION := 0.22
const FLIP_DURATION := 0.18

var card: CardData
var is_showing_back: bool = true

@onready var _flip_tween: Tween = null


func _ready() -> void:
	# 注意：必须先设 expand_mode 再设 size，否则 size 会被纹理原始尺寸(320×480)钳制
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0


## 初始化显示内容。face_up=false 时显示牌背。
func setup(p_card: CardData, face_up: bool) -> void:
	card = p_card
	is_showing_back = not face_up
	_apply_texture()


func _apply_texture() -> void:
	if is_showing_back or card == null:
		texture = AssetManager.get_card_back()
	else:
		var tex := AssetManager.get_card_texture(card.suit, card.rank)
		if tex != null:
			texture = tex
		else:
			push_error("CardView: 卡牌贴图缺失 %s%s" % [card.suit, card.rank])


## 从牌堆位置飞入场到 target_pos（带轻微淡入）。
func fly_in(target_pos: Vector2) -> void:
	position = DECK_POS
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", target_pos, FLY_DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, FLY_DURATION)


## 平滑移动到新的手牌槽位（手牌重新居中）。
func move_to(target_pos: Vector2) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", target_pos, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 翻牌动画：水平压缩→换贴图→展开。
func flip_to(face_up: bool) -> void:
	var want_back: bool = not face_up
	if want_back == is_showing_back:
		return
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 0.0, FLIP_DURATION / 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		is_showing_back = want_back
		_apply_texture())
	tw.tween_property(self, "scale:x", 1.0, FLIP_DURATION / 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
