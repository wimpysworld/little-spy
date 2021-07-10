extends Node

const VERSION := "v1.0.3"
const STARTING_HEALTH := 3
const STARTING_CHUTES := 3
const SCORE_PAD := 6


signal chutes_updated
signal health_updated
signal items_updated
signal items_to_find_updated
signal level_completed
signal player_died
signal new_game
signal new_level
signal score_updated
signal time_expired
signal time_limit_updated


var chutes: int = STARTING_CHUTES setget set_chutes, get_chutes
var dead := false setget set_dead, get_dead
var fullscreen := false
var health: int = STARTING_HEALTH setget set_health
var intro_played := false setget set_intro_played, get_intro_played
var items := 0 setget set_items, get_items
var level := 0 setget set_level, get_level
var items_to_find := 0 setget set_items_to_find, get_items_to_find
var level_complete := false setget set_level_complete, get_level_complete
var scale_factor := 0.8
var score := 0 setget set_score, get_score
var time_limit := 300 setget set_time_limit, get_time_limit
var time_remaining: int = 300 setget set_time_remaining, get_time_remaining
var title_delay := 5.25 setget set_title_delay, get_title_delay

# Used to store player metrics on entering a new level
# So retrying a failed level has an accurate starting point.
var retry_chutes := 0
var retry_health := 0
var retry_score := 0


onready var vp = get_tree().get_root()
onready var base_width = ProjectSettings.get_setting("display/window/size/width")
onready var base_height = ProjectSettings.get_setting("display/window/size/height")
onready var base_size = Vector2(base_width, base_height)


func _ready():
	if fullscreen:
		set_fullscreen()
	else:
		set_windowed()


func _process(_delta: float):
	if Input.is_action_just_released("toggle_fullscreen"):
		if fullscreen:
			set_windowed()
		else:
			set_fullscreen()
		fullscreen = not fullscreen
	if Input.is_action_just_released("toggle_scale") and not fullscreen:
		scale_factor += 0.2
		if scale_factor > 0.8:
			scale_factor = 0.2
		set_windowed()

		# FIXME: Lowest scale factor needs applying twice to centre the window
		if scale_factor == 0.2:
			set_windowed()


func set_fullscreen():
	var window_size = OS.get_screen_size()

	if OS.get_name() == 'X11' or window_size == base_size:
		OS.set_window_fullscreen(true)
	else:
		var scale = min(window_size.x / base_size.x, window_size.y / base_size.y)
		print(scale)
		var scaled_size = (base_size * scale).round()
		print(scaled_size)

		var margins = Vector2(window_size.x - scaled_size.x, window_size.y - scaled_size.y)
		print(margins)
		var screen_rect = Rect2((margins / 2).round(), scaled_size)
		print(screen_rect)

		OS.set_borderless_window(true)
		OS.set_window_position(OS.get_screen_position())
		OS.set_window_size(Vector2(window_size.x, window_size.y + 1)) # Black magic?
		vp.set_size(scaled_size) # Not sure this is strictly necessary
		vp.set_attach_to_screen_rect(screen_rect)


func set_windowed():
	var window_size = OS.get_screen_size()
	var scale = min(window_size.x / base_size.x, window_size.y / base_size.y) * scale_factor
	var scaled_size = (base_size * scale).round()
	var window_x = (window_size.x / 2) - (scaled_size.x / 2)
	var window_y = (window_size.y / 2) - (scaled_size.y / 2)

	OS.set_borderless_window(false)
	OS.set_window_fullscreen(false)
	OS.set_window_position(Vector2(window_x, window_y))
	OS.set_window_size(scaled_size)
	vp.set_size(scaled_size)


func new_game():
	chutes = STARTING_CHUTES
	dead = false
	health = STARTING_HEALTH
	items = 0
	items_to_find = 0
	level_complete = false
	level = 0
	score = 0
	time_limit = 300
	time_remaining = 300
	emit_signal("new_game")


func new_level():
	# Score is not reset here.
	dead = false
	items = 0
	items_to_find = 0
	level_complete = false
	level += 1
	time_limit = 300
	time_remaining = 300
	retry_chutes = chutes
	retry_health = health
	retry_score = score
	emit_signal("new_level")


func retry_level():
	# Level is not incremented here
	chutes = retry_chutes
	dead = false
	health = retry_health
	items = 0
	items_to_find = 0
	level_complete = false
	score =  retry_score
	time_limit = 300
	time_remaining = 300
	emit_signal("new_level")


func set_time_limit(new_time_limit: int):
	time_limit = new_time_limit
	emit_signal("time_limit_updated")


func get_time_limit() -> int:
	return time_limit


func set_time_remaining(new_time_remaining: int):
	if time_remaining != new_time_remaining:
		time_remaining = max(new_time_remaining, 0)
		if time_remaining == 0:
			emit_signal("time_expired")


func get_time_remaining() -> int:
	return time_remaining


func set_score(new_score: int):
	score = new_score
	emit_signal("score_updated")


func get_score() -> int:
	return score


# Return score, padded with 0s as a string
func pad_score() -> String:
	return str(score).pad_zeros(SCORE_PAD)


func set_items(new_items: int):
	items = new_items
	emit_signal("items_updated")


func get_items() -> int:
	return items


func set_level(new_level: int):
	level = new_level
	emit_signal("level_updated")


func get_level() -> int:
	return level

func set_items_to_find(new_items_to_find: int):
	items_to_find = new_items_to_find
	emit_signal("items_to_find_updated")


func get_items_to_find() -> int:
	return items_to_find


func get_chutes() -> int:
	return chutes


func set_chutes(new_chutes: int):
	chutes = new_chutes
	chutes = max(new_chutes, 0)
	emit_signal("chutes_updated")


func set_health(new_health: int):
	health = new_health
	health = max(new_health, 0)
	emit_signal("health_updated")


func get_health() -> int:
	return health


func set_dead(death: bool):
	dead = death
	emit_signal("player_died")


func get_dead() -> bool:
	return dead


func set_level_complete(complete: bool):
	level_complete = complete
	emit_signal("level_completed")


func get_level_complete() -> bool:
	return level_complete


func set_intro_played(new_intro_played: bool):
	intro_played = new_intro_played


func get_intro_played() -> bool:
	return intro_played


func set_title_delay(new_delay: float):
	title_delay = new_delay


func get_title_delay() -> float:
	return title_delay
