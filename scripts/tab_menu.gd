class_name TabMenu
extends Control
## 하단 탭 메뉴: 업무/장비/결사대(잠금)/재테크(잠금)/뽑기(잠금)

signal tab_selected(id: String)

func _ready() -> void:
	custom_minimum_size = Vector2(0, 56)
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
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
		btn.custom_minimum_size = Vector2(80, 0)
		btn.pressed.connect(func() -> void: tab_selected.emit(tab["id"]))
		hbox.add_child(btn)
