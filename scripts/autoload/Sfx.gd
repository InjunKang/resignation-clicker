extends Node
## 절차적으로 합성한 짧은 효과음 재생 (Autoload 싱글톤: "Sfx")
## 외부 오디오 에셋 없이 코드에서 파형을 직접 생성한다.

const SAMPLE_RATE := 22050
const POOL_SIZE := 8

var enabled: bool = true

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _cache: Dictionary = {}

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func _next() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	return p

func _make_tone(freq_start: float, freq_end: float, duration: float, wave: String, volume: float) -> AudioStreamWAV:
	var n_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n_samples * 2) # 16비트 모노
	var attack_time: float = min(0.01, duration * 0.2)
	for i in n_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(max(n_samples - 1, 1))
		var freq: float = lerp(freq_start, freq_end, progress)
		var phase: float = TAU * freq * t
		var sample: float
		match wave:
			"square":
				sample = 1.0 if sin(phase) >= 0.0 else -1.0
			"triangle":
				sample = (2.0 / PI) * asin(sin(phase))
			_:
				sample = sin(phase)
		var env: float = 1.0
		if t < attack_time:
			env = t / attack_time
		else:
			env = 1.0 - progress
		sample *= env * volume
		var v: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

func _get_or_make(key: String, freq_start: float, freq_end: float, duration: float, wave: String, volume: float) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = _make_tone(freq_start, freq_end, duration, wave, volume)
	return _cache[key]

func _play(stream: AudioStreamWAV) -> void:
	if not enabled:
		return
	var p: AudioStreamPlayer = _next()
	p.stream = stream
	p.play()

func play_click() -> void:
	_play(_get_or_make("click", 700.0, 700.0, 0.03, "square", 0.10))

func play_crit() -> void:
	_play(_get_or_make("crit", 880.0, 1200.0, 0.12, "square", 0.16))

func play_upgrade() -> void:
	_play(_get_or_make("upgrade", 660.0, 990.0, 0.15, "sine", 0.18))

func play_gacha() -> void:
	_play(_get_or_make("gacha", 500.0, 1400.0, 0.25, "triangle", 0.18))

func play_boss_clear() -> void:
	_play(_get_or_make("boss_clear", 220.0, 440.0, 0.5, "triangle", 0.22))

func play_boss_fail() -> void:
	_play(_get_or_make("boss_fail", 300.0, 120.0, 0.3, "square", 0.14))

func play_tap() -> void:
	_play(_get_or_make("tap", 1000.0, 1600.0, 0.05, "triangle", 0.10))

func play_skill() -> void:
	_play(_get_or_make("skill", 500.0, 900.0, 0.18, "square", 0.16))
