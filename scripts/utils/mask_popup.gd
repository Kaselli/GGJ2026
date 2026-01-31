extends Node

@onready var mask_text = $MaskText
@onready var popup_bg = $PopupBG

@export var mask_display_base_text: String = "You wear the face of the "
@export var display_duration: float = 2.0
@export var fade_duration: float = 1.5
var tween: Tween

func _ready():
	hide()

func display(mask: String) -> void:
	#var mask_loaded = load("res://sprites/" + mask + ".png")
	#if mask_loaded == null:
		#print("Error: Could not load mask sprite: " + mask)
		#hide()
	#else:
	mask_text.text = mask_display_base_text +mask
	show_temp()

func hide() -> void:
	popup_bg.modulate.a = 0.0
	mask_text.modulate.a = 0.0

func hide_delayed() -> void:
	tween = create_tween()
	tween.tween_property(popup_bg, "modulate:a", 0.0, fade_duration)
	tween.tween_property(mask_text, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(hide)

func show_temp() -> void:
	tween = create_tween()
	tween.tween_property(popup_bg, "modulate:a", 1.0, fade_duration)
	tween.tween_property(mask_text, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(hide_delayed).set_delay(display_duration)