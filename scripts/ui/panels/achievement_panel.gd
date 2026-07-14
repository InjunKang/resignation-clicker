class_name AchievementPanel
extends Control
## "업적" 탭: 평생 누적 스탯 기반 업적 달성/보상 수령

var rows: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	for a in GameData.ACHIEVEMENTS:
		var row := VBoxContainer.new()
		vbox.add_child(row)

		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(lbl)

		var btn := Button.new()
		btn.pressed.connect(func() -> void: GameState.claim_achievement(a["id"]))
		row.add_child(btn)

		rows[a["id"]] = {"label": lbl, "button": btn}

	GameState.currency_changed.connect(_refresh)
	GameState.stage_changed.connect(_refresh)
	GameState.equipment_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for a in GameData.ACHIEVEMENTS:
		var info: Dictionary = rows[a["id"]]
		var claimed: bool = GameState.is_achievement_claimed(a["id"])
		var complete: bool = GameState.is_achievement_complete(a)
		var progress: float = GameState.get_achievement_progress(a)
		var mark: String = "✅" if claimed else ("⭐" if complete else "🔲")
		info["label"].text = "%s %s — %s (%d%%)" % [mark, a["name"], a["desc"], int(progress * 100)]
		if claimed:
			info["button"].text = "완료"
			info["button"].disabled = true
		elif complete:
			info["button"].text = "💳%d 받기" % a["reward"]
			info["button"].disabled = false
		else:
			info["button"].text = "💳%d" % a["reward"]
			info["button"].disabled = true
