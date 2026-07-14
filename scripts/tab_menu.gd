class_name TabMenu
extends Control
## 하단 탭 메뉴: 업무/장비/결사대/재테크/뽑기/사직서/업적

signal tab_selected(id: String)

func _ready() -> void:
	custom_minimum_size = Vector2(0, 76)
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	var tabs := [
		{"id": "stats", "label": "업무"},
		{"id": "equipment", "label": "장비"},
		{"id": "team", "label": "결사대"},
		{"id": "invest", "label": "재테크"},
		{"id": "gacha", "label": "뽑기"},
		{"id": "prestige", "label": "사직서"},
		{"id": "achievement", "label": "업적"},
	]
	for tab in tabs:
		var btn := Button.new()
		btn.text = tab["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		btn.pressed.connect(func() -> void: Sfx.play_click(); tab_selected.emit(tab["id"]))
		hbox.add_child(btn)
