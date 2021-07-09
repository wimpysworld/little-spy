extends KinematicBody2D
class_name Actor


const LEFT = -1
const RIGHT = 1
const UP = -1
const DOWN = 1
const IDLE = 0

const FLOOR_FACES_UP = Vector2.UP
const GRAVITY := 3500.0
const GRAVITY_PARACHUTE := 128.0
const GRAVITY_WALLSLIDE := 64.0
const IMPACT_IMPULSE = 1000.0
const MAX_JITTER := 1
const MAX_LANDING_FRAMES := 10
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 12
const STOP_ON_SLOPE = true


# Rank determine the sprite uniform and some actor attribute, such as speed.
export var rank := "soldier"
export var respawn := true
export var start_with_airdrop := false
export var detect_voids := true


var points := 100
var speed := Vector2.ZERO
var direction = Vector2.ZERO
var velocity := Vector2.ZERO


var _first_spawn := true
var _can_kick := false
var _chute_deployed := false
var _hit_the_ground := false
var _in_shock := false
var _kicking := false
var _landing_counter := 0
var _is_passive := true
var _spawn_delay := 0.0
var _spawned := false
var _spawning = false
var _start_position := Vector2.ZERO
var _stomps_recieved := 0
var _stomps_required := 0
var _snap_vector = SNAP_DIRECTION * SNAP_LENGTH
var _terrain_jitter := 0
var _wall_jumping := false


func _ready() -> void:
	# Store the starting position; useful for respawning
	_start_position = self.position

	# Define actor attributes, based in their rank
	if rank == "spy":
		speed = Vector2(300.0, 1000.0)
	elif rank == "guard":
		_stomps_required = 1
		speed = Vector2(325.0, 1000.0)
	elif rank == "soldier":
		speed = Vector2(275.0, 1000.0)
		_stomps_required = 2
	points = _stomps_required * 100

	# Disable wall checkers (used for player wall sliding)
	$Actor/LeftWallChecker.enabled = false
	$Actor/RightWallChecker.enabled = false

	if start_with_airdrop:
		deploy_parachute()
	else:
		stow_parachute()


func _physics_process(_delta: float):
	# move_and_slide and move_and_slide_with_snap are implemented
	#  - move_and_slide doesn't clamp actors to uneven surfaces when they're shocked
	#  - if steep sloped terrain is ever added, move_and_slide_with_snap should work

	velocity = move_and_slide(velocity, FLOOR_FACES_UP, STOP_ON_SLOPE)
	#velocity = move_and_slide_with_snap(velocity, _snap_vector, FLOOR_FACES_UP, STOP_ON_SLOPE)


func _process(_delta: float):
	if _chute_deployed and (is_on_floor() or is_on_wall()):
		stow_parachute()

	if _spawned:
		animate_actor()


func animate_actor():
	var anim = rank + "_idle"

	if _chute_deployed:
		$Actor/Chute.animation = rank + "_parachute"

	$Actor/Chute.visible = _chute_deployed

	# Select the appropriate sprite for lateral motion
	if not velocity.x == 0:
		anim = rank + "_run"
		# Flip the sprite horizontally depending on direction of travel
		$Actor.flip_h = velocity.x < 0
		# Face toward the impact when shocked
		if _in_shock:
			$Actor.flip_h = not $Actor.flip_h

	# Select appropriate sprite for vertical motion, which takes precedence
	if _chute_deployed:
		anim = rank + "_fall"
		_hit_the_ground = false
	elif not is_on_floor():
		# Compensate for jitter when detecting ground when running over uneven terrain
		_terrain_jitter += 1
		if velocity.y < 0 and _terrain_jitter > MAX_JITTER:
			anim = rank + "_jump"
			_hit_the_ground = false
		elif velocity.y > 0 and _terrain_jitter > MAX_JITTER:
			anim = rank + "_fall"
			_hit_the_ground = false
	elif is_on_floor():
		_terrain_jitter = 0
		if not _hit_the_ground:
			animate_landing()

	# We're in the landing sequence.
	if _landing_counter:
		anim = rank + "_land"
		if _landing_counter >= MAX_LANDING_FRAMES:
			_landing_counter = 0
		else:
			# If actor is moving laterally, shorten the landing sequence
			if is_equal_approx(velocity.x, 0):
				_landing_counter += 1
			else:
				_landing_counter += 2

	if _kicking:
		anim = rank + "_kick"

	if next_to_wall() and velocity.y > 0:
		anim = rank + "_wall"

	# If in shock, this sprite superceeds everything
	if _in_shock:
		anim = rank + "_shock"

	if $Actor.animation != anim:
		$Actor.animation = anim
		$Actor.play(anim)


func animate_landing():
	# We've landed. Kick up dust and make a sound
	_hit_the_ground = true
	_landing_counter = 1
	$Actor/Land.play()
	$Actor/Dust.flip_h = not $Actor.flip_h
	$Actor/Dust.position.x = $CollisionShape2D.shape.get_radius() * (-direction.x * 1.5)
	$Actor/Dust/DustAnimation.play("dust")


func next_to_wall() -> bool:
	return next_to_left_wall() or next_to_right_wall()


func next_to_left_wall() -> bool:
	if $Actor/LeftWallChecker.is_colliding():
		$Actor.flip_h = true
		return true
	else:
		return false


func next_to_right_wall() -> bool:
	if $Actor/RightWallChecker.is_colliding():
		$Actor.flip_h = false
		return true
	else:
		return false


func get_directional_extents():
	# Get the direction extent of the actors physics collision shape
	$Actor/PlatformChecker.position.x = $CollisionShape2D.shape.get_radius() * direction.x


func deploy_parachute():
	_chute_deployed = true
	_hit_the_ground = false


func stow_parachute():
	_chute_deployed = false


func display_caption(caption: String):
	$Actor/Caption.text = caption
	$Actor/Caption.visible = true


func hide_caption():
	$Actor/Caption.visible = false


# Reference:
# - https://kidscancode.org/godot_recipes/2d/tilemap_collision/
func get_tile_name(this_collision: KinematicCollision2D) -> String:
	# Left here for reference, we could use the tile name too.
	if this_collision.collider is TileMap:
		# Find the colliding tile position
		var tile_pos = this_collision.collider.world_to_map(position)
		tile_pos -= this_collision.normal
		# Get the tile id
		var tile_id = this_collision.collider.get_cellv(tile_pos)
		var tile_name = this_collision.collider.tile_set.tile_get_name(tile_id)
		return tile_name
	else:
		return ""
