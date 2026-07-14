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
	content_label.text = "타자 속도(공격력): %s\n멘탈(최대 체력): %s\n아부력(방어력): %s\n월급루팡 확률(치명타): %.1f%%\n\n장비를 업그레이드하면 능력치가 상승합니다." % [
		Fmt.short(GameState.atk),
		Fmt.short(GameState.max_hp),
		Fmt.short(GameState.def),
		GameState.crit_chance * 100.0,
	]
