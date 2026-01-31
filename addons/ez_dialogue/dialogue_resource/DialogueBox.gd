extends VBoxContainer
signal state_changed(state_name: String, new_value: int)
signal typewriter_finished(response: DialogueResponse)

@export var dialogue: JSON
@export var typewriter_speed: float = 0.04
@export var pitch_scale: float = 0.1

@onready var mask_slider = $SpriteHandler/MaskSlider
@onready var mask_popup = $"../../MaskPopup"
@onready var character_name_handler = $CharacterNameHandler
@onready var dialogue_choice_res = preload("res://addons/ez_dialogue/main_screen/DialogueButton.tscn")

@export var state: Dictionary = {}
@export var other_mask_max_value: int = 6

@export var dialogue_width_minimized: float = 1350.0
@export var dialogue_width_maximized: float = 1728.0

@export var next_scene_path: String = ""

var dialogue_finished = false
var typewriter_tween: Tween
var button_cache: Array[DialogueButton] = []
var current_response: DialogueResponse

@onready var dialogue_handler: EzDialogue = $EzDialogue
#@onready var roll_handler = $"../RollBox"
@onready var sprites_handler = $SpriteHandler

func _ready():
	dialogue_finished = false
	dialogue_handler.start_dialogue(dialogue, state)
	mask_slider.init_slider(other_mask_max_value)
	character_name_handler.hide_speaking_character_name_ui()
	typewriter_finished.connect(_on_typewriter_finished)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_click"):
		skip_typewriter()

func _on_typewriter_finished(response: DialogueResponse):
	#print("Typewriter finished for text: " + response.text)
	current_response = null
	if response.choices.is_empty():
		add_choice("[...]", 0)
	else:
		for i in response.choices.size():
			add_choice(response.choices[i], i)

func clear_dialogue():
	$text.text = ""
	for child in get_children():
		if child is Button:
			#button_cache.erase(child)
			#child.queue_free()
			child.hide()

func add_text(response: DialogueResponse) -> void:
	var text = response.text
	$text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Defer starting the typewriter effect so the node is inside the scene tree and get_tree() is valid.
	call_deferred("_typewriter_effect", response)

func _typewriter_effect(response: DialogueResponse) -> void:
	current_response = response
	var text_content = response.text
	$text.text = text_content
	$text.visible_ratio = 0
	
	if typewriter_tween:
		typewriter_tween.kill()
	
	typewriter_tween = create_tween()
	var duration = text_content.length() * typewriter_speed
	
	# Use tween_method to call _on_typewriter_step repeatedly
	typewriter_tween.tween_method(_on_typewriter_step, 0.0, 1.0, duration)
	
	typewriter_tween.finished.connect(func():
		typewriter_finished.emit(response)
	)

func _on_typewriter_step(ratio: float) -> void:
	# Check if we've actually moved forward enough to show a new character
	var old_visible_chars = $text.visible_characters
	$text.visible_ratio = ratio
		
	# If the number of visible characters increased, play the sound
	if $text.visible_characters > old_visible_chars:
		# Avoid playing sound for spaces to make it feel more natural
		var last_char = $text.text[$text.visible_characters - 1]
		if last_char != " ":
			$TypewriterPlayer.pitch_scale = randf_range(1 - pitch_scale, 1 + pitch_scale)
			$TypewriterPlayer.play()

func skip_typewriter() -> void:
	if typewriter_tween and typewriter_tween.is_running():
		typewriter_tween.kill() # Stop the animation
		$text.visible_ratio = 1.0 # Show all text immediately
		# Manually emit since the tween was killed
		typewriter_finished.emit(current_response)

func add_choice(choice_text: String, id: int):
	if button_cache.size() < id + 1:
		var new_button = dialogue_choice_res.instantiate()
		new_button.choice_id = id
		button_cache.push_back(new_button)
		add_child(new_button)
		new_button.dialogue_selected.connect(_on_choice_button_down)
		new_button.custom_minimum_size.y = 40

	var button = button_cache[id]
	button.text = choice_text
	button.add_theme_font_size_override("font_size", 24)
	button.show()

func _on_choice_button_down(choice_id: int):
	clear_dialogue()
	if !dialogue_finished:
		dialogue_handler.next(choice_id)

