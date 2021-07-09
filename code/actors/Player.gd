extends Actor


const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.2
const KICK_BUFFER := 0.2
const WALL_JUMP_BUFFER := 0.2


export var input_disabled := false
export (float, 0, 1.0) var air_friction = 0.20
export (float, 0, 1.0) var chute_friction = 0.05
export (float, 0, 1.0) var ground_friction = 0.95
export (float, 0, 1.0) var run_acceleration = 0.25


var _coyote_time_delta := 0.0
var _jump_buffer_delta := 0.0
var _kick_buffer_delta := 0.0
var _wall_jump_buffer_delta := 0.0


func _ready() -> void:
	# Make sure the player is visible, since at end of level is set to not visible
	self.visible = true
	get_directional_extents()
	_spawned = true

	# Enable wall and platform checkers; used for player wall sliding
	$Actor/PlatformChecker.enabled = true
	$Actor/PlatformChecker.cast_to.y = 80
	$Actor/LeftWallChecker.enabled = true
	$Actor/RightWallChecker.enabled = true


func _on_EchoTimer_timeout():
	if _kicking:
		# Make an echo of the current player sprite
		var echo = preload("res://code/actors/Echo.tscn").instance()

		# Add the echo to the parent, so it doesn't move with the player sprite
		get_parent().add_child(echo)
		echo.position = position
		echo.texture = $Actor.frames.get_frame($Actor.animation, $Actor.frame)
		echo.flip_h = $Actor.flip_h


func _on_StompDetector_area_entered(area: Area2D):
	if position.y < area.global_position.y and area.is_in_group("top_impact"):
		player_stomp()


func _on_AttackLeft_area_entered(area: Area2D):
	if area.is_in_group("side_impact"):
		player_kick()


func _on_AttackRight_area_entered(area: Area2D):
	if area.is_in_group("side_impact"):
		player_kick()


func _on_EnemyDetector_body_entered(body: Actor):
	if not body._in_shock and not _in_shock and not _kicking and not body._is_passive:
		player_damage()


func _physics_process(delta: float):
	friction()
	gravity(delta)
	hazards(delta)


func _process(delta: float):
	move()
	chute()
	jump(delta)
	kick(delta)

	# While in shock disable the players hitbox
	$EnemyDetector/CollisionShape2D.disabled = _in_shock


# Reference:
# - https://godotengine.org/qa/69272/how-do-i-detect-collision-with-a-specific-tile-in-tilemap
func hazards(delta: float):
	# Use move_and_collide to get a collider object.
	# NOTE! Just get collision detection, not movement.
	var collision = move_and_collide(velocity * delta, true, true, true)
	if collision:
		# Is this collision with a Tilemap in the "danger" group?
		if collision.collider is TileMap and collision.collider.is_in_group("danger"):
			player_damage()

		#var tile_name = get_tile_name(collision)
		#print(tile_name)


func move():
	if input_disabled or _kicking:
		return

	# Return an int; -1 LEFT, 0 IDLE, 1 RIGHT
	direction.x = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	get_directional_extents()


func chute():
	if input_disabled:
		return

	if Input.is_action_just_pressed("chute"):
		if _chute_deployed:
			stow_parachute()
		elif not _chute_deployed and velocity.y > 0 and not next_to_wall() and not is_on_floor():
			if PlayerData.chutes >= 1:
				PlayerData.chutes -= 1
				deploy_parachute()
			else:
				$NoChute.play()


func jump(delta: float):
	if input_disabled or _in_shock or _kicking or PlayerData.level_complete:
		return

	# Jump buffering and Coyote time; as described here https://youtu.be/vFsJIrm2btU
	_jump_buffer_delta -= delta
	_coyote_time_delta -= delta
	_wall_jump_buffer_delta -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_delta = JUMP_BUFFER

	if next_to_wall():
		_wall_jump_buffer_delta = WALL_JUMP_BUFFER

	if is_on_floor() or next_to_wall():
		_coyote_time_delta = COYOTE_TIME

	# Determine if the player can jump again
	if (_jump_buffer_delta > 0 and _coyote_time_delta > 0):
		_jump_buffer_delta = 0.0
		_coyote_time_delta = 0.0

		direction.y = UP
		$Jump.play()
		if (_wall_jump_buffer_delta > 0 and not is_on_floor()):
			_wall_jump_buffer_delta = 0.0
			if next_to_right_wall():
				walljump(LEFT)
			elif next_to_left_wall():
				walljump(RIGHT)
	else:
		direction.y = DOWN

	# If jumping when jump button is released, cut the jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5


