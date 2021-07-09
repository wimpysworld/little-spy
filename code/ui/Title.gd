extends HBoxContainer


func _ready():
	yield(get_tree().create_timer(PlayerData.title_delay), "timeout")
	$TitleAnimation.play("drop_in")
