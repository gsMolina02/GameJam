extends Control

var selected_button: int = 0
var buttons: Array = []

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

func update_texts() -> void:
	var base = $GameOver/PanelContainer/MarginContainer/VBoxContainer
	if base.has_node("Label"):  base.get_node("Label").text  = _t("death.game_over")
	if base.has_node("Label2"): base.get_node("Label2").text = _t("death.continue_question")
	var botonera = base.get_node_or_null("botonera")
	if botonera:
		if botonera.has_node("botonYes"): botonera.get_node("botonYes").text = _t("death.yes")
		if botonera.has_node("botonNo"):  botonera.get_node("botonNo").text  = _t("death.no")

func _ready() -> void:


	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	add_to_group("localizable")
	_hide_pause_menu()
	update_texts()

	buttons = [
		$GameOver/PanelContainer/MarginContainer/VBoxContainer/botonera/botonYes,
		$GameOver/PanelContainer/MarginContainer/VBoxContainer/botonera/botonNo
	]

	# Las señales ya están conectadas en el archivo .tscn, no es necesario conectarlas aquí

	# Dar foco al primer botón
	_update_button_focus()

# Ocultar el menú de pausa si existe
func _hide_pause_menu() -> void:
	# Buscar el menú de pausa en el mismo MenusLayer
	var parent = get_parent()
	if parent:
		var pause_menu = parent.get_node_or_null("PuseMenu")
		if pause_menu:
			pause_menu.hide()
			print("✓ PauseMenu ocultado desde DeathMenu")

# Manejar input para navegación con teclado - usar _unhandled_input para mayor prioridad
func _unhandled_input(event: InputEvent) -> void:
	# NO procesar input si el menú no es visible o no está en el árbol
	if not visible or not is_inside_tree():
		return

	# Verificar que el viewport existe antes de usarlo
	var viewport = get_viewport()
	if not viewport:
		return

	# BLOQUEAR ESC para que no active el menú de pausa cuando hay game over
	if event.is_action_pressed("ui_cancel"):
		viewport.set_input_as_handled()
		return

	# Solo procesar input de teclado/gamepad para el menú
	if event.is_action_pressed("ui_left") or event.is_action_pressed("left"):
		selected_button = 0  # Seleccionar "Sí"
		_update_button_focus()
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("right"):
		selected_button = 1  # Seleccionar "No"
		_update_button_focus()
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		# Presionar el botón seleccionado
		_press_selected_button()
		viewport.set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		# Presionar el botón seleccionado con Enter
		_press_selected_button()
		viewport.set_input_as_handled()
	else:
		# Bloquear TODOS los demás inputs mientras el menú está activo
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			viewport.set_input_as_handled()

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


func _on_yes_pressed() -> void:
	# SÍ quiero continuar = Reiniciar el nivel
	if not is_inside_tree():
		return

	get_tree().paused = false

	# Ocultar el MenusLayer padre antes de cambiar de escena
	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = false

	# Usar call_deferred para evitar problemas durante el procesamiento de input
	get_tree().call_deferred("reload_current_scene")
	call_deferred("queue_free")


func _on_no_pressed() -> void:
	# NO quiero continuar = Volver al menú principal
	if not is_inside_tree():
		return

	get_tree().paused = false

	# Ocultar el MenusLayer padre antes de cambiar de escena
	var parent = get_parent()
	if parent and parent.name == "MenusLayer":
		parent.visible = false

	# Usar call_deferred para evitar problemas durante el procesamiento de input
	get_tree().call_deferred("change_scene_to_file", "res://Interfaces/main_menu.tscn")
	call_deferred("queue_free")
