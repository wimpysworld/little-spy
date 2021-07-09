tool
extends Area2D


onready var anim_helicopter: AnimationPlayer = $Helicopter/HelicopterAnimation
onready var anim_tansition: AnimationPlayer = $TransitionAnimation


export var points := 1000
export var next_scene: PackedScene


func _on_body_entered(_body: PhysicsBody2D):
	if PlayerData.items >= 1:
		PlayerData.score += points
		PlayerData.level_complete = true
		_body.visible = false
		fly_helicopter()
	else:
		$NoEntry.play()


func _get_configuration_warning() -> String:
	return "The next_scene property must be defined" if not next_scene else ""


func _ready():
	reset_helicopter()


func fly_helicopter(skip_animation: bool = false):
	get_tree().call_group("enemies", "queue_free")

	if not skip_animation:
		anim_helicopter.play("spin_up")
		yield(anim_helicopter, "animation_finished")

		anim_helicopter.play("lift_off")
		yield(anim_helicopter, "animation_finished")

	anim_tansition.play("fade_out")
	yield(anim_tansition, "animation_finished")
	PlayerData.new_level()
	if not next_scene:
		get_tree().change_scene("res://code/ui/EndScreen.tscn")
	else:
		get_tree().change_scene_to(next_scene)


func reset_helicopter():
	$Helicopter.play("helicopter", false)
	$Helicopter.frame = 0
	$Helicopter.speed_scale = 0
	$Helicopter.offset = Vector2.ZERO
	$Helicopter.rotation_degrees = 0.0
