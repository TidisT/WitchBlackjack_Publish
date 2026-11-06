extends SceneTree
## UI 视图集成测试：实例化真实 Game.tscn，完整模拟多轮对局，
## 断言卡牌视图数量与手牌一致、纹理非空、位置在屏内。
## 运行：Godot_v4.7.2-stable_win64_console.exe --headless --path <项目> -s res://tests/ui_views_test.gd

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	await _run()
	print("")
	print("UI 视图测试: 通过 %d 失败 %d" % [_passed, _failed])
	if _failed == 0:
		print("ALL UI TESTS PASSED")
		quit(0)
	else:
		print("UI TESTS FAILED")
		quit(1)


func _check(cond: bool, test_name: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		_failed += 1
		print("  [FAIL] %s" % test_name)


func _run() -> void:
	var game_scene: PackedScene = load("res://scenes/game/Game.tscn")
	var screen = game_scene.instantiate()
	root.add_child(screen)
	await process_frame

	var controller = screen.get_node("GameController")
	var card_layer = screen.get_node("CardLayer")

	# 等待开局发牌动画完成（4 张 × 0.22s + 判定）
	await create_timer(1.8).timeout

	_check(card_layer.get_child_count() == 4,
		"开局后 CardLayer 有 4 张卡牌视图（实际 %d）" % card_layer.get_child_count())
	_check(screen._dealer_views.size() == 2 and screen._player_views.size() == 2,
		"庄/家视图数组各 2")

	# 完整打 3 轮（玩家直接停牌），每轮后检查视图一致性
	for round_i in 3:
		# 等玩家可操作（结果展示 1.2s + 发牌 0.9s 内完成）
		var guard := 0
		while controller.round_result_showing and guard < 60:
			await create_timer(0.1).timeout
			guard += 1
		if controller.game_over:
			break
		screen._on_restart_requested if false else null
		controller.player_stand()
		# 等庄家抽牌与结果展示结束
		guard = 0
		while (controller.dealer_turn_active or controller.round_result_showing) and guard < 100:
			await create_timer(0.1).timeout
			guard += 1

		_check(screen._dealer_views.size() == controller.dealer.hand.size(),
			"第 %d 轮结束：庄家视图数(%d) == 手牌数(%d)"
				% [round_i + 1, screen._dealer_views.size(), controller.dealer.hand.size()])
		_check(screen._player_views.size() == controller.player.hand.size(),
			"第 %d 轮结束：玩家视图数(%d) == 手牌数(%d)"
				% [round_i + 1, screen._player_views.size(), controller.player.hand.size()])
		_check(card_layer.get_child_count()
			== controller.dealer.hand.size() + controller.player.hand.size(),
			"第 %d 轮结束：CardLayer 子节点数 == 双方手牌总数" % (round_i + 1))

		# 每个 view：纹理非空、位置在 760×540 屏内（允许动画余量）、缩放为 1
		var views_ok := true
		var pos_ok := true
		var scale_ok := true
		for v in card_layer.get_children():
			if v.texture == null:
				views_ok = false
			if v.position.x < -10 or v.position.x > 700 or v.position.y < 90 or v.position.y > 440:
				pos_ok = false
			if not v.scale.is_equal_approx(Vector2.ONE):
				scale_ok = false
		_check(views_ok, "第 %d 轮结束：所有视图纹理非空" % (round_i + 1))
		_check(pos_ok, "第 %d 轮结束：所有视图位置在手牌区域内" % (round_i + 1))
		_check(scale_ok, "第 %d 轮结束：所有视图缩放为 1（翻牌动画归位）" % (round_i + 1))

		# 进入下一轮（等 _after_result 推进）
		guard = 0
		while controller.round_result_showing and guard < 40:
			await create_timer(0.1).timeout
			guard += 1

	# 玩家 Hit 路径：等可操作后连按 Hit 到爆牌或 5 张
	var guard2 := 0
	while controller.round_result_showing and guard2 < 60:
		await create_timer(0.1).timeout
		guard2 += 1
	if not controller.game_over:
		var hits := 0
		while not controller.round_result_showing and not controller.game_over and hits < 5:
			controller.player_hit()
			hits += 1
			await create_timer(0.35).timeout
		_check(screen._player_views.size() == controller.player.hand.size(),
			"Hit 后玩家视图数(%d) == 手牌数(%d)" % [screen._player_views.size(), controller.player.hand.size()])
		var all_tex := true
		for v in screen._player_views:
			if v.texture == null:
				all_tex = false
		_check(all_tex, "Hit 后所有玩家视图纹理非空")

	root.remove_child(screen)
	screen.free()
