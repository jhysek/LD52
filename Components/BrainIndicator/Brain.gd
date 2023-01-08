extends Sprite

var active = false

func activate():
	active = true
	$AnimationPlayer.play("Activate")

func tween_to(target_pos):
	$Tween.interpolate_property(self, 'position', position, target_pos, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()

func _on_Tween_tween_completed(object, key):
	queue_free()
