tool
extends LineEdit

var expression := Expression.new()
var a := 20

func _ready():
	print(self["a"])

func _on_LineEdit_text_entered(command) -> void:
	var error = expression.parse(command, [])
	if error != OK:
		print(expression.get_error_text())
		return
	var result = expression.execute([], self, true)
	if not expression.has_execute_failed():
		$LineEdit.text = str(result)

