class_name InvestPanel
extends Control
## "재테크" 탭: 가짜 주식 매수/매도. 매수는 항상 "그 시점 골드의 정해진 비율"만큼만
## 들어가서 예측 가능하고, 보유 중이면 손익률을 항상 보여준다.

var rows: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(vbox)

	for s in GameData.STOCKS:
		var id: String = s["id"]
		var block := VBoxContainer.new()
		vbox.add_child(block)

		var info_label := Label.new()
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		block.add_child(info_label)

		var profit_label := Label.new()
		profit_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		profit_label.add_theme_font_size_override("font_size", 16)
		block.add_child(profit_label)

		var row := HBoxContainer.new()
		block.add_child(row)

		var buy_half_btn := Button.new()
		buy_half_btn.text = "50% 매수"
		buy_half_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_half_btn.pressed.connect(func() -> void: _on_buy(id, 0.5))
		row.add_child(buy_half_btn)

		var buy_all_btn := Button.new()
		buy_all_btn.text = "전액 매수"
		buy_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_all_btn.pressed.connect(func() -> void: _on_buy(id, 1.0))
		row.add_child(buy_all_btn)

		var sell_btn := Button.new()
		sell_btn.text = "전량 매도"
		sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell_btn.pressed.connect(func() -> void: _on_sell(id))
		row.add_child(sell_btn)

		var chart := StockChart.new()
		chart.stock_id = id
		block.add_child(chart)

		rows[id] = {
			"info": info_label, "profit": profit_label,
			"buy_half": buy_half_btn, "buy_all": buy_all_btn, "sell": sell_btn,
		}

	GameState.stock_changed.connect(_refresh)
	GameState.currency_changed.connect(_refresh)
	_refresh()

func _on_buy(id: String, fraction: float) -> void:
	if GameState.buy_stock_fraction(id, fraction):
		Sfx.play_click()

func _on_sell(id: String) -> void:
	var proceeds: float = GameState.sell_stock(id)
	if proceeds > 0.0:
		Sfx.play_upgrade()

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

		var profit_label: Label = info["profit"]
		if shares > 0.0:
			var pct: float = GameState.get_stock_profit_percent(id)
			var sign_str: String = "+" if pct >= 0.0 else ""
			profit_label.text = "매수 원가 대비 손익률: %s%.1f%%" % [sign_str, pct]
			profit_label.add_theme_color_override("font_color", UiTheme.COLOR_GREEN if pct >= 0.0 else UiTheme.COLOR_RED)
		else:
			profit_label.text = "보유 중인 주식이 없습니다."
			profit_label.remove_theme_color_override("font_color")

		info["sell"].disabled = shares <= 0.0
		info["buy_half"].disabled = GameState.gold < 2.0
		info["buy_all"].disabled = GameState.gold < 2.0
