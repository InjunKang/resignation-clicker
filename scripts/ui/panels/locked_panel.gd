class_name LockedPanel
extends Control
## 준비 중인 기능(결사대/재테크/뽑기 등)을 위한 공용 잠금 표시 패널

var message: String = "준비 중입니다":
	set(value):
		message = value
		if _label:
			_label.text = value

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.text = message
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_label)
