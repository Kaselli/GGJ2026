extends Node

@export var base_escape_text: String = "Hold ESCAPE to quit the game"
@onready var escape_label = $QuitLabel

var escape_held_time = 0.0
const ESCAPE_HOLD_DURATION = 3.0

func _ready() -> void:
	escape_label.text = base_escape_text
	escape_label.visible = false

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		escape_held_time += delta
		
		if escape_held_time >= ESCAPE_HOLD_DURATION:
			get_tree().quit()
		var dots = int(escape_held_time / ((ESCAPE_HOLD_DURATION - 0.5) / 3.0)) % 4
		var dot_string = ".".repeat(dots)
		escape_label.text = base_escape_text + dot_string
		escape_label.visible = true
			
	else:
		escape_held_time = 0.0
		escape_label.text = base_escape_text
		escape_label.visible = false
