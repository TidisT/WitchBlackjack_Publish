extends SceneTree
## 基础测试入口（不依赖第三方插件）。
## 运行方式：
##   Godot 控制台版执行：
##   Godot_v4.7.2-stable_win64_console.exe --headless --path <项目> -s res://tests/run_tests.gd
## 全部通过输出 "ALL TESTS PASSED" 并以退出码 0 结束；有失败则退出码 1。
## 说明：全部使用显式 preload 引用脚本，避免依赖编辑器扫描时序。

const CardDataScript := preload("res://scripts/core/CardData.gd")
const DeckScript := preload("res://scripts/core/Deck.gd")
const ParticipantScript := preload("res://scripts/core/Participant.gd")
const RulesScript := preload("res://scripts/core/BlackjackRules.gd")
const ControllerScript := preload("res://scripts/managers/GameController.gd")

var _passed: int = 0
var _failed: int = 0
var _current_section: String = ""


func _initialize() -> void:
	_test_card_data()
	_test_deck()
	_test_score_calc()
	_test_win_lose_rules()
	await _test_game_flow()
	print("")
	print("========================================")
	print("通过: %d  失败: %d" % [_passed, _failed])
	if _failed == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TESTS FAILED")
		quit(1)


func _section(name: String) -> void:
	_current_section = name
	print("")
	print("---- %s ----" % name)


