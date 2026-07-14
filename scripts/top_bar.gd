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

	var sep3 := Label.new()
	sep3.text = "   "
	currency_box.add_child(sep3)

	var sound_toggle := Button.new()
	sound_toggle.flat = true
	sound_toggle.focus_mode = Control.FOCUS_NONE
	sound_toggle.text = "🔊" if Sfx.enabled else "🔇"
	sound_toggle.pressed.connect(_on_sound_toggle_pressed.bind(sound_toggle))
	currency_box.add_child(sound_toggle)

	GameState.currency_changed.connect(_refresh)
	GameState.stage_changed.connect(_refresh)
	_refresh()

func _on_sound_toggle_pressed(btn: Button) -> void:
	Sfx.enabled = not Sfx.enabled
	btn.text = "🔊" if Sfx.enabled else "🔇"

func _refresh() -> void:
	var company_index: int = GameData.get_company_index(GameState.stage_index)
	var sub_stage: int = (GameState.stage_index % GameData.STAGE_COUNT) + 1
	var company_name: String = GameData.COMPANIES[company_index]["name"]
	stage_label.text = "%d-%d %s" % [company_index + 1, sub_stage, company_name]
	gold_label.text = "💰 %s" % Fmt.short(GameState.gold)
	stress_label.text = "😤 %s" % Fmt.short(GameState.stress)
	diamond_label.text = "💳 %s" % Fmt.short(GameState.diamond)
