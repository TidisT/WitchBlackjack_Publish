class_name GameController
extends Node
## 游戏核心流程控制：初始化对局、轮次、生命、发牌、玩家操作、
## 庄家自动抽牌、结算与胜负判定。通过信号与界面通信，不直接操作 UI 节点。
## 对应原版 states/game_state.py 的流程部分。

signal game_started
signal round_started(round_num: int)
signal card_dealt(target: String, card: CardData, index: int)
signal score_updated
signal lives_updated(lives: int)
signal dealer_turn_started
signal dealer_drawing_changed(active: bool)
signal round_finished(result: String, color_kind: String)  # color_kind: "good"/"bad"/"neutral"
signal dealer_hole_revealed
signal player_input_unlocked
signal game_finished(victory: bool)

const MAX_ROUNDS: int = 10
const MAX_LIVES: int = 5
const DEALER_DRAW_DELAY: float = 0.7   # 庄家每张补牌间隔（秒），原版 700ms
const RESULT_DURATION: float = 1.2     # 结算文字停留（秒），原版 1200ms
const DEAL_INTERVAL: float = 0.22      # 发牌动画间隔（秒），仅表现层

var round_num: int = 1
var lives: int = MAX_LIVES

var game_over: bool = false
var victory: bool = false

var dealer_revealed: bool = false          # 庄家暗牌是否已翻开
var dealer_turn_active: bool = false       # 庄家行动阶段
var round_result_showing: bool = false     # 结算展示期（禁止玩家操作）

var deck: Deck
var player: Participant = Participant.new("Player")
var dealer: Participant = Participant.new("Dealer")

## 计时器开关：真实运行时为 true；单元测试设为 false 后
## 可同步调用 _dealer_step() / _after_result() 驱动流程。
var timers_enabled: bool = true

## 对局代数令牌：每次新游戏/新轮次自增，用于作废挂起的旧计时器回调
## （防止 One More 重开后旧延迟逻辑污染新对局）。
var _generation: int = 0

# 结算颜色标记，供 UI 映射原版颜色
const COLOR_GOOD := "good"      # 绿 (0,255,120)
const COLOR_BAD := "bad"        # 红 (255,80,80)
const COLOR_NEUTRAL := "neutral"  # 黄 (220,220,120)


## ======================
## 对局生命周期
## ======================

## 开始一整场新游戏（One More 亦走此处）。
func start_new_game() -> void:
	_generation += 1
	lives = MAX_LIVES
	round_num = 1
	game_over = false
	victory = false
	lives_updated.emit(lives)
	game_started.emit()
	_begin_round(true)


## ======================
## 一轮流程
## ======================

## 开始新一轮：重置状态、新建牌组并洗牌、清空手牌、交替发 4 张。
## animated=true 时按 DEAL_INTERVAL 逐张发牌，发完做初始 Blackjack 判定。
func _begin_round(animated: bool) -> void:
	_generation += 1
	var gen: int = _generation
	round_result_showing = false
	dealer_turn_active = false
	dealer_revealed = false

	deck = Deck.new()
	deck.shuffle()

	player.clear_hand()
	dealer.clear_hand()
	score_updated.emit()

	round_started.emit(round_num)

	# 交替发牌：玩家→庄家→玩家→庄家（与原版一致）
	var order: Array = ["player", "dealer", "player", "dealer"]
	var hands: Dictionary = {"player": player, "dealer": dealer}
	var counts: Dictionary = {"player": 0, "dealer": 0}

	if animated and timers_enabled:
		for target in order:
			await _wait(DEAL_INTERVAL)
			if gen != _generation:  # 期间发生了重开/新一轮，作废本次发牌
				return
			var card: CardData = deck.deal()
			hands[target].receive_card(card)
			card_dealt.emit(target, card, counts[target])
			counts[target] += 1
			score_updated.emit()
	else:
		for target in order:
			var card: CardData = deck.deal()
			hands[target].receive_card(card)
			card_dealt.emit(target, card, counts[target])
			counts[target] += 1
		score_updated.emit()

	if gen != _generation:
		return
	_check_initial_blackjack()
	if not round_result_showing:
		player_input_unlocked.emit()


