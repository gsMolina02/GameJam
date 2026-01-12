extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ocultar el menú al inicio
	hide()
	# Asegurarse de que el proceso esté activo para detectar input
	set_process_input(true)

# Detectar cuando se presiona ESC
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC es ui_cancel por defecto
		# No permitir pausa si ya hay una pantalla de muerte activa
		if _is_death_screen_active():
			return
		toggle_pause()

# Alternar entre pausa y continuar
func toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	
	# Mostrar cursor cuando está en pausa, ocultarlo cuando continúa
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Verificar si hay una pantalla de muerte activa
func _is_death_screen_active() -> bool:
	# Buscar en la raíz si existe un nodo DeathMenu
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "DeathMenu" or child.get_script() != null and child.get_script().resource_path.contains("death_escene"):
			return true
	return false

# Botón continuar
func _on_btn_continue_pressed() -> void:
	toggle_pause()

# Botón salir al menú principal
func _on_btn_exit_pressed() -> void:
	# Despausar el juego antes de cambiar de escena
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")
