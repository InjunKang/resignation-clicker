class_name BattleView
extends Control
## 전투 화면: 몹/보스 vs 김대리. 코어 루프(자동 공격, 보스전, 결사대 DPS,
## 액티브 스킬 오토캐스트, 탭 미니게임)를 담당한다.

const ATTACK_ROLL_INTERVAL := 1.0

var enemy_hp: float = 0.0
var enemy_max_hp: float = 0.0
var enemy_name: String = ""
var enemy_icon: String = ""
var is_boss: bool = false
var boss_time_left: float = 0.0
var _boss_data: Dictionary = {}

var player_hp: float = 0.0

var _attack_timer: float = 0.0
var _boss_attack_timer: float = 0.0

var _skills: Array = []

var enemy_name_label: Label
var enemy_hp_bar: ProgressBar
var enemy_icon_label: Label
var player_hp_bar: ProgressBar
var boss_timer_label: Label
var log_label: Label
var skill_status_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(0, 360)
	_build_ui()
	for s in GameData.SKILLS:
		_skills.append({"data": s, "cd": 0.0, "active": 0.0})
	GameState.stats_changed.connect(_on_stats_changed)
	player_hp = GameState.max_hp
	_spawn_next_enemy()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_vbox)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(hbox)

	var enemy_box := VBoxContainer.new()
	enemy_box.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(enemy_box)

	enemy_icon_label = Label.new()
	enemy_icon_label.add_theme_font_size_override("font_size", 48)
	enemy_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_box.add_child(enemy_icon_label)

	enemy_name_label = Label.new()
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_box.add_child(enemy_name_label)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.show_percentage = false
	enemy_box.add_child(enemy_hp_bar)

	boss_timer_label = Label.new()
	boss_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_timer_label.visible = false
	enemy_box.add_child(boss_timer_label)

	var vs_label := Label.new()
	vs_label.text = "⚔️"
	vs_label.add_theme_font_size_override("font_size", 36)
	hbox.add_child(vs_label)

	var player_box := VBoxContainer.new()
	player_box.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(player_box)

	var player_icon_label := Label.new()
	player_icon_label.text = "🧑‍💼"
	player_icon_label.add_theme_font_size_override("font_size", 48)
	player_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_box.add_child(player_icon_label)

	var player_name_label := Label.new()
	player_name_label.text = "김대리"
	player_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_box.add_child(player_name_label)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.show_percentage = false
	player_box.add_child(player_hp_bar)

	log_label = Label.new()
	log_label.text = "자동으로 업무를 처리하는 중..."
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(log_label)

	skill_status_label = Label.new()
	skill_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_status_label.add_theme_font_size_override("font_size", 12)
	root_vbox.add_child(skill_status_label)

	var tap_button := Button.new()
	tap_button.flat = true
	tap_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_button.focus_mode = Control.FOCUS_NONE
	tap_button.pressed.connect(_on_tap)
	add_child(tap_button)

