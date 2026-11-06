# ASSET_LICENSE_AUDIT.md — 资产授权审计

> 状态：**待确认**。在逐项获得授权结论之前，本仓库不附加任何开源许可证，也不声明任何素材可自由商用。

## 审计清单

| 资产 | 文件 | 数量 | 来源 | 授权状态 | 需要确认的事项 |
| --- | --- | --- | --- | --- | --- |
| 主菜单背景 | `assets/backgrounds/firsthead.png` | 1 | 项目作者自绘（原版 Pygame 素材） | 待作者确认 | 是否同意随仓库公开发布与再分发 |
| 牌桌背景 | `assets/backgrounds/desk.png` | 1 | 项目作者自绘 | 待作者确认 | 同上 |
| 扑克牌面 | `assets/cards/C*.png D*.png H*.png S*.png` | 52 | 项目作者自绘 | 待作者确认 | 同上 |
| 牌背 | `assets/cards/WB.png` | 1 | 项目作者自绘 | 待作者确认 | 同上 |
| 菜单按钮图 | `assets/ui/ST.png` `Ru.png` `Ex.png` | 3 | 项目作者自绘 | 待作者确认 | 同上 |
| 生命图标 | `assets/ui/Fullheart.png` `Emheart.png` | 2 | 项目作者自绘 | 待作者确认 | 同上 |
| 规则页图 | `assets/rules/rules1.png` `rules2.png` | 2 | 项目作者自绘（内容含早期下注文案，与实际玩法有差异，见 MIGRATION_NOTES.md） | 待作者确认 | 同上；如公开发布是否需要修订文案 |
| 字体 | `assets/fonts/Ziti.ttf` | 1 | **来源不明**（收集自网络，原版项目即在使用） | **需重点确认** | 字体名称/作者/许可证（是否允许再分发与商用）；无法确认时需替换为可自由分发的字体 |
| 游戏图标 | `icon.png`（源自 card_icon.png 生成） | 1 | 项目作者通过脚本生成 | 待作者确认 | 同上 |
| 音效 | — | 0 | 原项目无音效资源 | — | — |

## 代码

- 游戏代码（GDScript / 场景）：本项目开发产物，授权方式待作者与整体仓库授权一并决定。
- 插件 `addons/godot_ai/`：Godot AI MCP 插件（第三方，随编辑器工作流使用）。其自带 LICENSE 文件（见 `addons/godot_ai/LICENSE`），发布前请核对其许可证是否允许再分发；若不允许，发布仓库时应按其条款处理或移除（移除会影响 project.godot 中已启用的插件配置，需同步处理）。

## 结论 / 行动项

1. **必须确认**：`Ziti.ttf` 字体的来源与再分发权（最高风险项）。
2. **必须确认**：作者自绘素材是否授权公开发布。
3. **必须核对**：`addons/godot_ai/` 插件许可证。
4. 以上确认完成前：README 已注明"授权状态待审计"，未创建任何 LICENSE 文件。
