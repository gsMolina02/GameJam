extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameOver/PanelContainer/MarginContainer/VBoxContainer/botonera/botonYes.connect("pressed", Callable(self, "_on_yes_pressed"))
	$GameOver/PanelContainer/MarginContainer/VBoxContainer/botonera/botonNo.connect("pressed", Callable(self, "_on_no_pressed"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_no_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")


func _on_yes_pressed() -> void:
	get_tree().reload_current_scene()
