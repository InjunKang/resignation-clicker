class_name TeamPanel
extends Control
## "결사대" 탭: 동료 5종의 해금 상태/DPS/패시브 표시

var rows: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	for c in GameData.COMPANIONS:
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(lbl)
		rows[c["id"]] = lbl

	GameState.stage_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for c in GameData.COMPANIONS:
		var lbl: Label = rows[c["id"]]
		if GameState.is_companion_active(c["id"]):
			lbl.text = "%s %s (DPS +%s) — %s" % [c["icon"], c["name"], Fmt.short(c["dps"]), c["desc"]]
		else:
			var comp_idx: int = GameData.get_company_index(c["unlock_stage"])
			var sub_stage: int = (c["unlock_stage"] % GameData.STAGE_COUNT) + 1
			lbl.text = "🔒 %s — 스테이지 %d-%d 도달 시 해금" % [c["name"], comp_idx + 1, sub_stage]
