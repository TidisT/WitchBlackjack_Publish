extends Control
## 规则页：两页原版规则图片等比缩放居中；底部黑色操作栏。
## 键盘：ESC=返回主菜单，RIGHT=下一页，LEFT=上一页。

const RULE_TEXTURES: Array[String] = [
	"res://assets/rules/rules1.png",
	"res://assets/rules/rules2.png",
]

var current_page: int = 0

@onready var rule_image: TextureRect = $RuleImage
@onready var menu_button: Button = $BottomBar/MenuButton
@onready var next_button: Button = $BottomBar/NextButton
@onready var last_button: Button = $BottomBar/LastButton


func _ready() -> void:
	menu_button.pressed.connect(_go_to_menu)
	next_button.pressed.connect(func() -> void: _switch_page(1))
	last_button.pressed.connect(func() -> void: _switch_page(-1))
	_show_page(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_go_to_menu()
			KEY_RIGHT:
				_switch_page(1)
			KEY_LEFT:
				_switch_page(-1)


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")


func _switch_page(direction: int) -> void:
	_show_page(current_page + direction)


func _show_page(page: int) -> void:
	current_page = clampi(page, 0, RULE_TEXTURES.size() - 1)
	rule_image.texture = load(RULE_TEXTURES[current_page])
	# 第一页只有 Menu/Next，第二页只有 Menu/Last（原版行为）
	next_button.visible = current_page == 0
	last_button.visible = current_page == 1
