class_name TopBar
extends Control
## 상단 재화/스테이지 표시 바

var stage_label: Label
var gold_label: Label
var stress_label: Label
var diamond_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(0, 60)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	stage_label = Label.new()
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stage_label)

	var currency_box := HBoxContainer.new()
	currency_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(currency_box)

	gold_label = Label.new()
	currency_box.add_child(gold_label)

	var sep1 := Label.new()
	sep1.text = "   "
	currency_box.add_child(sep1)

	stress_label = Label.new()
	currency_box.add_child(stress_label)

	var sep2 := Label.new()
	sep2.text = "   "
	currency_box.add_child(sep2)

	diamond_label = Label.new()
	currency_box.add_child(diamond_label)

	GameState.currency_changed.connect(_refresh)
	GameState.stage_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var sub_stage: int = (GameState.stage_index % GameData.STAGE_COUNT) + 1
	stage_label.text = "1-%d %s" % [sub_stage, GameData.STAGE_NAME]
	gold_label.text = "💰 %s" % Fmt.short(GameState.gold)
	stress_label.text = "😤 %s" % Fmt.short(GameState.stress)
	diamond_label.text = "💳 %s" % Fmt.short(GameState.diamond)
