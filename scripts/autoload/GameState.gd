extends Node
## 런타임 플레이어 상태 (Autoload 싱글톤: "GameState")

signal currency_changed
signal stats_changed
signal equipment_changed
signal stage_changed
signal stock_changed
signal prestiged

var gold: float = 0.0
var stress: float = 0.0
var diamond: float = 0.0

var stage_index: int = 0 # 0-based, 회사당 GameData.STAGE_COUNT개
var mobs_defeated_in_stage: int = 0

var equipment_levels: Dictionary = {
	"keyboard": 0,
	"chair": 0,
	"mouse": 0,
	"drink": 0,
}

# 회사(프레스티지 사이클)당 1회만 지급되는 보스 최초 처치 다이아 보상 추적
var boss_first_clear: Dictionary = {}

var gacha_pity: int = 0

# 재테크(가짜 주식): id -> 보유 수량(주)
var stock_shares: Dictionary = {}
# id -> 현재가 (세션마다 기준가로 재설정, 저장하지 않음)
var stock_prices: Dictionary = {}
# id -> 최근 가격 이력(차트용, 세션마다 재설정, 저장하지 않음)
var stock_price_history: Dictionary = {}
var _stock_tick_timer: float = 0.0

# 사직서 던지기(프레스티지) — 리셋되지 않는 영구 진행치
var prestige_currency: int = 0
var prestige_levels: Dictionary = {"atk_boost": 0, "offline_boost": 0}

# 업적용 평생 누적 스탯 — 사직서를 던져도 리셋되지 않음
var lifetime_max_stage_index: int = 0
var total_mob_kills: int = 0
var total_boss_kills: int = 0
var prestige_count: int = 0
var equipment_ever_maxed: bool = false
var achievements_claimed: Dictionary = {}

var last_save_unix: int = 0
var _passive_income_timer: float = 0.0

# 파생 스탯 (recalculate_stats에서 갱신)
var atk: float = 0.0
var max_hp: float = 0.0
var def: float = 0.0
var crit_chance: float = 0.0
var gold_rate_mult: float = 1.0

func _ready() -> void:
	_init_stock_prices()
	recalculate_stats()

func _process(delta: float) -> void:
	_stock_tick_timer += delta
	if _stock_tick_timer >= GameData.STOCK_TICK_INTERVAL:
		_stock_tick_timer -= GameData.STOCK_TICK_INTERVAL
		_tick_stock_market()

	_passive_income_timer += delta
	if _passive_income_timer >= 1.0:
		_passive_income_timer -= 1.0
		add_gold(get_estimated_gold_per_second() * GameData.PASSIVE_INCOME_RATIO)

func recalculate_stats() -> void:
	var kb_bonus: float = GameData.get_equipment_stat_bonus("keyboard", equipment_levels["keyboard"])
	var chair_bonus: float = GameData.get_equipment_stat_bonus("chair", equipment_levels["chair"])
	var mouse_bonus: float = GameData.get_equipment_stat_bonus("mouse", equipment_levels["mouse"])
	var drink_bonus: float = GameData.get_equipment_stat_bonus("drink", equipment_levels["drink"])

	atk = GameData.BASE_ATK * kb_bonus * get_atk_multiplier_bonus()
	max_hp = GameData.BASE_HP * chair_bonus
	crit_chance = clamp(0.05 * mouse_bonus, 0.0, 0.75)
	gold_rate_mult = drink_bonus
	def = GameData.BASE_DEF + equipment_levels["chair"] * 0.2

	stats_changed.emit()

# --- 재화 ---

func add_gold(amount: float) -> void:
	gold += amount * gold_rate_mult
	currency_changed.emit()

## 이미 배율이 반영된 금액을 그대로 더할 때 사용 (예: 오프라인 보상, 주식 매도 차익)
func add_gold_raw(amount: float) -> void:
	gold += amount
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

func add_diamond(amount: float) -> void:
	diamond += amount
	currency_changed.emit()

# --- 장비 ---

func get_equip_cost(slot: String, level: int) -> float:
	return GameData.get_equipment_upgrade_cost(slot, level) * get_equip_cost_multiplier()

