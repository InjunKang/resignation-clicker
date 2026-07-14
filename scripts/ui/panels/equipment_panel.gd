class_name EquipmentPanel
extends Control
## "장비" 탭: 키보드/의자/마우스/드링크 업그레이드

var rows: Dictionary = {}

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	for slot in GameData.EQUIPMENT.keys():
		var row := HBoxContainer.new()
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(320, 0)
		row.add_child(name_label)

		var upgrade_btn := Button.new()
		upgrade_btn.text = "업그레이드"
		upgrade_btn.pressed.connect(_on_upgrade_pressed.bind(slot))
		row.add_child(upgrade_btn)

		rows[slot] = {"name_label": name_label, "button": upgrade_btn}

	GameState.equipment_changed.connect(_refresh)
	GameState.currency_changed.connect(_refresh)
	_refresh()

func _on_upgrade_pressed(slot: String) -> void:
	if GameState.upgrade_equipment(slot):
		Sfx.play_upgrade()

func _refresh() -> void:
	for slot in rows.keys():
		var level: int = GameState.equipment_levels[slot]
		var def: Dictionary = GameData.EQUIPMENT[slot]
		var tier_index: int = GameData.get_equipment_tier_index(level)
		var tier: Dictionary = def["tiers"][tier_index]
		var info: Dictionary = rows[slot]
		info["name_label"].text = "%s %s %s Lv.%d" % [tier["icon"], def["label"], tier["name"], level]
		var cost: float = GameState.get_equip_cost(slot, level)
		info["button"].text = "업그레이드 (💰%s)" % Fmt.short(cost)
		info["button"].disabled = GameState.gold < cost
