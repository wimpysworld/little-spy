extends Area2D
class_name Item

onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

export var points := 500

func _ready():
	$CollisionShape2D.set_deferred("disabled", false)
	$Sprite.scale.x = 1
	$Sprite.scale.y = 1
	$Sprite.rotation_degrees = 0.0

# The player has collided with the Item
func _on_body_entered(_body: PhysicsBody2D):
	collected()


# Play the Item fade_out animation and award points to the player
func collected():
	$CollisionShape2D.set_deferred("disabled", true)
	PlayerData.score += points
	PlayerData.items += 1
	anim_player.play("fade_out")
	yield(anim_player, "animation_finished")
	queue_free()
