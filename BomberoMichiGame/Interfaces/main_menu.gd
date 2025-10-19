extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btnNewGame_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/escena_prueba.tscn") 


func _on_btnOptions_pressed() -> void:
	print("settings pressed")


func _on_btnExit_pressed() -> void:
	get_tree().quit() 
