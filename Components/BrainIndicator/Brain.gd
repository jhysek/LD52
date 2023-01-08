extends Sprite

var active = false

func activate():
	active = true
	$AnimationPlayer.play("Activate")