func upgrade_equipment(slot: String) -> bool:
	var level: int = equipment_levels[slot]
	var cost: float = get_equip_cost(slot, level)
	if not spend_gold(cost):
		return false
	equipment_levels[slot] = level + 1
	if equipment_levels[slot] >= GameData.get_equipment_legendary_level(slot):
		equipment_ever_maxed = true
	recalculate_stats()
	equipment_changed.emit()
	return true

## 한 슬롯에 대해 살 수 있는 만큼 한 번에 강화한다. 실제로 오른 레벨 수를 반환.
func upgrade_equipment_max(slot: String) -> int:
	var level: int = equipment_levels[slot]
	var count: int = 0
	var remaining: float = gold
	while true:
		var cost: float = get_equip_cost(slot, level + count)
		if remaining < cost:
			break
		remaining -= cost
		count += 1
	if count <= 0:
		return 0
	gold = remaining
	equipment_levels[slot] = level + count
	if equipment_levels[slot] >= GameData.get_equipment_legendary_level(slot):
		equipment_ever_maxed = true
	recalculate_stats()
	currency_changed.emit()
	equipment_changed.emit()
	return count

## 4개 슬롯 전체에 걸쳐 항상 가장 싼 슬롯부터 살 수 있는 만큼 강화한다.
func upgrade_all_equipment_max() -> int:
	var total: int = 0
	var remaining: float = gold
	var progressed: bool = true
	while progressed:
		progressed = false
		var best_slot: String = ""
		var best_cost: float = INF
		for slot in equipment_levels.keys():
			var cost: float = get_equip_cost(slot, equipment_levels[slot])
			if cost < best_cost:
				best_cost = cost
				best_slot = slot
		if best_slot != "" and remaining >= best_cost:
			remaining -= best_cost
			equipment_levels[best_slot] += 1
			if equipment_levels[best_slot] >= GameData.get_equipment_legendary_level(best_slot):
				equipment_ever_maxed = true
			total += 1
			progressed = true
	if total <= 0:
		return 0
	gold = remaining
	recalculate_stats()
	currency_changed.emit()
	equipment_changed.emit()
	return total

# --- 스테이지 진행 ---

func advance_stage() -> void:
	stage_index += 1
	mobs_defeated_in_stage = 0
	lifetime_max_stage_index = maxi(lifetime_max_stage_index, stage_index)
	stage_changed.emit()

func register_mob_kill() -> void:
	mobs_defeated_in_stage += 1
	total_mob_kills += 1

func register_boss_kill() -> void:
	total_boss_kills += 1

func is_boss_stage() -> bool:
	return mobs_defeated_in_stage >= GameData.MOBS_PER_STAGE

## 회사별 보스 최초 처치 여부 등록. 최초 처치면 true 반환(다이아 보상 지급 트리거용)
func register_boss_first_clear(company_index: int) -> bool:
	if boss_first_clear.get(company_index, false):
		return false
	boss_first_clear[company_index] = true
	return true

## 오프라인 보상 추정치 계산에 사용 (초당 골드 생산량 근사치, 드링크 배율 포함)
func get_estimated_gold_per_second() -> float:
	var mob_hp: float = GameData.get_mob_hp(stage_index)
	var mob_gold: float = GameData.get_mob_gold_reward(stage_index)
	var kills_per_second: float = (atk + get_companion_dps()) / max(mob_hp, 1.0)
	return kills_per_second * mob_gold * gold_rate_mult

# --- 사내 비밀 결사대 (동료) ---

func _companion(id: String) -> Dictionary:
	for c in GameData.COMPANIONS:
		if c["id"] == id:
			return c
	return {}

func is_companion_active(id: String) -> bool:
	var c: Dictionary = _companion(id)
	return not c.is_empty() and stage_index >= c["unlock_stage"]

func get_companion_dps() -> float:
	var total := 0.0
	for c in GameData.COMPANIONS:
		if stage_index >= c["unlock_stage"]:
			total += c["dps"]
	return total

