class_name GameScreen
extends Control
## 游戏牌桌界面：把 GameController 的信号接到视觉表现上。
## 只做展示与输入转发，不含 21 点规则逻辑（规则在 BlackjackRules / GameController）。

const CARD_SPACING := 55.0     # 原版手牌间距
const CARD_SIZE := Vector2(71, 96)
const DEALER_HAND_Y := 110.0   # 原版庄家手牌 Y
const PLAYER_HAND_Y := 320.0   # 原版玩家手牌 Y
const DESIGN_WIDTH := 760.0
const CARD_VIEW_SCENE := preload("res://scenes/components/CardView.tscn")

@onready var controller: GameController = $GameController
@onready var card_layer: Control = $CardLayer
@onready var round_label: Label = $RoundLabel
@onready var dealer_score_label: Label = $DealerScoreLabel
@onready var player_score_label: Label = $PlayerScoreLabel
@onready var dealer_drawing_label: Label = $DealerDrawingLabel
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton
@onready var hearts: HeartDisplay = $HeartDisplay
@onready var overlay: ResultOverlay = $ResultOverlay

var _dealer_views: Array[CardView] = []
var _player_views: Array[CardView] = []


func _ready() -> void:
	_connect_signals()
	hit_button.pressed.connect(func() -> void: controller.player_hit())
	stand_button.pressed.connect(func() -> void: controller.player_stand())
	overlay.restart_requested.connect(_on_restart_requested)
	# 开局
	controller.start_new_game()


func _connect_signals() -> void:
	controller.round_started.connect(_on_round_started)
	controller.card_dealt.connect(_on_card_dealt)
	controller.score_updated.connect(_refresh_scores)
	controller.lives_updated.connect(_on_lives_updated)
	controller.dealer_turn_started.connect(_on_dealer_turn_started)
	controller.dealer_drawing_changed.connect(_on_dealer_drawing_changed)
	controller.dealer_hole_revealed.connect(_on_dealer_hole_revealed)
	controller.round_finished.connect(_on_round_finished)
	controller.player_input_unlocked.connect(_on_input_unlocked)
	controller.game_finished.connect(_on_game_finished)


## ======================
## 输入（键盘快捷键与原版一致：H=Hit S=Stand R=重来 ESC=结束界面退出）
## ======================

func _unhandled_input(event: InputEvent) -> void:
	if controller.game_over:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_R:
					_on_restart_requested()
				KEY_ESCAPE:
					get_tree().quit()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				controller.player_hit()
			KEY_S:
				controller.player_stand()


func _on_restart_requested() -> void:
	overlay.reset()
	_clear_card_views()
	hearts.set_lives(GameController.MAX_LIVES, false)
	controller.start_new_game()


## ======================
## 信号响应
## ======================

func _on_round_started(round_num: int) -> void:
	overlay.reset()
	_clear_card_views()
	round_label.text = "%d/%d" % [round_num, GameController.MAX_ROUNDS]
	dealer_drawing_label.visible = false
	_set_action_buttons_enabled(false)


func _on_card_dealt(target: String, card: CardData, index: int) -> void:
	var view: CardView = CARD_VIEW_SCENE.instantiate()
	var face_up: bool = not (target == "dealer" and index == 0)
	view.setup(card, face_up)
	card_layer.add_child(view)
	if target == "dealer":
		_dealer_views.append(view)
		_relayout_hand(_dealer_views, DEALER_HAND_Y, view, true)
	else:
		_player_views.append(view)
		_relayout_hand(_player_views, PLAYER_HAND_Y, view, true)


## 计算手牌槽位并布置：新卡飞入，旧卡平滑重排（自动居中）。
func _relayout_hand(views: Array[CardView], y: float, new_view: CardView, flying: bool) -> void:
	var n := views.size()
	var total_w: float = (n - 1) * CARD_SPACING + CARD_SIZE.x
	var start_x: float = (DESIGN_WIDTH - total_w) / 2.0
	for i in n:
		var target := Vector2(start_x + i * CARD_SPACING, y)
		if views[i] == new_view and flying:
			new_view.fly_in(target)
		else:
			views[i].move_to(target)


func _clear_card_views() -> void:
	for v in _dealer_views + _player_views:
		v.queue_free()
	_dealer_views.clear()
	_player_views.clear()


func _refresh_scores() -> void:
	player_score_label.text = "Player: %d" % controller.player.get_score()
	dealer_score_label.text = _dealer_score_text()


## 庄家分数文本（忠实原版）：未翻暗牌时只显示明牌那张的原始点数。
func _dealer_score_text() -> String:
	var dealer := controller.dealer
	if dealer.hand.is_empty():
		return "Dealer: 0"
	if not controller.dealer_revealed:
		if dealer.hand.size() >= 2:
			return "Dealer: %d" % dealer.hand[1].value
		return "Dealer: ?"
	return "Dealer: %d" % dealer.get_score()


func _on_lives_updated(lives: int) -> void:
	hearts.set_lives(lives, true)


func _on_dealer_turn_started() -> void:
	_set_action_buttons_enabled(false)


func _on_dealer_drawing_changed(active: bool) -> void:
	dealer_drawing_label.visible = active


func _on_dealer_hole_revealed() -> void:
	if not _dealer_views.is_empty():
		_dealer_views[0].flip_to(true)
	_refresh_scores()


func _on_round_finished(result: String, color_kind: String) -> void:
	_set_action_buttons_enabled(false)
	overlay.show_result(result, color_kind)
	_refresh_scores()


func _on_input_unlocked() -> void:
	if not controller.game_over:
		_set_action_buttons_enabled(true)


func _on_game_finished(victory: bool) -> void:
	_set_action_buttons_enabled(false)
	overlay.show_game_over(victory)


func _set_action_buttons_enabled(enabled: bool) -> void:
	hit_button.disabled = not enabled
	stand_button.disabled = not enabled
