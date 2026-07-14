extends Node
## 저장/불러오기 + 오프라인 보상 (Autoload 싱글톤: "SaveManager")

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL := 30.0
const MAX_OFFLINE_SECONDS := 8.0 * 3600.0
const OFFLINE_EFFICIENCY := 0.5 # 오프라인은 접속 대비 50% 효율

var _autosave_timer: float = 0.0

func _ready() -> void:
	load_game()
	_apply_offline_progress()
	if get_tree() and get_tree().root:
		get_tree().root.close_requested.connect(_on_close_requested)

func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

func _on_close_requested() -> void:
	save_game()
	get_tree().quit()

func save_game() -> void:
	var data: Dictionary = GameState.to_save_dict()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		GameState.load_from_dict(parsed)

func _apply_offline_progress() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var last: int = GameState.last_save_unix
	if last <= 0:
		GameState.last_save_unix = now
		return
	var elapsed: float = clamp(float(now - last), 0.0, MAX_OFFLINE_SECONDS)
	if elapsed < 5.0:
		GameState.last_save_unix = now
		return
	var rate: float = GameState.get_estimated_gold_per_second()
	var reward: float = rate * elapsed * OFFLINE_EFFICIENCY
	if reward > 0.0:
		GameState.add_gold(reward)
	GameState.last_save_unix = now
