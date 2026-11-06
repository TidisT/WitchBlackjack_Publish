class_name Participant
extends RefCounted
## 参与者基础数据（玩家/庄家共用）。计分委托给 BlackjackRules。
## 对应原版 objects/participant.py。

var name: String = ""
var hand: Array[CardData] = []


func _init(p_name: String = "") -> void:
	name = p_name


## 摸一张牌（card 允许为 null 时忽略，避免空引用）。
func receive_card(card: CardData) -> void:
	if card != null:
		hand.append(card)


## 清空手牌（用于新一轮）。
func clear_hand() -> void:
	hand.clear()


## 当前总分（含 A 的 11/1 自动调整）。
func get_score() -> int:
	return BlackjackRules.hand_score(hand)
