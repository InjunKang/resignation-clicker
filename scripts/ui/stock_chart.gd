class_name StockChart
extends Control
## 재테크 탭에서 종목별 최근 가격 추이를 선 그래프로 그리는 미니 위젯.

var stock_id: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(0, 48)
	GameState.stock_changed.connect(func() -> void: queue_redraw())

func _draw() -> void:
	var history: Array = GameState.stock_price_history.get(stock_id, [])
	if history.size() < 2:
		return

	var min_v: float = history[0]
	var max_v: float = history[0]
	for v in history:
		min_v = min(min_v, v)
		max_v = max(max_v, v)
	if max_v - min_v < 0.001:
		max_v = min_v + 1.0

	var w: float = size.x
	var h: float = size.y
	var points := PackedVector2Array()
	for i in history.size():
		var x: float = w * (float(i) / float(history.size() - 1))
		var t: float = (history[i] - min_v) / (max_v - min_v)
		var y: float = h - t * h
		points.append(Vector2(x, y))

	var up: bool = history[history.size() - 1] >= history[0]
	var line_color: Color = Color(0.55, 0.85, 0.55) if up else Color(0.9, 0.45, 0.45)
	draw_polyline(points, line_color, 2.0, true)
