class_name InvestPanel
extends Control
## "재테크" 탭: 가짜 주식 매수/매도

var rows: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	for s in GameData.STOCKS:
		var id: String = s["id"]
		var block := VBoxContainer.new()
		vbox.add_child(block)

		var row := HBoxContainer.new()
		block.add_child(row)

		var info_label := Label.new()
		info_label.custom_minimum_size = Vector2(380, 0)
		row.add_child(info_label)

		var buy_btn := Button.new()
		buy_btn.text = "매수"
		buy_btn.pressed.connect(func() -> void: _on_buy(id))
		row.add_child(buy_btn)

		var sell_btn := Button.new()
		sell_btn.text = "매도"
		sell_btn.pressed.connect(func() -> void: GameState.sell_stock(id))
		row.add_child(sell_btn)

		var chart := StockChart.new()
		chart.stock_id = id
		block.add_child(chart)

		rows[id] = {"info": info_label, "buy": buy_btn, "sell": sell_btn}

	GameState.stock_changed.connect(_refresh)
	GameState.currency_changed.connect(_refresh)
	_refresh()

func _on_buy(id: String) -> void:
	var amount: float = max(10.0, floor(GameState.gold * 0.1))
	GameState.buy_stock(id, min(amount, GameState.gold))

func _refresh() -> void:
	for s in GameData.STOCKS:
		var id: String = s["id"]
		var price: float = GameState.stock_prices.get(id, s["base_price"])
		var shares: float = GameState.stock_shares.get(id, 0.0)
		var value: float = shares * price
		var crashed: bool = price <= s["base_price"] * 0.06
		var info: Dictionary = rows[id]
		var status: String = " (상장폐지 위기!)" if crashed else ""
		info["info"].text = "%s %s\n현재가 💰%s%s   보유가치 💰%s" % [s["icon"], s["name"], Fmt.short(price), status, Fmt.short(value)]
		info["sell"].disabled = shares <= 0.0
		info["buy"].disabled = GameState.gold < 10.0
