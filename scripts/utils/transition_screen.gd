extends CanvasLayer

signal on_transition_complete

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _ready():
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "fade_to_black":
		on_transition_complete.emit()
		animation_player.play("fade_in")
	elif anim_name == "fade_in":
		color_rect.visible = false

func play_transition_out() -> void:
	color_rect.visible = true
	animation_player.play("fade_to_black")

func play_transition_in() -> void:
	color_rect.visible = true
	animation_player.play("fade_in")