func _on_ez_dialogue_dialogue_generated(response: DialogueResponse):
	add_text(response)

func _on_ez_dialogue_end_of_dialogue_reached():
	dialogue_finished = true

func _on_ez_dialogue_custom_signal_received(value: String):
	var params = value.split(",")

	########################### DIALOGUE PARAMETERS SIGNALS HANDLED IN THIS SECTION ###########################
	if params[0] == "changeparam":
		var param_name: String = params[1]
		var amount: int
		if params.size() < 3 or not params[2].is_valid_int():
			print("[changeparam] Warning: Invalid amount parameter.")
			return
		amount = int(params[2])
		if param_name in state:
			state[param_name] += amount
			state_changed.emit(param_name, state[param_name])
			print(param_name + ": " + str(state[param_name]))
		else:
			print("[changeparam] Warning: Parameter " + param_name + " not found in state dictionary.")
	elif params[0] == "setparam":
		var param_name: String = params[1]
		var amount: int
		if params.size() < 3 or not params[2].is_valid_int():
			print("[setparam] Warning: Invalid amount parameter.")
			return
		amount = int(params[2])
		if param_name in state:
			state[param_name] = amount
			state_changed.emit(param_name, state[param_name])
			print("Set parameter " + param_name + " to: " + str(state[param_name]))
		else:
			print("[setparam] Warning: Parameter " + param_name + " not found in state dictionary.")
	elif params[0] == "debug":
		var message: String = params[1]
		print("[print signal]: " + message)
	elif params[0] == "checkparam":
		var comparison_type: String = params[1]
		var param_name: String = params[2]
		var test_value: int

		if params.size() < 4 or not params[3].is_valid_int():
			print("[checkparam] Warning: Invalid test value parameter.")
			return
		test_value = int(params[3])

		if param_name in state:
			var current_value = state[param_name]
			var comparison_result = false

			match comparison_type:
				"<":
					comparison_result = current_value < test_value
				">":
					comparison_result = current_value > test_value
				"<=":
					comparison_result = current_value <= test_value
				">=":
					comparison_result = current_value >= test_value
				"==":
					comparison_result = current_value == test_value
				"!=":
					comparison_result = current_value != test_value
				_:
					print("[checkparam] Warning: Unrecognized comparison type '" + comparison_type + "'.")
					return

			print("[checkparam] Comparison result for " + param_name + ": " + str(comparison_result))
			state["comparison_result"] = comparison_result
		else:
			print("[checkparam] Warning: Parameter " + param_name + " not found in state dictionary.")
	elif params[0] == "highestparam":
		var highest_param: String = ""
		var highest_value: int = -INF

		for key in state.keys():
			if state[key] is int:
				var param_value: int = state[key]
				if param_value > highest_value:
					highest_value = param_value
					highest_param = key
				elif param_value == highest_value:
					highest_param = ""  # Tie detected
					print("[highestparam] Warning: Tie detected between multiple parameters with value: " + str(highest_value))
					state["highest_param"] = highest_param
					return

		if highest_param != "":
			print("[highestparam] Highest parameter is " + highest_param + " with value: " + str(highest_value))
			state["highest_param"] = highest_param
		else:
			print("[highestparam] Warning: Either No integer parameters found in state dictionary or no states in it at all.")

	########################### VISUAL AND CHATBOX SIGNALS HANDLED IN THIS SECTION ###########################
	elif params[0] == "changeleftsprite":
		if params.size() < 3:
			print("[changeleftsprite] Warning: Invalid parameters.")
			return
		var left_character_name: String = params[1]
		var left_character_expression: String = params[2]
		var left_character: String = left_character_name + "_" + left_character_expression
		sprites_handler.change_left_character_visual(left_character)
	elif params[0] == "changerightsprite":
		if params.size() < 3:
			print("[changerightsprite] Warning: Invalid parameters.")
			return
		var right_character_name: String = params[1]
		var right_character_expression: String = params[2]
		var right_character: String = right_character_name + "_" + right_character_expression
		sprites_handler.change_right_character_visual(right_character)
	elif params[0] == "hidesprites":
		maximize_dialogue_size()
		sprites_handler.hide_all_sprites()
	elif params[0] == "hideleftsprite":
		sprites_handler.hide_left_sprite()
	elif params[0] == "hiderightsprite":
		maximize_dialogue_size()
		sprites_handler.hide_right_sprite()
	elif params[0] == "showsprites":
		minimize_dialogue_size()
		sprites_handler.show_all_sprites()
	elif params[0] == "showleftsprite":
		sprites_handler.show_left_sprite()
	elif params[0] == "showrightsprite":
		minimize_dialogue_size()
		sprites_handler.show_right_sprite()
	elif params[0] == "setspeakername":
		if params.size() < 2:
			character_name_handler.hide_speaking_character_name_ui()
		else:
			var character_name: String = params[1]
			character_name_handler.set_speaking_character_name(character_name)	
	elif params[0] == "maskpopup":
		if params.size() < 2 or not params[1].is_valid_int():
			print("[maskpopup] Warning: Invalid mask value parameter.")
			return
		var mask: String = params[1]
		mask_popup.display(mask)

	########################### SOUND SIGNALS HANDLED IN THIS SECTION ###########################
	elif params[0] == "playsound":
		if params.size() < 2:
			print("[playsound] Warning: No sound file specified.")
			return
		if not ResourceLoader.exists(params[1]):
			print("[playsound] Warning: Sound file " + params[1] + " does not exist.")
			return
		if %SFXAudioStreamPlayer.stream != null:
			%SFXAudioStreamPlayer.stop() 
		%SFXAudioStreamPlayer.play(params[1])
	elif params[0] == "stopsound":
		%SFXAudioStreamPlayer.stop()
		if %SFXAudioStreamPlayer.stream != null:
			%SFXAudioStreamPlayer.stream = null
	elif params[0] == "settypewritersfx":
		if params.size() < 2:
			print("[settypewritersfx] Warning: No sound file specified.")
			return
		if not ResourceLoader.exists(params[1]):
			print("[settypewritersfx] Warning: Sound file " + params[1] + " does not exist.")
			return
		var new_stream = load(params[1])
		if new_stream is AudioStream:
			$TypewriterPlayer.stream = new_stream
		else:
			print("[settypewritersfx] Warning: Loaded resource is not an AudioStream.")

	########################### SCENE MANAGEMENT SIGNALS HANDLED IN THIS SECTION ###########################
	elif params[0] == "nextscene":
		# dialogue_handler.end_dialogue()
		get_tree().change_scene_to_file(next_scene_path)

	########################### UNHANDLED SIGNALS HANDLED IN THIS SECTION ###########################
	else:
		print("[custom_signal] Error: There are no parameters/unrecognized ones in the specified signals. Following are the available signals:")
		print("PARAMETERS RELATED SIGNALS:")
		print("signal(changeparam,\"paramname\",value)")
		print("signal(setparam,\"paramname\",value)")
		print("signal(debug,\"message\")")
		print("signal(checkparam,\"<|>|<=|>=|==|!=\",\"paramname\",value) => comparison_result")
		print("signal(highestparam) => highest_param")
		print("VISUAL RELATED SIGNALS:")
		print("signal(changeleftsprite,\"leftcharactername\",\"leftcharacterexpression\")")
		print("signal(changerightsprite,\"rightcharactername\",\"rightcharacterexpression\")")
		print("signal(hidesprites)")
		print("signal(hideleftsprite)")
		print("signal(hiderightsprite)")
		print("signal(showsprites)")
		print("signal(showleftsprite)")
		print("signal(showrightsprite)")
		print("signal(setspeakername,-optional: \"charactername\")")
		print("SOUND RELATED SIGNALS:")
		print("signal(playsound,\"soundfilepath\")")
		print("signal(stopsound)")
		print("signal(settypewritersfx,\"soundfilepath\")")
		print("SCENE MANAGEMENT RELATED SIGNALS:")
		print("signal(nextscene)")

func maximize_dialogue_size():
	$text.custom_minimum_size.x = dialogue_width_maximized
	for button in button_cache:
		button.custom_minimum_size.x = dialogue_width_maximized

func minimize_dialogue_size():
	$text.custom_minimum_size.x = dialogue_width_minimized
	for button in button_cache:
		button.custom_minimum_size.x = dialogue_width_minimized
