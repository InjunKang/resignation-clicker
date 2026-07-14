class_name TeamPanel
extends Control
## "결사대" 탭: 동료 5종의 해금 상태/DPS/패시브 표시 (초상화 포함)

var rows: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	for c in GameData.COMPANIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vbox.add_child(row)

		var portrait := TextureRect.new()
		portrait.texture = load("res://assets/art/companion_%s.svg" % c["id"])
		portrait.custom_minimum_size = Vector2(56, 56)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)

		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		rows[c["id"]] = {"label": lbl, "portrait": portrait}

	GameState.stage_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for c in GameData.COMPANIONS:
		var info: Dictionary = rows[c["id"]]
		var lbl: Label = info["label"]
		var portrait: TextureRect = info["portrait"]
		var unlocked: bool = GameState.is_companion_active(c["id"])
		portrait.modulate = Color.WHITE if unlocked else Color(0.55, 0.55, 0.55, 0.55)
		if unlocked:
			lbl.text = "%s %s (DPS +%s)\n%s" % [c["icon"], c["name"], Fmt.short(c["dps"]), c["desc"]]
		else:
			var comp_idx: int = GameData.get_company_index(c["unlock_stage"])
			var sub_stage: int = (c["unlock_stage"] % GameData.STAGE_COUNT) + 1
			lbl.text = "🔒 %s\n스테이지 %d-%d 도달 시 해금" % [c["name"], comp_idx + 1, sub_stage]
