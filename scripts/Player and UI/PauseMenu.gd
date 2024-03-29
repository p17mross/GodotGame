extends CanvasLayer

enum Menu {
	PAUSE,
	SETTINGS,
	RESET_CONFIRMATION,
}

enum PauseMenuItems {
	SAVE_AND_QUIT,
	SAVE_GAME,
	SETTINGS,
	RETURN_TO_GAME,
	RESET_SAVE,
}

enum ResetConfirmationItems {
	CONFIRM,
	CANCEL,
}

var is_paused := false
var selected := 0
var current_menu := Menu.PAUSE

@onready
var menus: Array[Control] = [
	$Control/Pause,
	$Control/Settings,
	$"Control/Reset Save Confirmation"
]

# A type of setting
enum SettingType {
	Slider,
	CheckButton,
}

enum SettingsMenuItems {
	MOUSE_SENSITIVITY,
	MOVEMENT_SPEED,
	MENU_TRANSPARENCY,
	FULLSCREEN,
	
	EXIT,
}

# The names of settings to pass to the Settings class
const settings := [
	"mouse_sensitivity",
	"movement_speed",
	"menu_transparency",
	"fullscreen",
]

# What type each setting is
const setting_types := [
	SettingType.Slider,      # MOUSE_SENSITIVITY
	SettingType.Slider,      # MOVEMENT_SPEED
	SettingType.CheckButton, # MENU_TRANSPARENCY
	SettingType.CheckButton, # FULLSCREEN
	
	null,                    # EXIT
]

@onready
var selection_triangle := $"Control/Selection Triangle"

@export var background_transparent: Node
@export var background_opaque: Node

# The check mark next to 'Save Game'
@export var save_game_confirmation: Node

