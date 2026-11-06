class_name Deck
extends RefCounted
## 牌组：创建 52 张、洗牌、抽牌、判断余量。不处理任何 UI。
## 对应原版 objects/deck.py。

var cards: Array[CardData] = []


func _init() -> void:
	create_deck()


## 生成一副标准 52 张牌（追加到当前牌堆）。
func create_deck() -> void:
	for suit in CardData.SUITS:
		for rank in CardData.RANKS:
			cards.append(CardData.new(suit, rank))


## 洗牌。
func shuffle() -> void:
	cards.shuffle()


## 抽一张牌；牌堆为空时返回 null（调用方必须判空，不允许崩溃）。
func deal() -> CardData:
	if cards.is_empty():
		push_warning("Deck.deal(): 牌发完了！")
		return null
	return cards.pop_back()


## 是否还有剩余牌。
func has_cards() -> bool:
	return not cards.is_empty()


## 剩余张数。
func remaining() -> int:
	return cards.size()