## 开局 Blackjack 判定（只针对两张初始手牌）。
func _check_initial_blackjack() -> void:
	var p_blackjack: bool = BlackjackRules.is_blackjack(player.hand)
	var d_blackjack: bool = BlackjackRules.is_blackjack(dealer.hand)

	if p_blackjack and d_blackjack:
		_reveal_dealer()
		_end_round("PUSH", COLOR_NEUTRAL)
	elif p_blackjack:
		_reveal_dealer()
		_end_round("BLACKJACK", COLOR_GOOD)
	elif d_blackjack:
		_reveal_dealer()
		_lose_life()
		_end_round("BLACKJACK", COLOR_BAD)


## 玩家要牌。爆牌立即结算：庄家翻牌、生命-1、显示 BUST（红）。
func player_hit() -> void:
	if _player_input_locked():
		return
	var card: CardData = deck.deal()
	player.receive_card(card)
	card_dealt.emit("player", card, player.hand.size() - 1)
	score_updated.emit()
	if BlackjackRules.is_bust(player.hand):
		_reveal_dealer()
		_lose_life()
		_end_round("BUST", COLOR_BAD)


## 玩家停牌：翻开暗牌，进入庄家行动阶段。
func player_stand() -> void:
	if _player_input_locked():
		return
	_reveal_dealer()
	dealer_turn_started.emit()
	if BlackjackRules.dealer_should_hit(dealer.get_score()):
		dealer_turn_active = true
		dealer_drawing_changed.emit(true)
		if timers_enabled:
			_schedule_dealer_step()
		# timers_enabled=false 时由测试方手动循环调用 _dealer_step()
	else:
		_finish_dealer_turn()


## 庄家单步抽牌：<17 抽一张并继续，≥17 结算。
func _dealer_step() -> void:
	if not dealer_turn_active:
		return
	if BlackjackRules.dealer_should_hit(dealer.get_score()):
		dealer.receive_card(deck.deal())
		card_dealt.emit("dealer", dealer.hand.back(), dealer.hand.size() - 1)
		score_updated.emit()
		if timers_enabled:
			_schedule_dealer_step()
		# 手动模式下测试方继续调用本函数
	else:
		dealer_turn_active = false
		dealer_drawing_changed.emit(false)
		_finish_dealer_turn()


## 庄家行动结束，做最终比较结算。
func _finish_dealer_turn() -> void:
	var p_score: int = player.get_score()
	var d_score: int = dealer.get_score()

	if d_score > 21:
		_end_round("BUST", COLOR_GOOD)      # 庄家爆牌：玩家胜
	elif d_score > p_score:
		_lose_life()
		_end_round("LOSE", COLOR_BAD)
	elif d_score == p_score:
		_end_round("PUSH", COLOR_NEUTRAL)
	else:
		_end_round("WIN", COLOR_GOOD)


## ======================
## 结算与推进
## ======================

## 展示本轮结果；RESULT_DURATION 秒后由 _after_result() 推进。
func _end_round(result: String, color_kind: String) -> void:
	round_result_showing = true
	dealer_turn_active = false
	dealer_drawing_changed.emit(false)
	round_finished.emit(result, color_kind)
	if timers_enabled:
		var gen: int = _generation
		_wait(RESULT_DURATION).timeout.connect(func() -> void:
			if gen == _generation:
				_after_result())


## 结算展示结束：推进下一轮或宣布最终胜负。
func _after_result() -> void:
	round_result_showing = false
	if game_over:
		# 生命耗尽（本轮中途判负）→ 显示最终结算
		game_finished.emit(victory)
		return
	if round_num >= MAX_ROUNDS:
		# 十轮生存：完成第 10 轮且仍存活即胜利
		game_over = true
		victory = true
		game_finished.emit(true)
	else:
		round_num += 1
		_begin_round(true)


## ======================
## 内部工具
## ======================

func _lose_life() -> void:
	lives -= 1
	lives_updated.emit(lives)
	if lives <= 0:
		game_over = true
		victory = false


## 翻开庄家暗牌（带信号通知 UI 做翻牌动画）。
func _reveal_dealer() -> void:
	if not dealer_revealed:
		dealer_revealed = true
		dealer_hole_revealed.emit()


## 结算展示期间与庄家行动期间禁止玩家操作（原版行为）。
func _player_input_locked() -> bool:
	return game_over or round_result_showing or dealer_turn_active


func _wait(seconds: float) -> SceneTreeTimer:
	return get_tree().create_timer(seconds)


func _schedule_dealer_step() -> void:
	var gen: int = _generation
	_wait(DEALER_DRAW_DELAY).timeout.connect(func() -> void:
		if gen == _generation:
			_dealer_step())
