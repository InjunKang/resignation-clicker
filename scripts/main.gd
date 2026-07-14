extends Control
## 루트 씬: 상단바 + 전투화면 + 탭메뉴 + 하단 패널 호스트를 조립한다.
## "코믹 오피스" 테마(밝은 배경 + 카드형 패널)로 스타일링한다.

var panel_host: Control
var panels: Dictionary = {}

func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_background()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var top_card := PanelContainer.new()
	layout.add_child(top_card)
	var top_bar := TopBar.new()
	top_card.add_child(top_bar)

	var battle_card := PanelContainer.new()
	layout.add_child(battle_card)
	var battle_view := BattleView.new()
	battle_card.add_child(battle_view)

	var tab_menu := TabMenu.new()
	layout.add_child(tab_menu)

	var panel_card := PanelContainer.new()
	panel_card.custom_minimum_size = Vector2(0, 260)
	panel_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(panel_card)
	panel_host = Control.new()
	panel_card.add_child(panel_host)

	panels["stats"] = StatsPanel.new()
	panels["equipment"] = EquipmentPanel.new()
	panels["team"] = TeamPanel.new()
	panels["invest"] = InvestPanel.new()
	panels["gacha"] = GachaPanel.new()
	panels["prestige"] = PrestigePanel.new()
	panels["achievement"] = AchievementPanel.new()

	for key in panels.keys():
		var p: Control = panels[key]
		panel_host.add_child(p)
		p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.visible = false
	panels["stats"].visible = true

	tab_menu.tab_selected.connect(_on_tab_selected)

func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, UiTheme.COLOR_BG_TOP)
	gradient.set_color(1, UiTheme.COLOR_BG_BOTTOM)
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, 1)
	gradient_texture.width = 8
	gradient_texture.height = 256

	var bg := TextureRect.new()
	bg.texture = gradient_texture
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _on_tab_selected(id: String) -> void:
	for key in panels.keys():
		panels[key].visible = (key == id)
