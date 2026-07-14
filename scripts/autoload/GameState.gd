extends Node
## 런타임 플레이어 상태 (Autoload 싱글톤: "GameState")

signal currency_changed
signal stats_changed
signal equipment_changed
signal stage_changed

var gold: float = 0.0
var stress: float = 0.0
var diamond: float = 0.0

var stage_index: int = 0 # 0-based (0 == 1-1)
var mobs_defeated_in_stage: int = 0

var equipment_levels: Dictionary = {
	"keyboard": 0,
	"chair": 0,
	"mouse": 0,
	"drink": 0,
}

var last_save_unix: int = 0

# 파생 스탯 (recalculate_stats에서 갱신)
var atk: float = 0.0
var max_hp: float = 0.0
var def: float = 0.0
var crit_chance: float = 0.0
var gold_rate_mult: float = 1.0

func _ready() -> void:
	recalculate_stats()

func recalculate_stats() -> void:
	var kb_bonus: float = GameData.get_equipment_stat_bonus("keyboard", equipment_levels["keyboard"])
	var chair_bonus: float = GameData.get_equipment_stat_bonus("chair", equipment_levels["chair"])
	var mouse_bonus: float = GameData.get_equipment_stat_bonus("mouse", equipment_levels["mouse"])
	var drink_bonus: float = GameData.get_equipment_stat_bonus("drink", equipment_levels["drink"])

	atk = GameData.BASE_ATK * kb_bonus
	max_hp = GameData.BASE_HP * chair_bonus
	crit_chance = clamp(0.05 * mouse_bonus, 0.0, 0.75)
	gold_rate_mult = drink_bonus
	def = GameData.BASE_DEF + equipment_levels["chair"] * 0.2

	stats_changed.emit()

func add_gold(amount: float) -> void:
	gold += amount * gold_rate_mult
	currency_changed.emit()

func spend_gold(amount: float) -> bool:
	if gold >= amount:
		gold -= amount
		currency_changed.emit()
		return true
	return false

func add_stress(amount: float) -> void:
	stress += amount
	currency_changed.emit()

func upgrade_equipment(slot: String) -> bool:
	var level: int = equipment_levels[slot]
	var max_level: int = GameData.get_equipment_max_level(slot)
	if level >= max_level:
		return false
	var cost: float = GameData.get_equipment_upgrade_cost(slot, level)
	if not spend_gold(cost):
		return false
	equipment_levels[slot] = level + 1
	recalculate_stats()
	equipment_changed.emit()
	return true

func advance_stage() -> void:
	stage_index += 1
	mobs_defeated_in_stage = 0
	stage_changed.emit()

func register_mob_kill() -> void:
	mobs_defeated_in_stage += 1

func is_boss_stage() -> bool:
	return mobs_defeated_in_stage >= GameData.MOBS_PER_STAGE

## 오프라인 보상 추정치 계산에 사용 (초당 골드 생산량 근사치)
func get_estimated_gold_per_second() -> float:
	var mob_hp: float = GameData.get_mob_hp(stage_index)
	var mob_gold: float = GameData.get_mob_gold_reward(stage_index)
	var kills_per_second: float = atk / max(mob_hp, 1.0)
	return kills_per_second * mob_gold * gold_rate_mult

func to_save_dict() -> Dictionary:
	return {
		"gold": gold,
		"stress": stress,
		"diamond": diamond,
		"stage_index": stage_index,
		"mobs_defeated_in_stage": mobs_defeated_in_stage,
		"equipment_levels": equipment_levels.duplicate(),
		"last_save_unix": Time.get_unix_time_from_system(),
	}

func load_from_dict(data: Dictionary) -> void:
	gold = data.get("gold", 0.0)
	stress = data.get("stress", 0.0)
	diamond = data.get("diamond", 0.0)
	stage_index = data.get("stage_index", 0)
	mobs_defeated_in_stage = data.get("mobs_defeated_in_stage", 0)
	var eq: Dictionary = data.get("equipment_levels", {})
	for key in equipment_levels.keys():
		equipment_levels[key] = eq.get(key, 0)
	last_save_unix = data.get("last_save_unix", int(Time.get_unix_time_from_system()))
	recalculate_stats()
	currency_changed.emit()
	stage_changed.emit()
	equipment_changed.emit()
