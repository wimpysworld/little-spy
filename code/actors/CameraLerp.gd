extends Camera2D

export (NodePath) var TargetPath = null
export var lerp_speed := 0.05


var target = null


func _ready() -> void:
	target = get_node(TargetPath)


func _process(_delta):
	self.position = lerp(self.position, target.position, lerp_speed)
