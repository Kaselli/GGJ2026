extends Control # Or Panel, if specifically a panel

@onready var character_name_label = $name_text

func set_speaking_character_name(character_name: String):
    if character_name == "":
        hide_speaking_character_name_ui()
    else:
        # Show the panel and set the text
        self.show() 
        character_name_label.text = character_name
        # Reset transparency if you previously keyed it to 0
        character_name_label.modulate.a = 1.0 

func hide_speaking_character_name_ui():
    character_name_label.text = ""
    # Hide the entire panel/node
    self.hide()