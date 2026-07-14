class_name StatsPanel
extends Control
## "업무" 탭: 현재 능력치 표시 (능력치는 장비 업그레이드로만 상승)

var content_label: Label

func _ready() -> void:
	content_label = Label.new()
	content_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(content_label)
	GameState.stats_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	content_label.text = "타자 속도(공격력): %s%s\n멘탈(최대 체력): %s%s\n아부력(방어력): %s\n월급루팡 확률(치명타): %.1f%%%s\n\n장비를 업그레이드하면 능력치가 상승하고, 뽑기 아이템은 별도로 추가 보너스를 줍니다." % [
		Fmt.short(GameState.atk), _gacha_note("keyboard"),
		Fmt.short(GameState.max_hp), _gacha_note("chair"),
		Fmt.short(GameState.def),
		GameState.crit_chance * 100.0, _gacha_note("mouse"),
	]

func _gacha_note(slot: String) -> String:
	var pct: float = GameState.get_gacha_bonus_percent(slot)
	if pct <= 0.0:
		return ""
	return " (뽑기템 +%.0f%%)" % pct
