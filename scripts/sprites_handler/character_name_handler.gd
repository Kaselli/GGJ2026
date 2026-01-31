extends Node

@onready var character_name_label = $name_text

func set_speaking_character_name(character_name: String):
	if character_name == "":
		hide_speaking_character_name_ui()
	else:
		character_name_label.text = character_name
		character_name_label.modulate = Color.WHITE

func hide_speaking_character_name_ui():
	character_name_label.text = ""
	character_name_label.modulate = Color.TRANSPARENT