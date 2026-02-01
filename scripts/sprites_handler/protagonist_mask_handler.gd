extends Control
var tween: Tween

@onready var masks = {
    "CAT": $Cat,
    "FOX": $Fox,
    "LAMB": $Lamb,
    "SNAKE": $Snake,
    "MANTIS": $Mantis,
    "CONDOR": $Condor
}

func hide_all_masks() -> void:
    if tween:
        tween.stop_all()
        tween = null
    for mask in masks.values():
        mask.hide()
        mask.modulate.a = 1.0

func show_mask(mask_name: String) -> void:
    hide_all_masks()
    var key = mask_name.to_upper()
    if masks.has(key):
        masks[key].show()

func flicker_mask(mask_name: String, duration: float = 1.5) -> void:
    var key = mask_name.to_upper()
    if not masks.has(key): return
    var target = masks[key]
    
    hide_all_masks()
    target.modulate.a = .5
    target.show()

    tween = create_tween()
    # This toggles the visibility rapidly by stepping the property
    for i in range(int(duration * 10)): 
        tween.tween_callback(func(): target.visible = !target.visible)
        tween.tween_interval(randf_range(0.05, 0.15))
    # Ensure it ends in the state you want
    tween.finished.connect(func():
        target.hide()
        target.modulate.a = 1.0
    )
