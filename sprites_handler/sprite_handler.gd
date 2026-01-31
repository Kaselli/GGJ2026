extends Node


@onready var left_sprite = $LeftSprite
@onready var right_sprite = $RightSprite

func change_characters_visual(left_character: String, right_character: String) -> void:
	if left_character != "":
		left_sprite.texture = load("res://sprites/" + left_character + ".png")
		left_sprite.show()
	else:
		left_sprite.hide()
	
	if right_character != "":
		right_sprite.texture = load("res://sprites/" + right_character + ".png")
		right_sprite.show()
	else:
		right_sprite.hide()

func hide_all_sprites() -> void:
	left_sprite.hide()
	right_sprite.hide()

func hide_left_sprite() -> void:
	left_sprite.hide()

func hide_right_sprite() -> void:
	right_sprite.hide()

func show_all_sprites() -> void:
	left_sprite.show()
	right_sprite.show()

func show_left_sprite() -> void:
	left_sprite.show()

func show_right_sprite() -> void:
	right_sprite.show()
