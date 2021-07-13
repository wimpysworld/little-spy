extends "res://code/actors/Actor.gd"


onready var stomp_area: Area2D = $StompArea2D


export var initial_direction := LEFT


func _ready():
	var rng = RandomNumberGenerator.new()
	# Does this enemy detect voids?
	$Actor/PlatformChecker.enabled = detect_voids
	direction.x = initial_direction
	get_directional_extents()

	# As enemies appear on screen, for the first time, randomly delay spawning
	deactivate_enemy()
	rng.randomize()
	_spawn_delay = rng.randf_range(0.5, 2.5)


func _on_ImpactLeft_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack") and not _in_shock:
		enemy_attacked(RIGHT)


func _on_ImpactRight_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack") and not _in_shock:
		enemy_attacked(LEFT)


func _on_StompArea2D_area_entered(area: Area2D) -> void:
	if area.global_position.y < stomp_area.global_position.y and area.is_in_group("stomp"):
		enemy_stomped()


func _physics_process(delta: float):
	if _spawned:
		move(delta)
		friction()
		gravity(delta)


func _process(_delta: float) -> void:
	spawn()


func move(_delta: float):
	if not _in_shock:
		if _chute_deployed:
			direction.x = IDLE
		elif direction.x == IDLE and is_on_floor():
			direction.x = initial_direction

		# TODO: Fix enemy collisions with hazards
		#var hit_collider = $Actor/PlatformChecker.get_collider()
		#if hit_collider is TileMap:
		#	if hit_collider.is_in_group("danger"):
		#		print("danger")

		# This didn't work either, but works for the player?!
		#var collision = move_and_collide(velocity * delta, true, true, true)
		#if collision:
		#	# Is this collision with a Tilemap in the "danger" group?
		#	if collision.collider is TileMap and collision.collider.is_in_group("danger"):
		#		print("danger")

		if is_on_wall() or (detect_voids and not $Actor/PlatformChecker.is_colliding() and is_on_floor()):
			direction.x = -direction.x
			get_directional_extents()


func friction():
	if not _in_shock:
		velocity.x = speed.x * direction.x


func gravity(delta: float):
	if _chute_deployed and velocity.y > GRAVITY_PARACHUTE:
		velocity.y = GRAVITY_PARACHUTE * delta
	else:
		velocity.y += GRAVITY * delta


func activate_enemy():
	_spawning = true
	yield(get_tree().create_timer(_spawn_delay), "timeout")
	$Actor.animation = rank + "_spawn"
	$Teleport.play()
	$Actor/SpawnAnimation.play("spawn")
	yield($Actor/SpawnAnimation, "animation_finished")
	_spawned = true
	_first_spawn = false
	$CollisionShape2D.set_deferred("disabled", false)

	$StompArea2D.set_collision_mask_bit(0, true)
	$StompArea2D/CollisionShape2D.set_deferred("disabled", false)

	$ImpactLeft.set_collision_mask_bit(0, true)
	$ImpactLeft/CollisionShape2D.set_deferred("disabled", false)

	$ImpactRight.set_collision_mask_bit(0, true)
	$ImpactRight/CollisionShape2D.set_deferred("disabled", false)
	$Actor.visible = true

	# Add all enemies to a group so they can be operated on together
	add_to_group("enemies")
	if _is_passive:
		yield(get_tree().create_timer(1.0), "timeout")
		_is_passive = false



func deactivate_enemy():
	$Actor.visible = false
	_spawned = false
	$CollisionShape2D.set_deferred("disabled", true)

	$StompArea2D.set_collision_mask_bit(0, false)
	$StompArea2D/CollisionShape2D.set_deferred("disabled", true)

	$ImpactLeft.set_collision_mask_bit(0, false)
	$ImpactLeft/CollisionShape2D.set_deferred("disabled", true)

	$ImpactRight.set_collision_mask_bit(0, false)
	$ImpactRight/CollisionShape2D.set_deferred("disabled", true)


func spawn():
	# If the enemy has not yet spawn and is on screen the spawn them into the game
	if not _spawning and not _spawned and (respawn or _first_spawn) and $Actor/VisibilityNotifier2D.is_on_screen():
		activate_enemy()


func clone_thyself(can_spawn: bool):
	if can_spawn and not _first_spawn:
		var rng = RandomNumberGenerator.new()
		var thyself = self.duplicate()
		thyself.direction.x = IDLE
		thyself._in_shock = false
		thyself._spawned = false
		thyself._is_passive = true
		thyself._stomps_recieved = 0
		thyself.position.x = self._start_position.x
		thyself.position.y = self._start_position.y
		rng.randomize()
		thyself._spawn_delay = rng.randi_range(3.0, 7.5)
		get_tree().root.add_child(thyself)


func enemy_attacked(new_direction: float):
	# Enemy has been stomped
	_stomps_recieved += 1

	if _chute_deployed:
		stow_parachute()

	direction.x = new_direction
	get_directional_extents()
	velocity.y = -(IMPACT_IMPULSE / 2)
	velocity.x = new_direction * (IMPACT_IMPULSE * 0.65)

	_in_shock = true
	yield(get_tree().create_timer(0.5), "timeout")
	_in_shock = false

	# If they've taken too many stomps, they're dead Jim.
	if _stomps_recieved >= _stomps_required:
		PlayerData.score += points
		_in_shock = true

		# Disble the main collision shape so the now stomped enemy can't hit the player
		# This also makes the enemy fall through the floors when stomped,
		# because there are "no platforms" for the enemy to stand on.
		$CollisionShape2D.set_deferred("disabled", true)

		# Disable the player mask so that the player can not stomp the stomped sprite
		$StompArea2D.set_collision_mask_bit(0, false)

		$Hit.play()
		yield($Hit, "finished")
		clone_thyself(respawn)
		queue_free()
	else:
		# Make the enemy passive after being kicked.
		_is_passive = true
		yield(get_tree().create_timer(1.0), "timeout")
		_is_passive = false


func enemy_stomped():
	# Enemy has been stomped
	_stomps_recieved += 1

	if _chute_deployed:
		stow_parachute()

	# If they've taken too many stomps, they're dead Jim.
	if _stomps_recieved >= _stomps_required:
		PlayerData.score += points
		_in_shock = true
		direction.x = -direction.x
		velocity.y = -(IMPACT_IMPULSE / 2)

		# Disble the main collision shape so the now stomped enemy can't hit the player
		# This also makes the enemy fall through the floors when stomped,
		# because there are "no platforms" for the enemy to stand on.
		$CollisionShape2D.set_deferred("disabled", true)

		# Disable the player mask so that the player can not stomp the stomped sprite
		$StompArea2D.set_collision_mask_bit(0, false)

		$Squish.play()
		yield($Squish, "finished")
		clone_thyself(respawn)
		queue_free()
	else:
		$Ding.play()
