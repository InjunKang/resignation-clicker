class_name Fmt
extends RefCounted
## 숫자 표시 포맷 유틸 (예: 12345 -> "12.35K")

static func short(n: float) -> String:
	var sign_str: String = "-" if n < 0 else ""
	n = abs(n)
	if n < 1000.0:
		return sign_str + str(int(n))
	var units := ["", "K", "M", "B", "T"]
	var idx := 0
	while n >= 1000.0 and idx < units.size() - 1:
		n /= 1000.0
		idx += 1
	return "%s%.2f%s" % [sign_str, n, units[idx]]
