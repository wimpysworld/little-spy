extends Control


var instructions := "Cursor"


func _on_StartGame_button_up():
	set_process(false)
	$Player/Actor.visible = false
	PlayerData.new_game()
	if not PlayerData.intro_played:
		PlayerData.intro_played = true
		PlayerData.title_delay = 0.750
		$Portal.fly_helicopter()
	else:
		$Portal.fly_helicopter(PlayerData.intro_played)


func _ready():
	set_process(true)
	get_tree().paused = false
	$Menu.visible = false
	$Guard.direction.x = 0
	$Soldier.direction.x = 0
	$Version.text = Project.VERSION
	hide_instructions()
	if PlayerData.intro_played:
		$Player.stow_parachute()
		$Guard.stow_parachute()
		$Soldier.stow_parachute()

	# Hide the quit button in the HTML5 version
	if OS.get_name() == "HTML5":
		$Menu/QuitButton.visible = false


func _process(_delta: float):
	if $Player.is_on_floor():
		$Menu.visible = true
	if $Guard.is_on_floor():
		$Guard.display_caption("Hit x1")
	if $Soldier.is_on_floor():
		$Soldier.display_caption("Hit x2")


func _input(_event: InputEvent):
	if $Menu.visible:
		if Input.is_action_just_pressed("ui_accept"):
			_on_StartGame_button_up()
		elif Input.is_action_just_pressed("ui_cancel") and OS.get_name() != "HTML5":
			get_tree().quit()


func _on_InstructionsTimer_timeout():
	if $Player.is_on_floor():
		hide_instructions()
		if OS.has_touchscreen_ui_hint():
			instructions = "Xbox"
		elif instructions == "Xbox":
			instructions = "WASD"
		elif instructions == "WASD":
			instructions = "Cursor"
		elif instructions == "Cursor":
			instructions = "Xbox"
		show_instructions()


func hide_instructions():
	$ControlsCursor.visible = false
	$ControlsWASD.visible = false
	$ControlsXbox.visible = false
	$Options.visible = false


func show_instructions():
	$Options.visible = not OS.has_touchscreen_ui_hint()

	# Hide irrelevant options when running the webapp
	if OS.get_name() == "HTML5":
		$Options/F10_Key_Dark.visible = false
		$Options/F11_Key_Dark.visible = false
		$Options/FullScreen.visible = false
		$Options/WindowSize.visible = false

	if instructions == "Xbox":
		$ControlsCursor.visible = false
		$ControlsWASD.visible = false
		$ControlsXbox.visible = true
	elif instructions == "Cursor":
		$ControlsCursor.visible = true
		$ControlsWASD.visible = false
		$ControlsXbox.visible = false
	elif instructions == "WASD":
		$ControlsCursor.visible = false
		$ControlsWASD.visible = true
		$ControlsXbox.visible = false
