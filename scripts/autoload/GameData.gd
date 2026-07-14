extends Node
## 정적 게임 데이터 테이블 (Autoload 싱글톤: "GameData")
## 이 스크립트는 런타임 상태를 갖지 않는다. 상태는 GameState에서 관리한다.

const STAGE_COUNT := 10 # 회사당 서브스테이지 수 (1-1 ~ 1-10)
const MOBS_PER_STAGE := 10 # 보스 등장까지 처치해야 하는 몹 수
const BOSS_ATTACK_INTERVAL := 2.0

const BASE_ATK := 5.0
const BASE_HP := 50.0
const BASE_DEF := 0.0

# --- 회사(스테이지) ---

const COMPANIES := [
	{
		"name": "(주)까라면까 상사",
		"mobs": [
			{"id": "copier_jam", "name": "복사기 잼", "icon": "🖨️"},
			{"id": "coffee_thief", "name": "탕비실 커피 믹스 도둑", "icon": "☕"},
			{"id": "hwp_error", "name": "한글 파일 에러", "icon": "📄"},
		],
		"boss": {"id": "boss_1", "name": "낙하산 박낙하 대리", "icon": "🪂", "quote": "우리 아버지가 누군지 알아?", "time_limit": 20.0},
	},
	{
		"name": "꼰대 플래닛",
		"mobs": [
			{"id": "weekend_hike", "name": "주말 등산 강요", "icon": "⛰️"},
			{"id": "sudden_dinner", "name": "갑작스러운 회식", "icon": "🍻"},
			{"id": "messenger_jail", "name": "메신저 감옥", "icon": "📱"},
		],
		"boss": {"id": "boss_2", "name": "라떼는 과장", "icon": "☕", "quote": "나 때는 말이야, 야근이 기본이었어!", "time_limit": 22.0},
	},
	{
		"name": "네카라쿠배당토",
		"mobs": [
			{"id": "konglish_bot", "name": "영어 섞어 쓰기 봇", "icon": "🤖"},
			{"id": "tf_meeting", "name": "의미 없는 TF 팀 미팅", "icon": "📅"},
			{"id": "weekly_report", "name": "주간 보고서", "icon": "📊"},
		],
		"boss": {"id": "boss_3", "name": "트렌디 최부장", "icon": "🕶️", "quote": "As ASAP하게, 린(Lean)하게 얼라인(Align)해봐.", "time_limit": 25.0},
	},
]

func get_company_index(stage_index: int) -> int:
	return mini(int(stage_index / float(STAGE_COUNT)), COMPANIES.size() - 1)

func get_company(stage_index: int) -> Dictionary:
	return COMPANIES[get_company_index(stage_index)]

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

# --- 사내 비밀 결사대 (동료) ---
# unlock_stage: 이 값 이상 stage_index에 도달하면 자동 해금(글로벌 0-based 스테이지 인덱스)

const COMPANIONS := [
	{"id": "intern", "name": "눈치 빠른 인턴", "icon": "🙋", "unlock_stage": 4, "dps": 10.0, "desc": "김대리의 타자 속도 +5%"},
	{"id": "copier_tech", "name": "복사기 수리 기사", "icon": "🔧", "unlock_stage": 9, "dps": 85.0, "desc": "장비 강화 비용 3% 할인"},
	{"id": "peer", "name": "만년 대리 (동기)", "icon": "🥲", "unlock_stage": 10, "dps": 540.0, "desc": "오프라인 부업 수익 +10%"},
	{"id": "cleaner", "name": "만능 수수께끼 청소 이모님", "icon": "🧹", "unlock_stage": 20, "dps": 4200.0, "desc": "보스전 제한시간 +5초"},
	{"id": "whistleblower", "name": "내부 고발자 (인사과 대리)", "icon": "🕵️", "unlock_stage": 24, "dps": 36000.0, "desc": "월급루팡 대미지 +50%"},
]

# --- 액티브 스킬 (오토 발동) ---

const SKILLS := [
	{"id": "nep", "name": "넵! 알겠습니다", "icon": "🛡️", "cooldown": 30.0, "duration": 10.0, "unlock_stage": 0, "desc": "10초 무적 + 보스 공격 반사"},
	{"id": "coffee", "name": "커피 수혈", "icon": "☕", "cooldown": 45.0, "duration": 5.0, "unlock_stage": 9, "desc": "5초간 공격력 300%"},
	{"id": "blame", "name": "네 탓이오", "icon": "📑", "cooldown": 60.0, "duration": 0.0, "unlock_stage": 14, "desc": "적 최대 HP의 10% 고정 데미지"},
	{"id": "chopper", "name": "전무님 라인 타기", "icon": "🚁", "cooldown": 180.0, "duration": 20.0, "unlock_stage": 19, "desc": "광역 데미지 + 20초간 골드 2배"},
]

# --- 재테크(가짜 주식) ---

const STOCK_TICK_INTERVAL := 3.0
const STOCK_HISTORY_LENGTH := 30

const STOCKS := [
	{"id": "samsong", "name": "삼송전자", "icon": "📺", "base_price": 100.0, "volatility": 0.05, "crash_chance": 0.01},
	{"id": "bitcoinjok", "name": "비트코인족", "icon": "🪙", "base_price": 50.0, "volatility": 0.12, "crash_chance": 0.02},
]

# --- 뽑기(가챠) ---

const GACHA_COST_DIAMOND := 10
const GACHA_MIN_LEVELS := 1
const GACHA_MAX_LEVELS := 3
const GACHA_PITY_THRESHOLD := 10 # 이 횟수만큼 연속으로 최고 등급을 못 뽑으면 다음 뽑기는 확정
const BOSS_FIRST_CLEAR_DIAMOND_REWARD := 5.0

const GACHA_RARITY_NAMES := {1: "일반", 2: "희귀", 3: "전설"}

func get_gacha_rarity_name(levels: int) -> String:
	return GACHA_RARITY_NAMES.get(levels, "일반")

# --- 사직서 던지기 (프레스티지) ---

const PRESTIGE_UNLOCK_STAGE := 20

const PRESTIGE_UPGRADES := [
	{"id": "atk_boost", "name": "낙하산 인맥 (기본 공격력 +10%/스택)", "cost_base": 1.0, "cost_growth": 1.5},
	{"id": "offline_boost", "name": "부업 노하우 (오프라인 수익 +10%/스택)", "cost_base": 1.0, "cost_growth": 1.5},
]

func get_prestige_upgrade_cost(index: int, level: int) -> int:
	var u: Dictionary = PRESTIGE_UPGRADES[index]
	return int(ceil(u["cost_base"] * pow(u["cost_growth"], level)))

func get_prestige_reward(max_stage_reached: int) -> int:
	return int(max_stage_reached / 2)