func get_atk_multiplier_bonus() -> float:
	var m := 1.0
	if is_companion_active("intern"):
		m *= 1.05
	m *= (1.0 + prestige_levels.get("atk_boost", 0) * 0.10)
	return m

func get_equip_cost_multiplier() -> float:
	return 0.97 if is_companion_active("copier_tech") else 1.0

func get_offline_bonus_multiplier() -> float:
	var m := 1.0
	if is_companion_active("peer"):
		m *= 1.10
	m *= (1.0 + prestige_levels.get("offline_boost", 0) * 0.10)
	return m

func get_boss_time_bonus() -> float:
	return 5.0 if is_companion_active("cleaner") else 0.0

func get_crit_multiplier() -> float:
	return 7.5 if is_companion_active("whistleblower") else 5.0

# --- 재테크(가짜 주식) ---

func _init_stock_prices() -> void:
	for s in GameData.STOCKS:
		var id: String = s["id"]
		stock_prices[id] = s["base_price"]
		stock_price_history[id] = [s["base_price"]]
		if not stock_shares.has(id):
			stock_shares[id] = 0.0

func _tick_stock_market() -> void:
	for s in GameData.STOCKS:
		var id: String = s["id"]
		if randf() < s["crash_chance"]:
			stock_prices[id] = s["base_price"] * 0.05
		else:
			var change: float = 1.0 + randf_range(-s["volatility"], s["volatility"])
			stock_prices[id] = max(stock_prices[id] * change, s["base_price"] * 0.02)
		var history: Array = stock_price_history[id]
		history.append(stock_prices[id])
		if history.size() > GameData.STOCK_HISTORY_LENGTH:
			history.pop_front()
	stock_changed.emit()

func buy_stock(id: String, amount: float) -> bool:
	if amount <= 0.0 or not spend_gold(amount):
		return false
	var price: float = stock_prices.get(id, 1.0)
	stock_shares[id] = stock_shares.get(id, 0.0) + amount / max(price, 0.0001)
	stock_changed.emit()
	return true

func sell_stock(id: String) -> float:
	var shares: float = stock_shares.get(id, 0.0)
	if shares <= 0.0:
		return 0.0
	var proceeds: float = shares * stock_prices.get(id, 0.0)
	stock_shares[id] = 0.0
	add_gold_raw(proceeds)
	stock_changed.emit()
	return proceeds

# --- 뽑기(가챠) ---

func do_gacha() -> Dictionary:
	if diamond < GameData.GACHA_COST_DIAMOND:
		return {"success": false}
	diamond -= GameData.GACHA_COST_DIAMOND
	var slots: Array = GameData.EQUIPMENT.keys()
	var slot: String = slots[randi() % slots.size()]

	var levels: int
	if gacha_pity >= GameData.GACHA_PITY_THRESHOLD - 1:
		levels = GameData.GACHA_MAX_LEVELS
	else:
		levels = randi_range(GameData.GACHA_MIN_LEVELS, GameData.GACHA_MAX_LEVELS)
	gacha_pity = 0 if levels >= GameData.GACHA_MAX_LEVELS else gacha_pity + 1

	var new_level: int = equipment_levels[slot] + levels
	equipment_levels[slot] = new_level
	if new_level >= GameData.get_equipment_legendary_level(slot):
		equipment_ever_maxed = true
	recalculate_stats()
	currency_changed.emit()
	equipment_changed.emit()
	return {
		"success": true,
		"slot": slot,
		"levels": levels,
		"rarity": GameData.get_gacha_rarity_name(levels),
	}

# --- 사직서 던지기 (프레스티지) ---

func can_prestige() -> bool:
	return stage_index >= GameData.PRESTIGE_UNLOCK_STAGE

func do_prestige() -> int:
	var reward: int = GameData.get_prestige_reward(stage_index)
	prestige_currency += reward
	prestige_count += 1

	gold = 0.0
	stress = 0.0
	diamond = 0.0
	stage_index = 0
	mobs_defeated_in_stage = 0
	equipment_levels = {"keyboard": 0, "chair": 0, "mouse": 0, "drink": 0}
	boss_first_clear = {}
	stock_shares = {}
	_init_stock_prices()

	recalculate_stats()
	currency_changed.emit()
	stage_changed.emit()
	equipment_changed.emit()
	stock_changed.emit()
	prestiged.emit()
	return reward

