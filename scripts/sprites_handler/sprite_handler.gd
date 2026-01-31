extends Node


@onready var left_sprite = $LeftSprite
@onready var right_sprite = $RightSprite

func change_left_character_visual(left_character: String) -> void:
	if left_character != "":
		var left_sprite_loaded = load("res://sprites/" + left_character + ".png")
		if left_sprite_loaded == null:
			print("Error: Could not load left character sprite: " + left_character)
			hide_left_sprite()
		else:
			left_sprite.texture = left_sprite_loaded
			show_left_sprite()
	else:
		print("Error: Left character string is empty.")
		hide_left_sprite()

func change_right_character_visual(right_character: String) -> void:
	if right_character != "":
		var right_sprite_loaded = load("res://sprites/" + right_character + ".png")
		if right_sprite_loaded == null:
			print("Error: Could not load right character sprite: " + right_character)
			hide_right_sprite()
		else:
			right_sprite.texture = right_sprite_loaded
			show_right_sprite()
	else:
		print("Error: Right character string is empty.")
		hide_right_sprite()

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
