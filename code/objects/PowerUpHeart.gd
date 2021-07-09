extends PowerUp


func _on_PowerUp_body_entered(_body: Node):
	PlayerData.health += 1
	collect_powerup()
