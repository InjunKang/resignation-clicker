extends Control
## 루트 씬: 상단바 + 전투화면 + 탭메뉴 + 하단 패널 호스트를 조립한다.

var panel_host: Control
var panels: Dictionary = {}

func _ready() -> void:
	_setup_emoji_fallback()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var top_bar := TopBar.new()
	layout.add_child(top_bar)

	var battle_view := BattleView.new()
	battle_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(battle_view)

	var tab_menu := TabMenu.new()
	layout.add_child(tab_menu)

	panel_host = Control.new()
	panel_host.custom_minimum_size = Vector2(0, 200)
	layout.add_child(panel_host)

	panels["stats"] = StatsPanel.new()
	panels["equipment"] = EquipmentPanel.new()
	panels["team"] = TeamPanel.new()
	panels["invest"] = InvestPanel.new()
	panels["gacha"] = GachaPanel.new()
	panels["prestige"] = PrestigePanel.new()

	for key in panels.keys():
		var p: Control = panels[key]
		panel_host.add_child(p)
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.visible = false
	panels["stats"].visible = true

	tab_menu.tab_selected.connect(_on_tab_selected)

func _on_tab_selected(id: String) -> void:
	for key in panels.keys():
		panels[key].visible = (key == id)

## 프로젝트 기본 폰트(한글용 Pretendard)는 이모지 글리프가 없으므로,
## 흑백 이모지 폰트(Noto Emoji)를 fallback으로 붙여 🔒💰 등이 깨지지 않게 한다.
func _setup_emoji_fallback() -> void:
	var base_font := load("res://assets/fonts/Pretendard-Regular.otf") as FontFile
	var emoji_font := load("res://assets/fonts/NotoEmoji.ttf") as FontFile
	if base_font and emoji_font and base_font.fallbacks.is_empty():
		base_font.fallbacks = [emoji_font]
