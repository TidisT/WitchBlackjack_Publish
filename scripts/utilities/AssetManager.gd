class_name AssetManager
extends Object
## 静态资源统一访问：带缓存的纹理加载（避免每次抽牌重复 load），
## 卡牌纹理按花色/点数命名约定取路径。缺失资源时给出清晰错误信息。

static var _texture_cache: Dictionary = {}

const CARD_BACK_PATH := "res://assets/cards/WB.png"
const FONT_PATH := "res://assets/fonts/Ziti.ttf"


## 通用纹理获取（带缓存）。
static func get_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not ResourceLoader.exists(path):
		push_error("AssetManager: 找不到资源文件: %s" % path)
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		push_error("AssetManager: 资源加载失败: %s" % path)
		return null
	_texture_cache[path] = tex
	return tex


## 卡牌正面纹理：suit∈{C,D,H,S}，rank∈{2..10,J,Q,K,A}。
static func get_card_texture(suit: String, rank: String) -> Texture2D:
	return get_texture("res://assets/cards/%s%s.png" % [suit, rank])


## 卡牌背面纹理。
static func get_card_back() -> Texture2D:
	return get_texture(CARD_BACK_PATH)


## 项目字体。
static func get_font() -> FontFile:
	if not ResourceLoader.exists(FONT_PATH):
		push_error("AssetManager: 找不到字体: %s" % FONT_PATH)
		return null
	return load(FONT_PATH)
