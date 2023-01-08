extends Node2D

func _on_Start_pressed():
	LevelSwitcher.start_level()

func _on_Start2_pressed():
	get_tree().change_scene("res://Scenes/Menu.tscn")

