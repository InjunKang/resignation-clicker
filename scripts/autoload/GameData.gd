extends Node
## 정적 게임 데이터 테이블 (Autoload 싱글톤: "GameData")
## 이 스크립트는 런타임 상태를 갖지 않는다. 상태는 GameState에서 관리한다.

const MOBS := [
	{"id": "copier_jam", "name": "복사기 잼", "icon": "🖨️"},
	{"id": "coffee_thief", "name": "탕비실 커피 믹스 도둑", "icon": "☕"},
	{"id": "hwp_error", "name": "한글 파일 에러", "icon": "📄"},
]

const BOSS := {
	"id": "boss_1_10",
	"name": "낙하산 박낙하 대리",
	"icon": "🪂",
	"quote": "우리 아버지가 누군지 알아?",
	"time_limit": 20.0,
}

const STAGE_NAME := "(주)까라면까 상사"
const STAGE_COUNT := 10 # 스테이지 1-1 ~ 1-10 (Phase 1 범위)
const MOBS_PER_STAGE := 10
const BOSS_ATTACK_INTERVAL := 2.0

const BASE_ATK := 5.0
const BASE_HP := 50.0
const BASE_DEF := 0.0

# --- 성장 곡선 ---

func get_mob_hp(stage_index: int) -> float:
	return 20.0 * pow(1.18, stage_index)

func get_mob_gold_reward(stage_index: int) -> float:
	return 5.0 * pow(1.15, stage_index)

func get_boss_hp(stage_index: int) -> float:
	return get_mob_hp(stage_index) * MOBS_PER_STAGE * 3.0

func get_boss_gold_reward(stage_index: int) -> float:
	return get_mob_gold_reward(stage_index) * MOBS_PER_STAGE * 5.0

func get_boss_stress_reward(stage_index: int) -> float:
	return 10.0 + stage_index * 5.0

func get_boss_atk(stage_index: int) -> float:
	return 3.0 + stage_index * 1.5

# --- 장비 ---

const LEVELS_PER_TIER := 10

const EQUIPMENT := {
	"keyboard": {
		"label": "키보드",
		"tiers": [
			{"name": "멤브레인", "icon": "⌨️", "base": 1.0},
			{"name": "기계식 적축", "icon": "⌨️", "base": 1.6},
			{"name": "커스텀 RGB", "icon": "⌨️", "base": 2.6},
			{"name": "[전설] 광선 키보드", "icon": "⌨️✨", "base": 4.5},
		],
	},
	"chair": {
		"label": "의자",
		"tiers": [
			{"name": "플라스틱 의자", "icon": "🪑", "base": 1.0},
			{"name": "매시 의자", "icon": "🪑", "base": 1.6},
			{"name": "게이밍 의자", "icon": "🪑", "base": 2.6},
			{"name": "[전설] 회장님 중역 의자", "icon": "🪑✨", "base": 4.5},
		],
	},
	"mouse": {
		"label": "마우스",
		"tiers": [
			{"name": "볼 마우스", "icon": "🖱️", "base": 1.0},
			{"name": "버티컬 인체공학 마우스", "icon": "🖱️", "base": 1.5},
			{"name": "무소음 마우스", "icon": "🖱️", "base": 2.2},
			{"name": "[전설] 황금 마우스", "icon": "🖱️✨", "base": 3.5},
		],
	},
	"drink": {
		"label": "드링크",
		"tiers": [
			{"name": "믹스커피", "icon": "☕", "base": 1.0},
			{"name": "아이스 아메리카노 메가사이즈", "icon": "🧊", "base": 1.6},
			{"name": "에너지 드링크", "icon": "⚡", "base": 2.4},
			{"name": "[전설] 산삼 엑기스", "icon": "🌿✨", "base": 4.0},
		],
	},
}

func get_equipment_upgrade_cost(_slot: String, level: int) -> float:
	return 10.0 * pow(1.12, level)

func get_equipment_tier_index(level: int) -> int:
	return mini(int(level / float(LEVELS_PER_TIER)), 3)

func get_equipment_stat_bonus(slot: String, level: int) -> float:
	var tier_index: int = get_equipment_tier_index(level)
	var tier_base: float = EQUIPMENT[slot]["tiers"][tier_index]["base"]
	var level_in_tier: int = level % LEVELS_PER_TIER
	return tier_base * (1.0 + level_in_tier * 0.08)

func get_equipment_max_level(slot: String) -> int:
	return LEVELS_PER_TIER * EQUIPMENT[slot]["tiers"].size() - 1
