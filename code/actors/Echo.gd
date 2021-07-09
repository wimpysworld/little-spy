extends Sprite


func _ready():
	# Module from solid to completely alpha transparent.
	$AlphaTween.interpolate_property(self, "modulate", Color(1,1,1,1), Color(1,1,1,0), 0.75, Tween.TRANS_BACK, Tween.EASE_OUT)
	$AlphaTween.start()


func _on_AlphaTween_tween_completed(_object: Object, _key: NodePath):
	queue_free()
