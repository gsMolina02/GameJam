extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ocultar el menú al inicio
	hide()
	# Asegurarse de que el menú funcione durante la pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

# Alternar entre pausa y continuar (llamado por el personaje o los botones)
func toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused

	# Activar/desactivar el MenusLayer padre si existe
	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = is_paused

		# Asegurarse de que el DeathMenu esté oculto cuando se activa la pausa
		if is_paused:
			var death_menu = parent.get_node_or_null("DeathMenu")
			if death_menu:
				death_menu.visible = false

	# Mostrar cursor cuando está en pausa, ocultarlo cuando continúa
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Botón continuar
func _on_btn_continue_pressed() -> void:
	toggle_pause()

# Botón salir al menú principal
func _on_btn_exit_pressed() -> void:
	# Despausar el juego antes de cambiar de escena
	get_tree().paused = false

	# Ocultar el MenusLayer antes de cambiar de escena
	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = false

	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
