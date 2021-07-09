extends Area2D
class_name PowerUp


func _on_PowerUp_body_entered(_body: Node):
	pass


func collect_powerup():
	$PowerUpSprite.visible = false
	$PowerUp.play()
	yield($PowerUp, "finished")
	queue_free()
