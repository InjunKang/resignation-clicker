class_name PrestigePanel
extends Control
## "사직서" 탭: 프레스티지(환생) — 진행 초기화 + 영구 버프 구매

var info_label: Label
var prestige_btn: Button
var confirm_dialog: ConfirmationDialog
var rows: Dictionary = {}

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(info_label)

	prestige_btn = Button.new()
	prestige_btn.text = "사직서 던지기"
	prestige_btn.pressed.connect(_on_prestige_pressed)
	vbox.add_child(prestige_btn)

	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "정말 사직서를 던지시겠습니까?\n골드/스트레스/장비 진행이 초기화되고\n영구 재화 '황금 사직서'를 획득합니다."
	confirm_dialog.confirmed.connect(_on_prestige_confirmed)
	add_child(confirm_dialog)

	for i in GameData.PRESTIGE_UPGRADES.size():
		var u: Dictionary = GameData.PRESTIGE_UPGRADES[i]
		var row := HBoxContainer.new()
		vbox.add_child(row)

		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(380, 0)
		row.add_child(lbl)

		var btn := Button.new()
		btn.pressed.connect(func() -> void: GameState.buy_prestige_upgrade(u["id"]))
		row.add_child(btn)

		rows[u["id"]] = {"label": lbl, "button": btn}

	GameState.currency_changed.connect(_refresh)
	GameState.stage_changed.connect(_refresh)
	_refresh()

func _on_prestige_pressed() -> void:
	if not GameState.can_prestige():
		return
	confirm_dialog.popup_centered()

func _on_prestige_confirmed() -> void:
	GameState.do_prestige()

func _refresh() -> void:
	var can: bool = GameState.can_prestige()
	var potential: int = GameData.get_prestige_reward(GameState.stage_index)
	var unlock_company: int = (GameData.PRESTIGE_UNLOCK_STAGE / GameData.STAGE_COUNT) + 1
	var status: String = ("지금 던지면 ★+%d개 획득" % potential) if can else ("%d-1 스테이지 도달 시 사직서를 던질 수 있습니다" % unlock_company)
	info_label.text = "황금 사직서: ★%d개\n%s" % [GameState.prestige_currency, status]
	prestige_btn.disabled = not can

	for i in GameData.PRESTIGE_UPGRADES.size():
		var u: Dictionary = GameData.PRESTIGE_UPGRADES[i]
		var level: int = GameState.prestige_levels.get(u["id"], 0)
		var cost: int = GameData.get_prestige_upgrade_cost(i, level)
		var info: Dictionary = rows[u["id"]]
		info["label"].text = "%s Lv.%d" % [u["name"], level]
		info["button"].text = "★%d" % cost
		info["button"].disabled = GameState.prestige_currency < cost
