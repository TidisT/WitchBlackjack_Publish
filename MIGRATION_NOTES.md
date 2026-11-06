# MIGRATION_NOTES.md — Pygame → Godot 4 迁移记录

## 迁移基本信息

- 原项目：Witch's Blackjack（Python + Pygame，单文件状态机：`main.py` / `objects/` / `states/`）
- 目标项目：`WitchBlackjack_Godot/`（Godot 4.7.2-stable，GDScript）
- 原则：**第一版以实际 Pygame 源码为准**，任务书与规则图片冲突之处记录于此。

## 原版行为确认清单（逐条来自源码阅读）

| 行为 | 原版实现 | Godot 版实现 |
| --- | --- | --- |
| 窗口 | 760×540，标题 Witch's Blackjack | 相同；`canvas_items` 拉伸 + `keep` 比例，窗口可缩放不破版 |
| 每轮发牌 | 新建 52 张牌并洗牌，玩家→庄家→玩家→庄家 | 相同（`GameController.start_round()`） |
| 暗牌 | 庄家第 1 张（hand[0]）盖住，hand[1] 明牌 | 相同（`CardView` 翻转显示背面） |
| 庄家分数（未翻牌） | 只显示明牌 `hand[1].value`（J/Q/K=10、A=11 原始值，不做 A 调整） | 相同（忠实复刻，见"差异说明"） |
| A 计分 | 11 起算，>21 时逐个降为 1 | `BlackjackRules.hand_score()` 相同逻辑 |
| Hit | 抽 1 张，>21 立即 BUST、生命-1、庄家翻牌 | 相同 |
| Stand | 庄家翻牌；<17 每 700ms 抽一张；≥17 结算 | 相同（`DealerDrawTimer` 0.7s） |
| 庄家规则 | <17 必抽，≥17 必停 | `BlackjackRules.dealer_should_hit()` |
| 初始 Blackjack | 双 21=PUSH（不扣血）；仅玩家=BLACKJACK 绿；仅庄家=BLACKJACK 红、生命-1 | 相同 |
| 结算文字停留 | 1200ms 后进入下一轮 | 相同（`ResultTimer` 1.2s） |
| 十轮生存 | 第 10 轮结算展示结束后存活即胜利（即使第 10 轮 LOSE） | 相同（`_next_round()`：`round_num >= 10` → victory） |
| 生命 | 5 颗心，38×38，x=20，y=320+45i | 相同（`HeartDisplay`） |
| 按钮 | Hit(575,205,150×60)、Stand(540,285,190×60)、One More(520,355,200×55)、Exit(520,425,200×55) | 相同坐标 |
| 键盘 | H=Hit、S=Stand、R=结束后重来、ESC=仅游戏结束界面退出 | 相同；游戏过程 ESC 无功能（忠实原版） |
| 菜单 | 背景 firsthead.png；ST/Ru/Ex 150×50，中心 (380,330)/(380,400)/(380,470) | 相同（TextureButton） |
| 规则页 | rules1/2 等比缩放居中于 760×480 区域；底部 60px 黑条；Menu 中(380,510)、Next(670,510)、Last(90,510)；ESC/←/→ 键盘 | 相同 |
| 卡牌显示 | 320×480 原图缩放到 71×96，手牌间距 55px 自动居中 | 相同（`CardView` + `GameScreen` 布局） |
| 字体 | assets/fonts/Ziti.ttf（22/28/54 三种字号） | 相同 |

## 与规则图片的差异（任务书 6.3 要求记录）

规则图片（rules1.png / rules2.png）中包含**下注与返还筹码**的说明文字，但原版 Pygame 代码**没有实现任何下注/筹码系统**。按任务书要求：

- 第一版不添加下注机制，以实际代码为准；
- 规则图片按原图完整显示，未裁剪、未改字。

## Godot 版新增（不改变玩法）

- 发牌动画：卡牌从牌堆位置飞入手牌区（Tween，约 0.22s/张），发牌期间禁止操作；原版为瞬间发牌，最终手牌结果与原版一致。
- 暗牌翻开带水平翻转动画（0.18s）；手牌数量变化时平滑重新居中（0.2s）。
- 结果文字淡入+缩放；生命扣除时爱心脉冲反馈；按钮 hover/pressed 有视觉反馈且结算期间真正 `disabled`。
- 结算等待（1.2s）期间与庄家回合期间禁止 Hit/Stand，与原版一致。

## 结构映射

| Pygame | Godot |
| --- | --- |
| `objects/card.py` | `scripts/core/CardData.gd`（纯数据） |
| `objects/deck.py` | `scripts/core/Deck.gd` |
| `objects/participant.py` | `scripts/core/Participant.gd` |
| （散落在 game_state.py 的规则判断） | `scripts/core/BlackjackRules.gd`（静态纯函数） |
| `states/game_state.py` 流程控制 | `scripts/managers/GameController.gd`（信号驱动） |
| `states/game_state.py` 绘制 | `scenes/game/Game.tscn` + `scripts/ui/GameScreen.gd` 等 |
| `states/menu_state.py` | `scenes/main/MainMenu.tscn` + `scripts/ui/MainMenu.gd` |
| `states/rule_state.py` | `scenes/rules/Rules.tscn` + `scripts/ui/Rules.gd` |

## 原始资产处理

- 仅迁移源码所需素材；PyInstaller 的 `build/`、`dist/`、`__pycache__`、`.spec`、`.exe` 一律未导入。
- `card_icon.png` 作为项目图标（`icon.png`）；`icon.ico` 为 Windows 打包图标格式，Godot 项目内不直接引用，保留在原版目录。
- 原版 Pygame 项目文件未做任何修改、覆盖或删除。
