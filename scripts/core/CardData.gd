class_name CardData
extends RefCounted
## 纯数据卡牌：不负责任何界面绘制。
## 对应原版 objects/card.py 的数据部分。

## 花色常量：C=梅花 D=方块 H=红桃 S=黑桃
const SUITS: Array[String] = ["C", "D", "H", "S"]
## 点数顺序（对应图片命名 C2..CA 等）
const RANKS: Array[String] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

var suit: String = ""
var rank: String = ""
## 原始点数：J/Q/K=10，A=11，其余为面值（A 的 11/1 调整由 BlackjackRules 统一处理）
var value: int = 0
## 卡牌正面纹理的 res:// 路径
var texture_path: String = ""


func _init(p_suit: String = "", p_rank: String = "") -> void:
	if p_suit != "" and p_rank != "":
		setup(p_suit, p_rank)


func setup(p_suit: String, p_rank: String) -> void:
	suit = p_suit
	rank = p_rank
	value = BlackjackRules.card_base_value(rank)
	texture_path = "res://assets/cards/%s%s.png" % [suit, rank]


func _to_string() -> String:
	return "[%s %s]" % [suit, rank]
