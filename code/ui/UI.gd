extends Control


const TIMER_PAD := 3


export var time_limit := 300.0


onready var scene_tree := get_tree()
onready var pause_overlay: ColorRect = get_node("PauseOverlay")
onready var score: Label = get_node("Score")
onready var timer: Label = get_node("Timer")
onready var health: Label = get_node("Health")
onready var chutes: Label = get_node("Chutes")
onready var items: Label = get_node("Items")
onready var status: Label = get_node("Status")


var paused := false setget set_paused
var clock = null
var last_second := 0


func _ready():
	set_paused(false)
	$PauseOverlay/PauseMenu/Resume.visible = true
	PlayerData.time_remaining = int(round(time_limit))
	PlayerData.connect("chutes_updated", self, "update_chutes")
	PlayerData.connect("health_updated", self, "update_health")
	PlayerData.connect("items_updated", self, "update_items")
	PlayerData.connect("score_updated", self, "update_score")
	update_chutes()
	update_health()
	update_items()
	update_score()

	PlayerData.connect("level_completed", self, "_on_level_complete")
	PlayerData.connect("player_died", self, "_on_Player_died")
	PlayerData.connect("time_expired", self, "_on_time_expired")

	clock = Timer.new()
	clock.set_timer_process_mode(Timer.TIMER_PROCESS_IDLE)
	clock = get_tree().create_timer(time_limit, false)
	clock.connect("timeout", self, "time_expired")

	pause_overlay.visible = false
	status.text = "Level: " + str(PlayerData.level).pad_zeros(2) + "\n" + '"' + get_node("../../").level_name + '"'
	status.visible = true
	yield(get_tree().create_timer(5.0), "timeout")
	status.visible = false

	$MedalBorder.visible = false
	$GoldMedal.visible = false
	$SilverMedal.visible = false
	$BronzeMedal.visible = false


func _on_Player_died():
	end_of_game("Agent Status: Killed In Action")


func _on_time_expired():
	end_of_game("Agent Status: Missing In Action")


func _on_level_complete():
	# FIXME: This stop the _process() function, which only has check_clock() in it.
	#        So janky way to stop the timer.
	set_process(false)
	end_of_level()


func _on_Resume_button_up():
	set_paused(false)


func _process(_delta):
	check_clock()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("pause") and not PlayerData.dead:
		set_paused(not paused)
		# Prevents other input being handled while paused
		scene_tree.set_input_as_handled()
	elif paused and event.is_action_pressed("ui_accept"):
		get_tree().change_scene("res://code/MainScreen.tscn")


func check_clock():
	var current_second := int(round(clock.time_left))
	if last_second != current_second:
		timer.text = str(current_second).pad_zeros(TIMER_PAD)
		if current_second <= 30:
			$Urgent.play()
		elif current_second % 60 == 0 and current_second < time_limit:
			$Reminder.play()
		last_second = current_second
		PlayerData.time_remaining = current_second


func end_of_game(message: String):
	set_paused(true)
	status.text = message
	$PauseOverlay/PauseMenu/Resume.visible = false
	$PauseOverlay/PauseMenu/MainMenu.size_flags_vertical = SIZE_FILL
	$GameOver.play()
	yield($GameOver, "finished")
	PlayerData.new_game()
	set_paused(false)
	get_tree().change_scene("res://code/MainScreen.tscn")


func end_of_level():
	var success = 0.0
	var time_bonus = int(PlayerData.time_remaining * 100)
	var rating = 0

	success = PlayerData.items / PlayerData.items_to_find as float

	# Calculate agent rank: 000 (worst) to 009 (best)
	rating = int(stepify(success, 0.001) * 10) - 1
	rating = max(rating, 0)

	# Calculate percentage complete
	success = stepify(success, 0.01) * 100

	$MedalBorder.visible = true
	if rating == 9:
		$GoldMedal.visible = true
	elif rating >= 6:
		$SilverMedal.visible = true
	else:
		$BronzeMedal.visible = true

	pause_overlay.visible = false
	status.text = "Agent Rank: " + str(rating).pad_zeros(3) + "\nObjective Success: " + str(success) + "%\nTime Bonus: " + str(time_bonus)
	status.visible = true
	PlayerData.score += time_bonus


func set_paused(value: bool):
	status.text = "Paused"
	paused = value
	scene_tree.paused = value
	pause_overlay.visible = value
	status.visible = value


func update_score():
	score.text = "Score: %s" % PlayerData.pad_score()


func update_health():
	health.text = "x %s" % PlayerData.get_health()


func update_items():
	items.text = "x %s" % PlayerData.get_items()


func update_chutes():
	chutes.text = "x %s" % PlayerData.get_chutes()
