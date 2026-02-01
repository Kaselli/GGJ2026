extends Node

@onready var panel = $Panel
@onready var mask_text = $Panel/MaskText

@export var mask_display_base_text: String = "You wear the face of the "
@export var display_duration: float = 2.0
@export var fade_duration: float = 1.5
var text_tween: Tween
var panel_tween: Tween

func _ready():
	hide()

func display(mask: String) -> void:
	mask_text.text = mask_display_base_text + mask
	show_temp()

func hide() -> void:
	mask_text.modulate.a = 0.0
	panel.modulate.a = 0.0

func hide_delayed() -> void:
	text_tween = create_tween()
	panel_tween = create_tween()
	text_tween.tween_property(mask_text, "modulate:a", 0.0, fade_duration)
	panel_tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	text_tween.tween_callback(hide)

func show_temp() -> void:
	text_tween = create_tween()
	panel_tween = create_tween()
	text_tween.tween_property(mask_text, "modulate:a", 1.0, fade_duration)
	panel_tween.tween_property(panel, "modulate:a", 1.0, fade_duration)
	text_tween.tween_callback(hide_delayed).set_delay(display_duration)