func _process(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= ATTACK_ROLL_INTERVAL:
		_attack_timer -= ATTACK_ROLL_INTERVAL
		_player_attack_tick()

	if is_boss:
		boss_time_left -= delta
		boss_timer_label.text = "남은 시간: %d초" % maxi(int(ceil(boss_time_left)), 0)
		_boss_attack_timer += delta
		if _boss_attack_timer >= GameData.BOSS_ATTACK_INTERVAL:
			_boss_attack_timer -= GameData.BOSS_ATTACK_INTERVAL
			_boss_attack_tick()
		if boss_time_left <= 0.0 or player_hp <= 0.0:
			_on_boss_fail()

	_update_skills(delta)
	_refresh_bars()
	_refresh_skill_status()

func _spawn_next_enemy() -> void:
	if GameState.is_boss_stage():
		_spawn_boss()
	else:
		_spawn_mob()

func _spawn_mob() -> void:
	is_boss = false
	boss_timer_label.visible = false
	var company: Dictionary = GameData.get_company(GameState.stage_index)
	var mobs: Array = company["mobs"]
	var mob: Dictionary = mobs[GameState.mobs_defeated_in_stage % mobs.size()]
	enemy_name = mob["name"]
	enemy_icon = mob["icon"]
	enemy_max_hp = GameData.get_mob_hp(GameState.stage_index)
	enemy_hp = enemy_max_hp
	_refresh_bars()

func _spawn_boss() -> void:
	is_boss = true
	boss_timer_label.visible = true
	_boss_attack_timer = 0.0
	var company: Dictionary = GameData.get_company(GameState.stage_index)
	_boss_data = company["boss"]
	enemy_name = _boss_data["name"]
	enemy_icon = _boss_data["icon"]
	enemy_max_hp = GameData.get_boss_hp(GameState.stage_index)
	enemy_hp = enemy_max_hp
	boss_time_left = _boss_data["time_limit"] + GameState.get_boss_time_bonus()
	log_label.text = "%s: \"%s\"" % [enemy_name, _boss_data["quote"]]
	_refresh_bars()

func _refresh_bars() -> void:
	enemy_icon_label.text = enemy_icon
	enemy_name_label.text = enemy_name
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	player_hp_bar.max_value = GameState.max_hp
	player_hp_bar.value = player_hp

func _refresh_skill_status() -> void:
	var parts: Array = []
	for sk in _skills:
		var data: Dictionary = sk["data"]
		if GameState.stage_index < data["unlock_stage"]:
			continue
		var cd: float = sk["cd"]
		var status: String = "준비" if cd <= 0.0 else "%ds" % int(ceil(cd))
		parts.append("%s %s" % [data["icon"], status])
	skill_status_label.text = "  ".join(parts)

# --- 전투 ---

func _gold_multiplier() -> float:
	return 2.0 if _skill_active("chopper") else 1.0

func _player_attack_tick() -> void:
	var dmg: float = GameState.atk * ATTACK_ROLL_INTERVAL
	if _skill_active("coffee"):
		dmg *= 3.0
	var crit: bool = randf() < GameState.crit_chance
	if crit:
		dmg *= GameState.get_crit_multiplier()
		GameState.add_stress(2.0 + GameState.stage_index)
		log_label.text = "월급루팡! 대박 효율!"
	dmg += GameState.get_companion_dps() * ATTACK_ROLL_INTERVAL
	enemy_hp -= dmg
	_check_enemy_death()

func _check_enemy_death() -> void:
	if enemy_hp <= 0.0:
		if is_boss:
			_on_boss_defeated()
		else:
			_on_mob_defeated()

func _on_mob_defeated() -> void:
	GameState.add_gold(GameData.get_mob_gold_reward(GameState.stage_index) * _gold_multiplier())
	GameState.register_mob_kill()
	_spawn_next_enemy()

func _on_boss_defeated() -> void:
	var company_index: int = GameData.get_company_index(GameState.stage_index)
	GameState.add_gold(GameData.get_boss_gold_reward(GameState.stage_index) * _gold_multiplier())
	GameState.add_stress(GameData.get_boss_stress_reward(GameState.stage_index))
	if GameState.register_boss_first_clear(company_index):
		GameState.add_diamond(GameData.BOSS_FIRST_CLEAR_DIAMOND_REWARD)
		log_label.text = "%s 격파! 첫 클리어 보너스 법인카드 +%d" % [_boss_data.get("name", ""), int(GameData.BOSS_FIRST_CLEAR_DIAMOND_REWARD)]
	else:
		log_label.text = "%s 격파! 다음 스테이지로." % _boss_data.get("name", "")
	GameState.advance_stage()
	player_hp = GameState.max_hp
	_spawn_next_enemy()

func _boss_attack_tick() -> void:
	var boss_atk: float = GameData.get_boss_atk(GameState.stage_index)
	if _skill_active("nep"):
		enemy_hp -= boss_atk
		_check_enemy_death()
		return
	var dmg: float = max(1.0, boss_atk - GameState.def)
	player_hp = max(0.0, player_hp - dmg)

func _on_boss_fail() -> void:
	log_label.text = "멘탈이 나갔다... 다시 도전!"
	player_hp = GameState.max_hp
	enemy_hp = enemy_max_hp
	boss_time_left = _boss_data.get("time_limit", 20.0) + GameState.get_boss_time_bonus()
	_boss_attack_timer = 0.0

func _on_tap() -> void:
	GameState.add_stress(1.0)
	log_label.text = "화장실에서 폰게임... 스트레스 해소 +1"

func _on_stats_changed() -> void:
	player_hp = min(player_hp, GameState.max_hp)
	if player_hp <= 0.0:
		player_hp = GameState.max_hp

# --- 액티브 스킬 (오토캐스트) ---

func _skill_active(id: String) -> bool:
	for sk in _skills:
		if sk["data"]["id"] == id:
			return sk["active"] > 0.0
	return false

func _update_skills(delta: float) -> void:
	for sk in _skills:
		var data: Dictionary = sk["data"]
		if GameState.stage_index < data["unlock_stage"]:
			continue
		if sk["active"] > 0.0:
			sk["active"] = max(0.0, sk["active"] - delta)
		if sk["cd"] > 0.0:
			sk["cd"] = max(0.0, sk["cd"] - delta)
		if sk["cd"] <= 0.0 and sk["active"] <= 0.0:
			_cast_skill(data["id"])
			sk["cd"] = data["cooldown"]
			sk["active"] = data["duration"]

func _cast_skill(id: String) -> void:
	match id:
		"blame":
			enemy_hp -= enemy_max_hp * 0.10
			log_label.text = "네 탓이오! %s 탓이야!" % enemy_name
			_check_enemy_death()
		"chopper":
			enemy_hp -= enemy_max_hp * 0.20
			log_label.text = "전무님이 헬기 타고 등장! 대가리 박아!"
			_check_enemy_death()
		# "nep", "coffee"는 지속시간(active) 동안의 상태 플래그로만 동작 (즉발 효과 없음)
