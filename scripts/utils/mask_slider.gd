extends Control

@onready var sprite = $MaskSprite

@export var observed_state_name: String = "other_mask"
var max_slider_value: int = 6
@export var min_x: float = 1920 * 0.2
@export var max_x: float = 1920 * 0.8
@export var transparency_modulation_power: float = 2.5

func _ready():
	sprite.position.x = max_x
	sprite.modulate.a = 0.0
	# Connect to the parent's signal
	get_parent().get_parent().connect("state_changed", self._on_value_changed)
	# Connect to signal from another class
	# signal_source.value_changed.connect(_on_value_changed)

func init_slider(max_value: int):
	if max_value <= 0:
		print("Error: max_value must be greater than 0. Setting to default value of 1.")
		max_value = 1
	max_slider_value = max_value

func _on_value_changed(state_name: String, value: int):
	if state_name != observed_state_name:
		return
	
	var alpha = pow(value / float(max_slider_value), transparency_modulation_power)
	var tween_alpha = create_tween()
	tween_alpha.tween_property(sprite, "modulate:a", alpha, 1.0)
	
	var target_x = lerp(max_x, min_x, value / float(max_slider_value))
	var tween = create_tween()
	tween.tween_property(sprite, "position:x", target_x, 1.0)