func walljump(new_direction: float):
	direction.x = new_direction
	get_directional_extents()
	velocity.x = (new_direction * 1.5) * (IMPACT_IMPULSE)
	_wall_jumping = true
	yield(get_tree().create_timer(0.65), "timeout")
	_wall_jumping = false


func kick(delta: float):
	if PlayerData.level_complete:
		_kicking = false
		return

	if input_disabled or _in_shock or _kicking:
		return

	# Jump buffering; as described here https://youtu.be/vFsJIrm2btU
	_kick_buffer_delta -= delta

	if is_on_floor() or is_on_wall():
		# Recharge when player touches the floor or a wall
		_can_kick = true

	if _kicking and next_to_wall():
		$Actor/Land.play()
		_kicking = false

	if (Input.is_action_just_pressed("kick")
		and _can_kick
		and not next_to_wall()
		and not direction.x == IDLE):
		_kick_buffer_delta = KICK_BUFFER

		if _kick_buffer_delta > 0:
			_kick_buffer_delta = 0.0
			_can_kick = false
			$Kick.play()
			direction = Vector2(direction.x,0)
			velocity = direction.normalized() * (IMPACT_IMPULSE * 0.75)
			# Enable the attack box based on the direction of travel
			if velocity.x < 0:
				$AttackRight/CollisionShape2D.disabled = false
			elif velocity.x > 0:
				$AttackLeft/CollisionShape2D.disabled = false
			_kicking = true
			yield(get_tree().create_timer(0.4), "timeout")
			_kicking = false

	if not _kicking:
		$AttackLeft/CollisionShape2D.disabled = true
		$AttackRight/CollisionShape2D.disabled = true


func friction():
	if not _kicking:
		if direction.x != IDLE:
			if _wall_jumping:
				velocity.x = lerp(velocity.x, (direction.x * 1.25) * speed.x, air_friction)
			elif velocity.y != 0:
				velocity.x = lerp(velocity.x, direction.x * speed.x, air_friction)
			else:
				# We're on the move, accelerate.
				velocity.x = lerp(velocity.x, direction.x * speed.x, run_acceleration)
		else:
			# We're not requesting movement, slow down.
			if _chute_deployed:
				velocity.x = lerp(velocity.x, 0, chute_friction)
			elif velocity.y == 0 or _in_shock:
				velocity.x = lerp(velocity.x, 0, ground_friction)
			else:
				velocity.x = lerp(velocity.x, 0, air_friction)


func gravity(delta: float):
	# Don't apply gravity while kicking, which is also a dash mechanic
	if _kicking:
		velocity.y = 0
	elif _chute_deployed:
		velocity.y = max(GRAVITY_PARACHUTE * delta, GRAVITY_PARACHUTE)
	elif is_wall_sliding():
		velocity.y = max(GRAVITY_WALLSLIDE * delta, GRAVITY_WALLSLIDE)
	else:
		velocity.y += GRAVITY * delta

	if direction.y == UP:
		if _wall_jumping:
			velocity.y = direction.y * speed.y * 1.125
		else:
			velocity.y = direction.y * speed.y


func is_wall_sliding() -> bool:
	return not $Actor/PlatformChecker.is_colliding() and next_to_wall() and velocity.y > 0


func player_stomp():
	velocity.y = -IMPACT_IMPULSE
	_landing_counter = 1
	$CameraLerp/ScreenShake.start(0.1, 32, 4, 0)
	$Stomp.play()


func player_kick():
	_kicking = false
	_landing_counter = 1
	$CameraLerp/ScreenShake.start(0.1, 16, 8, 0)
	$KickLanded.play()


func player_damage():
	PlayerData.health -= 1
	player_shock()


func player_shock():
	_can_kick = true
	# Don't add shock impulse if you're parachuting
	if _chute_deployed:
		stow_parachute()
	elif not _in_shock:
		velocity.y = -IMPACT_IMPULSE
		direction.x = -direction.x

	$CameraLerp/ScreenShake.start(0.2, 20, 24, 0)
	$Damage.play()
	_in_shock = true
	yield(get_tree().create_timer(0.5), "timeout")
	_in_shock = false
	if PlayerData.health <= 0:
		player_death()


func player_death():
	#_in_shock = true
	# Disable physics collision to make the player fall through the screen.
	$CollisionShape2D.set_deferred("disabled", true)
	# Disable the players stompdector so that the player can not stomp whilst dead
	$StompDetector/CollisionShape2D.set_deferred("disabled", true)
	$Die.play()
	yield(get_tree().create_timer(1.5), "timeout")
	PlayerData.dead = true
	queue_free()
