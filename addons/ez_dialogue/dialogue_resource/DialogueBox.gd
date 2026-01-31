extends VBoxContainer
signal state_changed(state_name: String, new_value: int)

@export var dialogue: JSON

@onready var mask_slider = $SpriteHandler/MaskSlider
@onready var dialogue_choice_res = preload("res://crpg_dialogue_demo/DialogueButton.tscn")

@export var state: Dictionary = {}

@export var dialogue_width_minimized: float = 1350.0
@export var dialogue_width_maximized: float = 1728.0

var dialogue_finished = false
var is_rolling = false

var button_cache: Array[DialogueButton] = []

@onready var dialogue_handler: EzDialogue = $EzDialogue
#@onready var roll_handler = $"../RollBox"
@onready var sprites_handler = $SpriteHandler


func _ready():
	dialogue_finished = false
	dialogue_handler.start_dialogue(dialogue, state)

func clear_dialogue():
	$text.text = ""
	is_rolling = false
	for child in get_children():
		if child is Button:
			#button_cache.erase(child)
			#child.queue_free()
			child.hide()

func add_text(text: String):
	$text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#$text.add_theme_font_size_override("font_size", 24)
	$text.text = text

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
	if is_rolling:
		return

	add_text(response.text)
	if response.choices.is_empty():
		add_choice("[...]", 0)
	else:
		for i in response.choices.size():
			add_choice(response.choices[i], i)

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

	########################### VISUAL PARAMETERS SIGNALS HANDLED IN THIS SECTION ###########################
	elif params[0] == "changesprites":
			var left_character_name: String = params[1]
			var left_character_expression: String = params[2]
			var right_character_name: String = params[3]
			var right_character_expression: String = params[4]
			var left_character: String = left_character_name + "_" + left_character_expression
			var right_character: String = right_character_name + "_" + right_character_expression
			
			print("[changesprites] Not implemented yet.")
			sprites_handler.change_characters_visual(left_character, right_character)
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
		print("signal(changesprites,\"leftcharactername\",\"leftcharacterexpression\",\"rightcharactername\",\"rightcharacterexpression\")")
		print("signal(hidesprites)")
		print("signal(hideleftsprite)")
		print("signal(hiderightsprite)")
		print("signal(showsprites)")
		print("signal(showleftsprite)")
		print("signal(showrightsprite)")

func maximize_dialogue_size():
	$text.custom_minimum_size.x = dialogue_width_maximized
	for button in button_cache:
		button.custom_minimum_size.x = dialogue_width_maximized

func minimize_dialogue_size():
	$text.custom_minimum_size.x = dialogue_width_minimized
	for button in button_cache:
		button.custom_minimum_size.x = dialogue_width_minimized