# The tutorial text for resetting settings
@export var reset_prompt: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	# Web browsers can't reliably close tabs from scripts, so don't show the 'Save and Quit' option on web.
	if OS.get_name() == "Web":
		menus[Menu.PAUSE].get_child(PauseMenuItems.SAVE_AND_QUIT).visible = false
	
	# Set the UI components for settings to match the saved value of the settings
	for i in len(setting_types):
		if setting_types[i] == SettingType.Slider:
			var slider: HSlider = menus[Menu.SETTINGS].get_child(0).get_child(i).get_node("Slider")
			var setting_value = Settings.get_setting(settings[i])
			slider.value = setting_value
		elif setting_types[i] == SettingType.CheckButton:
			var check_button: CheckButton = menus[Menu.SETTINGS].get_child(0).get_child(i).get_node("CheckButton")
			var setting_value = Settings.get_setting(settings[i])
			check_button.button_pressed = setting_value
	
	Settings.register_callback("menu_transparency", func(value: bool):
		# If value is true, this will show the transparent version and hide the opaque
		# And vice versa if false
		background_transparent.visible = value
		background_opaque.visible = !value
	)
	
	# The 'fullscreen' setting can be set by other code if the user exits fullscreen using system controls.
	# When this happens, update the check button to the right value
	Settings.register_callback("fullscreen", func(value: bool):
		var check_button: CheckButton = menus[Menu.SETTINGS].get_child(0).get_child(SettingsMenuItems.FULLSCREEN).get_node("CheckButton")
		check_button.button_pressed = value
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.visible = is_paused
	
	if Input.is_action_just_pressed("pause"):
		if !is_paused:
			pause()
		else:
			if current_menu == Menu.PAUSE:
				unpause()
			else:
				set_menu(Menu.PAUSE)
	
	# Don't process other actions unless the game is paused
	if !is_paused:
		return
	
	if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_backward"):
		var num_children = menus[current_menu].get_child_count()
		var previous_selected = selected
		
		while true:
			selected += 1
			
			# If there are no more items to check, reset to previous state
			if selected >= num_children:
				selected = previous_selected
				break
			
			var candidate: Control = menus[current_menu].get_child(0).get_child(selected)
			# If the node is visible, choose it
			if candidate.visible:
				break
		
		set_pointer_position()
		
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_forward"):
		var previous_selected = selected
		
		while true:
			selected -= 1
			
			# If there are no more items to check, reset to previous state
			if selected < 0:
				selected = previous_selected
				break
			
			var candidate: Control = menus[current_menu].get_child(0).get_child(selected)
			# If the node is visible, choose it
			if candidate.visible:
				break
		
		set_pointer_position()
	
	if Input.is_action_just_pressed("ui_accept"):
		select_item()
	
	if current_menu == Menu.SETTINGS and setting_types[selected] == SettingType.Slider:
		var is_even_frame := Engine.get_process_frames() % 4 == 0
		
		# These updates triggers a value_changed event,
		# so there's no need to manually call on_menu_item_slider_input
		if is_even_frame and (Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right")):
			var slider: HSlider = menus[Menu.SETTINGS].get_child(0).get_child(selected).get_node("Slider")
			slider.value += slider.step
		
		if is_even_frame and (Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left")):
			var slider: HSlider = menus[Menu.SETTINGS].get_child(0).get_child(selected).get_node("Slider")
			slider.value -= slider.step
		
		if Input.is_action_just_pressed("reset"):
			var slider: HSlider = menus[Menu.SETTINGS].get_child(0).get_child(selected).get_node("Slider")
			var reset_value = Settings.reset_setting(settings[selected])
			slider.value = reset_value
		
	if current_menu == Menu.SETTINGS and setting_types[selected] == SettingType.CheckButton:
		if Input.is_action_just_pressed("reset"):
			var check_button: CheckButton = menus[Menu.SETTINGS].get_child(0).get_child(selected).get_node("CheckButton")
			var reset_value = Settings.reset_setting(settings[selected])
			check_button.button_pressed = reset_value

# Show the pause menu and stop the rest of the game from running
func pause():
	get_tree().paused = true
	is_paused = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	set_menu(Menu.PAUSE)

func unpause():
	get_tree().paused = false
	is_paused = false
	
	if get_node("/root/Node3D/Player").in_puzzle_mode:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_menu(menu: int):
	selected = 0
	current_menu = menu
	
	while true:
		if menus[current_menu].get_child(0).get_child(selected).visible:
			break
		
		selected += 1
	
	for i in len(menus):
		menus[i].visible = i == current_menu
	
	if current_menu == Menu.PAUSE:
		# Hide the check mark next to 'Save Game'
		save_game_confirmation.visible = false
	
	# Show the reset prompt if the current menu is the settings menu,
	# and not otherwise
	reset_prompt.visible = (current_menu == Menu.SETTINGS) 
	
	set_pointer_position()

func set_pointer_position():
	selection_triangle.reparent(menus[current_menu].get_child(0).get_child(selected), false)

func select_item():
	if current_menu == Menu.PAUSE:
		match selected:
			PauseMenuItems.SAVE_AND_QUIT:
				SaveManager.save_all()
				get_tree().quit()
			PauseMenuItems.SAVE_GAME:
				SaveManager.save_all()
				
				# Show the checkmark next to the save game option
				save_game_confirmation.visible = true
				# Hide the checkmark after a timeout of 1s
				(func():
					await get_tree().create_timer(1.0).timeout
					save_game_confirmation.visible = false
				).call()
				
			PauseMenuItems.SETTINGS:
				set_menu(Menu.SETTINGS)
			PauseMenuItems.RETURN_TO_GAME:
				unpause()
			PauseMenuItems.RESET_SAVE:
				set_menu(Menu.RESET_CONFIRMATION)
	elif current_menu == Menu.SETTINGS:
		if selected == SettingsMenuItems.EXIT:
			set_menu(Menu.PAUSE)
		elif setting_types[selected] == SettingType.CheckButton:
			var check_button: CheckButton = menus[Menu.SETTINGS].get_child(0).get_child(selected).get_node("CheckButton")
			# Don't need to set the actual setting here because that happens in the callback from setting the value
			check_button.button_pressed = !check_button.button_pressed
			
	elif current_menu == Menu.RESET_CONFIRMATION:
		match selected:
			ResetConfirmationItems.CONFIRM:
				SaveManager.reset_save()
				# Restart the application
				GameManager.reload()
				
			ResetConfirmationItems.CANCEL:
				set_menu(Menu.PAUSE)

# Callback for when the mouse hovers over a menu item
func on_menu_item_mouse_entered(menu_item: int):
	selected = menu_item
	set_pointer_position()

# Callback for when the player clicks on a menu item
func on_menu_item_gui_input(event: InputEvent, menu_item: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected = menu_item
			select_item()

# Callback for when the value of a slider setting changes
func on_menu_item_slider_input(value: float, menu_item: int):
	Settings.set_setting(settings[menu_item], value)

# Callback for when the value of a check button setting changes
func on_menu_item_check_button_input(value: bool, menu_item: int):
	Settings.set_setting(settings[menu_item], value)
