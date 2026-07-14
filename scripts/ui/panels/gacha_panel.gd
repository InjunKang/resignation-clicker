class_name GachaPanel
extends Control
## "뽑기" 탭: 법인카드(다이아)로 뽑는 별도 아이템. 장비 레벨에 합쳐지지 않고
## 아이템을 실제로 보유하며, 해당 스탯에 추가 보너스(%)를 곱연산으로 더한다.

var gacha_btn: Button
var result_label: Label
var pity_label: Label
var inventory_rows: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var desc := Label.new()
	desc.text = "법인카드로 뽑으면 능력치 아이템을 얻습니다. 장비와는 별개로 보유하며 추가 보너스를 줍니다."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	gacha_btn = Button.new()
	gacha_btn.pressed.connect(_on_gacha)
	vbox.add_child(gacha_btn)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(result_label)

	pity_label = Label.new()
	pity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pity_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	pity_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(pity_label)

	var inv_title := Label.new()
	inv_title.text = "보유 아이템"
	inv_title.add_theme_font_override("font", load("res://assets/fonts/Pretendard-Bold.otf"))
	vbox.add_child(inv_title)

	for slot in GameData.EQUIPMENT.keys():
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(lbl)
		inventory_rows[slot] = lbl

	GameState.currency_changed.connect(_refresh)
	GameState.equipment_changed.connect(_refresh)
	_refresh()

func _on_gacha() -> void:
	var res: Dictionary = GameState.do_gacha()
	if res.get("success", false):
		Sfx.play_gacha()
		var stat_name: String = GameData.get_gacha_stat_name(res["slot"])
		var bonus_pct: int = int(round(res["bonus"] * 100.0))
		result_label.text = "[%s] %s 아이템 획득! (+%d%%) 🎉" % [res["rarity"], stat_name, bonus_pct]
		result_label.add_theme_color_override("font_color", GameData.get_gacha_rarity_color(res["rarity_level"]))
		result_label.add_theme_font_size_override("font_size", 26 if res["rarity_level"] >= GameData.GACHA_MAX_LEVELS else 20)
		_pulse(result_label)
	else:
		result_label.text = "법인카드가 부족합니다."
		result_label.remove_theme_color_override("font_color")
		result_label.remove_theme_font_size_override("font_size")
	_refresh()

func _pulse(control: Control) -> void:
	control.scale = Vector2(1.4, 1.4)
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh() -> void:
	gacha_btn.text = "뽑기 (💳%d)" % GameData.GACHA_COST_DIAMOND
	gacha_btn.disabled = GameState.diamond < GameData.GACHA_COST_DIAMOND
	var remaining: int = maxi(GameData.GACHA_PITY_THRESHOLD - GameState.gacha_pity, 0)
	pity_label.text = "천장까지 %d회 (그 안에 [전설]을 못 뽑으면 다음 뽑기는 확정 전설)" % remaining

	for slot in GameData.EQUIPMENT.keys():
		var lbl: Label = inventory_rows[slot]
		var stat_name: String = GameData.get_gacha_stat_name(slot)
		var counts: Dictionary = {1: 0, 2: 0, 3: 0}
		for item in GameState.gacha_items:
			if item["slot"] == slot:
				counts[item["rarity"]] = counts.get(item["rarity"], 0) + 1
		var total: int = counts[1] + counts[2] + counts[3]
		var bonus_pct: float = GameState.get_gacha_bonus_percent(slot)
		if total == 0:
			lbl.text = "%s: 보유 아이템 없음" % stat_name
		else:
			lbl.text = "%s: 일반x%d 희귀x%d 전설x%d — 총 +%.0f%%" % [stat_name, counts[1], counts[2], counts[3], bonus_pct]
