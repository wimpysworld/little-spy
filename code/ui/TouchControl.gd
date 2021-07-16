extends Control


func _ready():
	self.visible = OS.has_touchscreen_ui_hint()


#func _unhandled_input(event: InputEvent):
#	if event is InputEventScreenTouch and OS.get_name() == "HTML5":
#		self.visible = true
