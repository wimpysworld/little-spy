extends Control


func _ready():
	$Results/Status.text = "Final Score: %s" % PlayerData.pad_score()
	$MissionAccomplished.play()
	yield($MissionAccomplished, "finished")
	get_tree().change_scene("res://code/MainScreen.tscn")


func _input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene("res://code/MainScreen.tscn")
	elif Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
