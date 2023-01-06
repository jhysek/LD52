extends Node2D


func _ready():
	pass
	#Transition.openScene()


func _on_Start_pressed():
	get_tree().change_scene("res://Scenes/Game.tscn")
	#Transition.switchTo("res://Scenes/Game.tscn")
