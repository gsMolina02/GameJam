extends Control

# Índice del botón seleccionado (0 = Sí, 1 = No)
var selected_button: int = 0
var buttons: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Asegurarse de que esta UI funcione incluso cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ocultar el menú de pausa si estaba visible
	_hide_pause_menu()
	
	# Obtener referencias a los botones
	buttons = [
		$GameOver/PanelContainer/MarginContainer/VBoxContainer/botonera/botonYes,
		$GameOver/PanelContainer/MarginContainer/VBoxContainer/botonera/botonNo
	]
	
	# Conectar señales de los botones
	buttons[0].connect("pressed", Callable(self, "_on_yes_pressed"))
	buttons[1].connect("pressed", Callable(self, "_on_no_pressed"))
	
	# Dar foco al primer botón
	_update_button_focus()

# Ocultar el menú de pausa si existe
func _hide_pause_menu() -> void:
	var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.hide()

# Manejar input para navegación con teclado - usar _unhandled_input para mayor prioridad
func _unhandled_input(event: InputEvent) -> void:
	# Solo procesar input de teclado/gamepad para el menú
	if event.is_action_pressed("ui_left") or event.is_action_pressed("left"):
		selected_button = 0  # Seleccionar "Sí"
		_update_button_focus()
		get_viewport().set_input_as_handled()
		accept_event()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("right"):
		selected_button = 1  # Seleccionar "No"
		_update_button_focus()
		get_viewport().set_input_as_handled()
		accept_event()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		# Presionar el botón seleccionado
		_press_selected_button()
		get_viewport().set_input_as_handled()
		accept_event()
	else:
		# Bloquear TODOS los demás inputs mientras el menú está activo
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
			accept_event()

# Actualizar el foco visual del botón
func _update_button_focus() -> void:
	for i in range(buttons.size()):
		if i == selected_button:
			buttons[i].grab_focus()
		else:
			buttons[i].release_focus()

# Presionar el botón actualmente seleccionado
func _press_selected_button() -> void:
	if selected_button == 0:
		_on_yes_pressed()
	else:
		_on_no_pressed()


func _on_no_pressed() -> void:
	# Despausar el juego
	get_tree().paused = false
	# Eliminar este menú antes de cambiar de escena
	queue_free()
	# Cambiar al menú principal
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")


func _on_yes_pressed() -> void:
	# Despausar el juego
	get_tree().paused = false
	# Eliminar este menú antes de reiniciar
	queue_free()
	# Reiniciar la escena actual
	get_tree().reload_current_scene()