func buy_prestige_upgrade(id: String) -> bool:
	var idx: int = -1
	for i in GameData.PRESTIGE_UPGRADES.size():
		if GameData.PRESTIGE_UPGRADES[i]["id"] == id:
			idx = i
			break
	if idx < 0:
		return false
	var level: int = prestige_levels.get(id, 0)
	var cost: int = GameData.get_prestige_upgrade_cost(idx, level)
	if prestige_currency < cost:
		return false
	prestige_currency -= cost
	prestige_levels[id] = level + 1
	recalculate_stats()
	currency_changed.emit()
	return true

# --- 업적 ---

func get_achievement_progress(a: Dictionary) -> float:
	match a["type"]:
		"stage":
			return 1.0 if lifetime_max_stage_index >= a["value"] else 0.0
		"mob_kills":
			return clamp(float(total_mob_kills) / a["value"], 0.0, 1.0)
		"boss_kills":
			return clamp(float(total_boss_kills) / a["value"], 0.0, 1.0)
		"prestige_count":
			return clamp(float(prestige_count) / a["value"], 0.0, 1.0)
		"equipment_maxed":
			return 1.0 if equipment_ever_maxed else 0.0
	return 0.0

func is_achievement_complete(a: Dictionary) -> bool:
	return get_achievement_progress(a) >= 1.0

func is_achievement_claimed(id: String) -> bool:
	return achievements_claimed.get(id, false)

func claim_achievement(id: String) -> bool:
	if is_achievement_claimed(id):
		return false
	for a in GameData.ACHIEVEMENTS:
		if a["id"] == id:
			if not is_achievement_complete(a):
				return false
			achievements_claimed[id] = true
			add_diamond(a["reward"])
			return true
	return false

# --- 저장/불러오기 ---

func to_save_dict() -> Dictionary:
	return {
		"gold": gold,
		"stress": stress,
		"diamond": diamond,
		"stage_index": stage_index,
		"mobs_defeated_in_stage": mobs_defeated_in_stage,
		"equipment_levels": equipment_levels.duplicate(),
		"boss_first_clear": boss_first_clear.duplicate(),
		"gacha_pity": gacha_pity,
		"stock_shares": stock_shares.duplicate(),
		"prestige_currency": prestige_currency,
		"prestige_levels": prestige_levels.duplicate(),
		"lifetime_max_stage_index": lifetime_max_stage_index,
		"total_mob_kills": total_mob_kills,
		"total_boss_kills": total_boss_kills,
		"prestige_count": prestige_count,
		"equipment_ever_maxed": equipment_ever_maxed,
		"achievements_claimed": achievements_claimed.duplicate(),
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
	boss_first_clear = data.get("boss_first_clear", {})
	gacha_pity = data.get("gacha_pity", 0)
	var shares: Dictionary = data.get("stock_shares", {})
	for s in GameData.STOCKS:
		var id: String = s["id"]
		stock_shares[id] = shares.get(id, 0.0)
	prestige_currency = data.get("prestige_currency", 0)
	var levels: Dictionary = data.get("prestige_levels", {})
	for key in prestige_levels.keys():
		prestige_levels[key] = levels.get(key, 0)
	lifetime_max_stage_index = data.get("lifetime_max_stage_index", stage_index)
	total_mob_kills = data.get("total_mob_kills", 0)
	total_boss_kills = data.get("total_boss_kills", 0)
	prestige_count = data.get("prestige_count", 0)
	equipment_ever_maxed = data.get("equipment_ever_maxed", false)
	achievements_claimed = data.get("achievements_claimed", {})
	last_save_unix = data.get("last_save_unix", int(Time.get_unix_time_from_system()))
	recalculate_stats()
	currency_changed.emit()
	stage_changed.emit()
	equipment_changed.emit()
	stock_changed.emit()
