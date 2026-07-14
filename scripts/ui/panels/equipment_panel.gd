class_name EquipmentPanel
extends Control
## "장비" 탭: 키보드/의자/마우스/드링크 업그레이드

var rows: Dictionary = {}
var upgrade_all_btn: Button

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	upgrade_all_btn = Button.new()
	upgrade_all_btn.text = "전체 최대 강화 (싼 순서대로 일괄 구매)"
	upgrade_all_btn.pressed.connect(_on_upgrade_all_pressed)
	vbox.add_child(upgrade_all_btn)

	for slot in GameData.EQUIPMENT.keys():
		var row := HBoxContainer.new()
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(300, 0)
		row.add_child(name_label)

		var upgrade_btn := Button.new()
		upgrade_btn.text = "업그레이드"
		upgrade_btn.pressed.connect(_on_upgrade_pressed.bind(slot))
		row.add_child(upgrade_btn)

		var max_btn := Button.new()
		max_btn.text = "MAX"
		max_btn.pressed.connect(_on_upgrade_max_pressed.bind(slot))
		row.add_child(max_btn)

		rows[slot] = {"name_label": name_label, "button": upgrade_btn, "max_button": max_btn}

	GameState.equipment_changed.connect(_refresh)
	GameState.currency_changed.connect(_refresh)
	_refresh()

func _on_upgrade_pressed(slot: String) -> void:
	if GameState.upgrade_equipment(slot):
		Sfx.play_upgrade()

func _on_upgrade_max_pressed(slot: String) -> void:
	if GameState.upgrade_equipment_max(slot) > 0:
		Sfx.play_upgrade()

func _on_upgrade_all_pressed() -> void:
	if GameState.upgrade_all_equipment_max() > 0:
		Sfx.play_upgrade()

func _refresh() -> void:
	var any_affordable: bool = false
	for slot in rows.keys():
		var level: int = GameState.equipment_levels[slot]
		var def: Dictionary = GameData.EQUIPMENT[slot]
		var tier_index: int = GameData.get_equipment_tier_index(level)
		var tier: Dictionary = def["tiers"][tier_index]
		var info: Dictionary = rows[slot]
		info["name_label"].text = "%s %s %s Lv.%d" % [tier["icon"], def["label"], tier["name"], level]
		var cost: float = GameState.get_equip_cost(slot, level)
		var affordable: bool = GameState.gold >= cost
		any_affordable = any_affordable or affordable
		info["button"].text = "업그레이드 (💰%s)" % Fmt.short(cost)
		info["button"].disabled = not affordable
		info["max_button"].disabled = not affordable
	upgrade_all_btn.disabled = not any_affordable
