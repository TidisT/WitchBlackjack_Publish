# TEST_PLAN.md — 测试说明

## 测试入口

| 文件 | 覆盖范围 | 运行方式 |
| --- | --- | --- |
| `tests/run_tests.gd` | 纯逻辑：卡牌/牌组/点数/胜负规则/游戏流程（61 项断言） | `--headless -s res://tests/run_tests.gd` |
| `tests/ui_views_test.gd` | UI 视图集成：真实 Game.tscn 实例化后视图数量/纹理/位置/缩放（22 项断言） | `--headless -s res://tests/ui_views_test.gd` |

退出码 0 = 全部通过（输出 `ALL TESTS PASSED`）。
测试不依赖任何第三方插件；`run_tests.gd` 中 GameController 以 `timers_enabled=false`
同步驱动流程，`ui_views_test.gd` 按真实计时器等待动画完成。

## 覆盖清单（对应任务书第九章）

### 9.1 卡牌数据
52 张创建 / 4 花色 / 13 点数 / 无重复组合 / JQK=10 / A=11 / 数字牌面值 / 纹理路径命名

### 9.2 牌组
52 张 / 洗牌后仍 52 张 / 洗牌改变牌序 / 抽牌减数 / 抽空 / 空牌堆 deal() 返回 null 不崩溃

### 9.3 点数计算
K+A=21 / A+6=17 / A+9+5=15 / A+A+9+2=13 / 10+K+2=22 / A+A=12 / 爆牌判定 / Participant.get_score 一致性

### 9.4 胜负规则
数值比较 WIN/LOSE/PUSH / 玩家初始 BJ / 庄家初始 BJ / 双 BJ / 三张 21 不算 BJ / 庄家 16 抽 17 停 21 停

### 9.5 游戏流程
新游戏初始化（生命 5/轮数 1/各 2 张/牌堆 48） / 轮数递增 / 生命扣除 / 生命归零失败并发 game_finished(false)
/ One More 重置 / 第 10 轮存活胜利并发 game_finished(true) / 庄家 16 补牌至 ≥17 / 庄家 17 直接停 / 庄家爆牌不扣血

### UI 集成（ui_views_test.gd）
开局 4 视图 / 视图数==手牌数（3 轮 Stand 流程 + Hit 路径） / CardLayer 子节点数==双方手牌总数
/ 所有纹理非空 / 位置在手牌区 / 翻牌动画归位（scale==1）

## 实机（MCP）验证记录（2026-11-06/07）

通过 Godot AI MCP 驱动真实编辑器运行游戏并注入输入，逐项目视截图验证：

- 主菜单：背景 + Start/Rules/Exit 图片按钮，点击进入对应场景
- 规则页：两页原图等比完整显示；Next/Last 切换；ESC 返回主菜单
- 牌桌：暗牌显示 WB 牌背、庄家明牌与分数正确；Hit 得牌即时显示（修复 player_hit 缺 card_dealt 信号后）
- 多张手牌 55px 重叠、自动居中重排（验证过 4、5 张）
- BUST 红/绿、LOSE、Dealer Drawing... 提示、按钮禁用态
- 完整对局至生命归零 → YOU LOSE + One More/Exit；One More 重开正常
- 生命爱心满/空显示与扣除反馈

## 已修复的缺陷（测试发现）

1. `player_hit()` 未发出 `card_dealt` 信号 → Hit 的牌不显示（UI 集成测试抓出）
2. CardView `expand_mode` 设置顺序错误 → 卡牌被纹理原始尺寸 320×480 钳制
3. 生命归零时 `game_finished` 不发出 → 结束界面不出现（流程测试抓出）
4. One More 重开时旧计时器回调污染新对局 → 引入对局代数令牌
