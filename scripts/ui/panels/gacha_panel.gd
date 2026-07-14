class_name GachaPanel
extends Control
## "뽑기" 탭: 법인카드(다이아)로 장비 랜덤 강화

var gacha_btn: Button
var result_label: Label

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var desc := Label.new()
	desc.text = "법인카드로 장비 슬롯 1개를 무작위로 강화합니다."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	gacha_btn = Button.new()
	gacha_btn.pressed.connect(_on_gacha)
	vbox.add_child(gacha_btn)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(result_label)

	GameState.currency_changed.connect(_refresh)
	_refresh()

func _on_gacha() -> void:
	var res: Dictionary = GameState.do_gacha()
	if res.get("success", false):
		var slot_label: String = GameData.EQUIPMENT[res["slot"]]["label"]
		result_label.text = "%s +%d Lv! 🎉" % [slot_label, res["levels"]]
	else:
		result_label.text = "법인카드가 부족합니다."

func _refresh() -> void:
	gacha_btn.text = "뽑기 (💳%d)" % GameData.GACHA_COST_DIAMOND
	gacha_btn.disabled = GameState.diamond < GameData.GACHA_COST_DIAMOND
