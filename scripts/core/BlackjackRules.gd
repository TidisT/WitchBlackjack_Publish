class_name BlackjackRules
extends Object
## 21 点规则集中管理：全部为静态纯函数，可独立测试，不依赖任何场景节点。
## 对应原版 participant.get_score() 与 game_state.py 中散落的规则判断。

const BLACKJACK_SCORE: int = 21
const DEALER_STAND_SCORE: int = 17


## 单张牌的基础点数：J/Q/K=10，A=11，其余为面值。
static func card_base_value(rank: String) -> int:
	match rank:
		"J", "Q", "K":
			return 10
		"A":
			return 11
		_:
			return int(rank)


## 计算手牌总分：A 先按 11 计，超出 21 时逐张降为 1。
## 例：A+9=20，A+K=21，A+6=17，A+9+5=15，A+A+9+2=13。
static func hand_score(hand: Array) -> int:
	var score: int = 0
	var aces: int = 0
	for card in hand:
		if card.rank in ["J", "Q", "K"]:
			score += 10
		elif card.rank == "A":
			score += 11
			aces += 1
		else:
			score += int(card.rank)
	while score > BLACKJACK_SCORE and aces > 0:
		score -= 10
		aces -= 1
	return score


## 是否爆牌。
static func is_bust(hand: Array) -> bool:
	return hand_score(hand) > BLACKJACK_SCORE


## 是否初始 Blackjack：恰好两张牌且总分为 21。
static func is_blackjack(hand: Array) -> bool:
	return hand.size() == 2 and hand_score(hand) == BLACKJACK_SCORE


## 庄家是否需要继续抽牌（<17 必须抽）。
static func dealer_should_hit(score: int) -> bool:
	return score < DEALER_STAND_SCORE


## 最终点数比较结果。
## 返回 "WIN"（玩家大）/"LOSE"（庄家大）/"PUSH"（平局）。
static func compare(player_score: int, dealer_score: int) -> String:
	if dealer_score > player_score:
		return "LOSE"
	elif dealer_score == player_score:
		return "PUSH"
	else:
		return "WIN"
