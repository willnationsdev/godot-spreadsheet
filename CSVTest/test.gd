extends Reference
class_name Utility

const data := {}

static func init() -> void:
	print(data)
	data.my_field = get_str()
	print(data)

static func get_str() -> String:
	return "my_text"