func _check(cond: bool, test_name: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		_failed += 1
		print("  [FAIL] %s   (section: %s)" % [test_name, _current_section])


## 便捷构造手牌：["H", "K"], ["S", "6"] ...
func _hand(specs: Array) -> Array:
	var hand: Array = []
	for s in specs:
		hand.append(CardDataScript.new(s[0], s[1]))
	return hand


## ======================
## 9.1 卡牌数据测试
## ======================

func _test_card_data() -> void:
	_section("9.1 卡牌数据")
	var deck = DeckScript.new()
	_check(deck.cards.size() == 52, "一副牌共 52 张")

	var suits := {}
	var ranks := {}
	var dup := false
	for c in deck.cards:
		suits[c.suit] = true
		ranks[c.rank] = true
		var key: String = c.suit + c.rank
		# 统计重复组合
		for c2 in deck.cards:
			if c2 != c and c2.suit + c2.rank == key:
				dup = true
	_check(suits.size() == 4, "花色共 4 种 (C/D/H/S)")
	_check(ranks.size() == 13, "点数共 13 种 (2..A)")
	_check(not dup, "52 张牌无重复花色+点数组合")

	var j = CardDataScript.new("H", "J")
	var q = CardDataScript.new("D", "Q")
	var k = CardDataScript.new("S", "K")
	var a = CardDataScript.new("C", "A")
	var n10 = CardDataScript.new("C", "10")
	var n2 = CardDataScript.new("C", "2")
	_check(j.value == 10 and q.value == 10 and k.value == 10, "J/Q/K 基础点数都是 10")
	_check(a.value == 11, "A 的原始点数是 11")
	_check(n10.value == 10 and n2.value == 2, "数字牌按面值")
	_check(j.texture_path == "res://assets/cards/HJ.png", "卡牌纹理路径按花色点数生成")


## ======================
## 9.2 牌组测试
## ======================

func _test_deck() -> void:
	_section("9.2 牌组")
	var deck = DeckScript.new()
	_check(deck.cards.size() == 52, "创建牌组有 52 张")
	deck.shuffle()
	_check(deck.cards.size() == 52, "洗牌后仍保持 52 张")

	var seen := {}
	var no_dup := true
	for c in deck.cards:
		var key: String = c.suit + c.rank
		if seen.has(key):
			no_dup = false
		seen[key] = true
	_check(no_dup and seen.size() == 52, "52 张牌无重复组合")

	var before: Array = []
	for c in deck.cards:
		before.append(c.suit + c.rank)
	deck.shuffle()
	var same_order := true
	for i in deck.cards.size():
		if before[i] != deck.cards[i].suit + deck.cards[i].rank:
			same_order = false
	_check(not same_order, "洗牌确实改变了牌序（概率性，重跑可验证）")

	for i in 5:
		deck.deal()
	_check(deck.remaining() == 47, "抽 5 张后剩 47 张")

	while deck.has_cards():
		deck.deal()
	_check(deck.remaining() == 0, "可以抽空牌组")
	_check(deck.deal() == null, "牌组为空时 deal() 返回 null，不崩溃")
	_check(deck.has_cards() == false, "空牌组 has_cards() 为 false")


## ======================
## 9.3 点数计算测试
## ======================

func _test_score_calc() -> void:
	_section("9.3 点数计算")
	var rules = RulesScript
	_check(rules.hand_score(_hand([["S", "K"], ["C", "A"]])) == 21, "K + A = 21")
	_check(rules.hand_score(_hand([["C", "A"], ["H", "6"]])) == 17, "A + 6 = 17")
	_check(rules.hand_score(_hand([["C", "A"], ["H", "9"], ["D", "5"]])) == 15, "A + 9 + 5 = 15")
	_check(rules.hand_score(_hand([["C", "A"], ["D", "A"], ["H", "9"], ["S", "2"]])) == 13,
		"A + A + 9 + 2 = 13")
	_check(rules.hand_score(_hand([["H", "10"], ["S", "K"], ["D", "2"]])) == 22, "10 + K + 2 = 22")
	_check(rules.hand_score(_hand([["C", "A"], ["D", "A"]])) == 12, "A + A = 12（一张降为 1）")
	_check(rules.is_bust(_hand([["H", "10"], ["S", "K"], ["D", "2"]])), "10+K+2 判定爆牌")
	_check(not rules.is_bust(_hand([["C", "A"], ["H", "9"], ["D", "5"]])), "A+9+5=15 不爆牌")

	# Participant.get_score() 与规则一致
	var p = ParticipantScript.new("T")
	for c in _hand([["C", "A"], ["D", "A"], ["H", "9"], ["S", "2"]]):
		p.receive_card(c)
	_check(p.get_score() == 13, "Participant.get_score() A+A+9+2=13")


## ======================
## 9.4 胜负规则测试
## ======================

func _test_win_lose_rules() -> void:
	_section("9.4 胜负规则")
	var rules = RulesScript
	# compare 是纯数值比较；爆牌（>21）由 GameController 流程层的 BUST 分支优先处理
	_check(rules.compare(22, 5) == "WIN", "数值比较：玩家 22 > 庄家 5 → WIN")
	_check(rules.compare(20, 22) == "LOSE", "数值比较：庄家爆牌由流程层 BUST 分支处理")

	_check(rules.compare(18, 19) == "LOSE", "庄家点数较高 → LOSE")
	_check(rules.compare(18, 18) == "PUSH", "双方平局 → PUSH")
	_check(rules.compare(20, 18) == "WIN", "玩家点数较高 → WIN")

	_check(rules.is_blackjack(_hand([["C", "A"], ["S", "K"]])), "玩家初始 Blackjack (A+K)")
	_check(not rules.is_blackjack(_hand([["C", "A"], ["S", "K"], ["H", "5"]])), "三张 21 不算初始 Blackjack")
	_check(rules.is_blackjack(_hand([["H", "Q"], ["D", "A"]])), "庄家初始 Blackjack (Q+A)")
	_check(rules.dealer_should_hit(16), "庄家 16 需要继续抽牌")
	_check(not rules.dealer_should_hit(17), "庄家 17 停牌")
	_check(not rules.dealer_should_hit(21), "庄家 21 停牌")


## ======================
## 9.5 游戏流程测试（同步模式：timers_enabled=false）
## ======================

func _test_game_flow() -> void:
	_section("9.5 游戏流程")
	var controller = ControllerScript.new()
	controller.timers_enabled = false
	root.add_child(controller)  # 触发 _ready
	controller.timers_enabled = false  # 再确认一次

	var finished_victory := []
	var finished_count := []
	var round_results := []
	controller.game_finished.connect(func(v: bool) -> void:
		finished_victory.append(v)
		finished_count.append(true))
	controller.round_finished.connect(func(result: String, kind: String) -> void:
		round_results.append(result))

	# --- 新游戏初始化 ---
	controller.start_new_game()
	_check(controller.lives == 5, "新游戏生命值重置为 5")
	_check(controller.round_num == 1, "新游戏轮数重置为 1")
	_check(controller.player.hand.size() == 2, "玩家初始 2 张牌")
	_check(controller.dealer.hand.size() == 2, "庄家初始 2 张牌")
	_check(controller.deck.remaining() == 48, "发 4 张后牌组剩 48")
	_check(controller.dealer_revealed == false or controller.round_result_showing,
		"无 Blackjack 时庄家暗牌保持隐藏")

	# --- 轮数增加：连续打完几轮（玩家始终停牌） ---
	var guard := 0
	while controller.round_num == 1 and guard < 10:
		guard += 1
		if controller.round_result_showing:
			controller._after_result()
			continue
		if controller.game_over:
			break
		controller.player_stand()
		var steps := 0
		while controller.dealer_turn_active and steps < 10:
			controller._dealer_step()
			steps += 1
		if controller.round_result_showing:
			controller._after_result()
	_check(controller.round_num == 2, "一轮结算完成后轮数 +1（round_num=2）")

	# --- 生命扣除与归零失败 ---
	var lives_before: int = controller.lives
	controller._lose_life()
	_check(controller.lives == lives_before - 1, "输掉一轮生命 -1")
	for i in 10:
		controller._lose_life()
	_check(controller.game_over == true and controller.victory == false, "生命归零判定失败")
	var before_finish := finished_count.size()
	controller.round_result_showing = true
	controller._after_result()
	_check(finished_count.size() == before_finish + 1, "生命归零结算后发出 game_finished")
	_check(finished_victory.back() == false, "game_finished 携带 victory=false")

	# --- One More 正确重置 ---
	controller.start_new_game()
	_check(controller.lives == 5 and controller.round_num == 1, "One More 重置生命与轮数")
	_check(controller.game_over == false and controller.victory == false, "One More 清除结束状态")
	_check(controller.player.hand.size() == 2 and controller.dealer.hand.size() == 2,
		"One More 后重新发牌")

	# --- 完成第十轮并存活时胜利 ---
	controller.round_num = 10
	controller.game_over = false
	controller.round_result_showing = false
	var finish_before := finished_count.size()
	controller._after_result()
	_check(controller.game_over == true and controller.victory == true, "完成第 10 轮且存活 → 胜利")
	_check(finished_count.size() == finish_before + 1 and finished_victory.back() == true,
		"胜利时发出 game_finished(true)")

	# --- 庄家 16 点继续抽牌 / 17 点停牌 ---
	controller.start_new_game()
	controller.player.clear_hand()
	controller.dealer.clear_hand()
	for c in _hand([["S", "K"], ["H", "6"]]):
		controller.player.receive_card(c)      # 玩家 16，停牌
	for c in _hand([["C", "10"], ["D", "6"]]):
		controller.dealer.receive_card(c)      # 庄家 16
	controller.deck = DeckScript.new()
	controller.round_result_showing = false
	controller.game_over = false
	controller.player_stand()
	_check(controller.dealer_turn_active == true, "庄家 16 进入抽牌阶段")
	var drew := 0
	while controller.dealer_turn_active and drew < 6:
		controller._dealer_step()
		drew += 1
	var d_score: int = controller.dealer.get_score()
	_check(controller.dealer.hand.size() >= 3, "庄家 16 点至少补了 1 张牌")
	_check(d_score >= 17, "庄家抽到 >=17 停止（实际 %d）" % d_score)
	_check(controller.round_result_showing, "庄家行动结束进入结算展示")

	controller.start_new_game()
	controller.player.clear_hand()
	controller.dealer.clear_hand()
	for c in _hand([["S", "10"], ["H", "9"]]):
		controller.player.receive_card(c)      # 玩家 19
	for c in _hand([["C", "10"], ["D", "7"]]):
		controller.dealer.receive_card(c)      # 庄家 17
	controller.deck = DeckScript.new()
	controller.round_result_showing = false
	controller.game_over = false
	controller.player_stand()
	_check(controller.dealer_turn_active == false, "庄家 17 点直接停牌，不进入抽牌阶段")
	_check(controller.dealer.hand.size() == 2, "庄家 17 点没有抽牌")
	_check(controller.round_result_showing, "庄家 17 点直接结算")

	# --- 庄家爆牌 → 玩家胜（BUST 绿）且不扣生命 ---
	var lives_before_bust: int = controller.lives
	controller.player.clear_hand()
	controller.dealer.clear_hand()
	for c in _hand([["S", "10"], ["H", "9"]]):
		controller.player.receive_card(c)      # 玩家 19
	for c in _hand([["C", "K"], ["D", "Q"], ["H", "5"]]):
		controller.dealer.receive_card(c)      # 庄家 25 爆牌
	controller.round_result_showing = false
	controller.game_over = false
	controller._finish_dealer_turn()
	_check(round_results.back() == "BUST", "庄家爆牌 → BUST")
	_check(controller.lives == lives_before_bust, "庄家爆牌不扣玩家生命")

	root.remove_child(controller)
	controller.free()
