extends Node2D


export var level_name := "Template"


func _ready() -> void:
	PlayerData.time_limit = $UILayer/UI.time_limit
	PlayerData.items_to_find = $Items.get_child_count()
