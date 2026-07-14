class_name UiTheme
extends RefCounted
## "코믹 오피스" 테마 빌더 — 밝고 채도 높은 카드형 UI. Main이 루트 Control의
## `theme`로 설정해서 하위 모든 Control에 전파시킨다.

const COLOR_TEXT := Color("#2B2440")
const COLOR_ORANGE := Color("#FF6B35")
const COLOR_MINT := Color("#2EC4B6")
const COLOR_YELLOW := Color("#FFD23F")
const COLOR_RED := Color("#E63946")
const COLOR_GREEN := Color("#06D6A0")
const COLOR_PANEL := Color("#FFFFFF")
const COLOR_OUTLINE := Color("#2B2440")
const COLOR_TRACK := Color("#EFE7D4")
const COLOR_BG_TOP := Color("#FFF6E5")
const COLOR_BG_BOTTOM := Color("#FFE9C2")

const BASE_FONT_SIZE := 22
const BUTTON_FONT_SIZE := 20

static func build() -> Theme:
	var theme := Theme.new()

	var base_font: FontFile = load("res://assets/fonts/Pretendard-Regular.otf")
	var bold_font: FontFile = load("res://assets/fonts/Pretendard-Bold.otf")
	var emoji_font: FontFile = load("res://assets/fonts/NotoEmoji.ttf")
	if base_font and emoji_font and base_font.fallbacks.is_empty():
		base_font.fallbacks = [emoji_font]
	if bold_font and emoji_font and bold_font.fallbacks.is_empty():
		bold_font.fallbacks = [emoji_font]

	theme.default_font = base_font
	theme.default_font_size = BASE_FONT_SIZE
	theme.set_type_variation("BoldLabel", "Label")
	theme.set_font("font", "BoldLabel", bold_font)
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font_size("font_size", "Label", BASE_FONT_SIZE)

	# --- Button ---
	var btn_normal := _flat_style(COLOR_ORANGE, 14, 2)
	var btn_hover := _flat_style(COLOR_ORANGE.lightened(0.12), 14, 2)
	var btn_pressed := _flat_style(COLOR_ORANGE.darkened(0.12), 14, 2)
	btn_pressed.content_margin_top += 2.0
	btn_pressed.shadow_size = 0
	var btn_disabled := _flat_style(Color("#DAD3C2"), 14, 2)
	btn_disabled.border_color = Color("#B9B2A0")
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("focus", "Button", _flat_style(COLOR_ORANGE, 14, 2))
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_font("font", "Button", bold_font)
	theme.set_font_size("font_size", "Button", BUTTON_FONT_SIZE)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("#8A8474"))

	# --- Panel / PanelContainer (card containers, 서로 다른 테마 타입이라 둘 다 설정) ---
	theme.set_stylebox("panel", "Panel", _flat_style(COLOR_PANEL, 18, 2))
	theme.set_stylebox("panel", "PanelContainer", _flat_style(COLOR_PANEL, 18, 2))

	# --- ProgressBar ---
	var track := StyleBoxFlat.new()
	track.bg_color = COLOR_TRACK
	track.set_corner_radius_all(8)
	track.set_border_width_all(2)
	track.border_color = COLOR_OUTLINE
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_MINT
	fill.set_corner_radius_all(8)
	theme.set_stylebox("background", "ProgressBar", track)
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_font_size("font_size", "ProgressBar", 16)

	return theme

static func _flat_style(bg: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_width)
	sb.border_color = COLOR_OUTLINE
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.shadow_size = 3
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	sb.shadow_offset = Vector2(0, 2)
	return sb

## 적/플레이어 HP 바 등, 개별 인스턴스에 색을 다르게 줄 때 사용.
static func make_fill_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	return sb
