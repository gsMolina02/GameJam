extends Node2D

# Configuración del diálogo
@export var nombre_gato: String = "Miel"
@export var mensaje_agradecimiento: String = "¡Miau! Gracias por salvarme~"
@export var mostrar_dialogo_automatico: bool = true

# Referencias
var dialogo_activo: bool = false
var jugador_cerca: bool = false
var label_interactuar: Label = null
var dialogo_ui: Control = null

# Señal para cuando el jugador interactúa
signal dialogo_iniciado
signal dialogo_terminado

func _ready():
	# Configurar para que funcione durante pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Agregar al grupo de gatos salvados
	add_to_group("gatos_salvados")
	print("🐱 Gato", nombre_gato, "agregado al grupo 'gatos_salvados'")
	
	# Crear label de interacción
	label_interactuar = Label.new()
	label_interactuar.text = "[F] Hablar"
	label_interactuar.position = Vector2(-30, -80)
	label_interactuar.visible = false
	label_interactuar.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label_interactuar)
	
	# Buscar el Area2D de interacción (debe estar en la escena)
	if has_node("InteractionArea"):
		var area = $InteractionArea
		area.body_entered.connect(_on_interaction_area_body_entered)
		area.body_exited.connect(_on_interaction_area_body_exited)
	
	print("🐱 Gato", nombre_gato, "salvado apareció en la escena")
	
	# Solo mostrar diálogo automático si está configurado
	# El RoomManager puede desactivar esto para controlarlo manualmente
	if mostrar_dialogo_automatico:
		await get_tree().create_timer(0.5).timeout
		_mostrar_dialogo()

func _physics_process(_delta: float) -> void:
	# Detectar si el jugador presiona F cuando está cerca
	if jugador_cerca and not dialogo_activo:
		if Input.is_action_just_pressed("interact"):
			_mostrar_dialogo()

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_main"):
		jugador_cerca = true
		if label_interactuar and not dialogo_activo:
			label_interactuar.visible = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_main"):
		jugador_cerca = false
		if label_interactuar:
			label_interactuar.visible = false

func _mostrar_dialogo() -> void:
	if dialogo_activo:
		print("⚠️ Diálogo ya está activo")
		return
	
	print("💬 Mostrando diálogo del gato:", nombre_gato)
	print("  Mensaje:", mensaje_agradecimiento)
	
	dialogo_activo = true
	emit_signal("dialogo_iniciado")
	
	# Pausar el juego para que el jugador lea
	get_tree().paused = true
	print("⏸️ Juego pausado para el diálogo")
	
	# Ocultar label de interacción
	if label_interactuar:
		label_interactuar.visible = false
	
	# Crear UI de diálogo
	_crear_dialogo_ui()

func _crear_dialogo_ui() -> void:
	print("🎨 Creando UI del diálogo...")
	
	# Crear CanvasLayer para que aparezca sobre toda la pantalla
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogoCanvasLayer"
	canvas_layer.layer = 100  # Asegurar que esté encima de todo
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS  # Funcionar durante pausa
	
	# Crear contenedor principal
	dialogo_ui = Control.new()
	dialogo_ui.name = "DialogoGato"
	dialogo_ui.set_anchors_preset(Control.PRESET_FULL_RECT)  # Ocupar toda la pantalla
	canvas_layer.add_child(dialogo_ui)
	
	# Panel de fondo semi-transparente para toda la pantalla
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)  # Negro semi-transparente
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogo_ui.add_child(overlay)
	
	# Panel del diálogo (centrado en la pantalla)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(500, 150)
	panel.position = Vector2(400, 250)  # Centrado aproximado (ajustar según resolución)
	panel.size = Vector2(500, 150)
	dialogo_ui.add_child(panel)
	
	# Contenedor vertical
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.custom_minimum_size = Vector2(460, 110)
	panel.add_child(vbox)
	
	# Label del nombre
	var nombre_label = Label.new()
	nombre_label.text = "🐱 Gato " + nombre_gato + ":"
	nombre_label.add_theme_color_override("font_color", Color.ORANGE)
	nombre_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(nombre_label)
	
	# Espaciador
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# Label del mensaje
	var mensaje_label = Label.new()
	mensaje_label.text = mensaje_agradecimiento
	mensaje_label.add_theme_color_override("font_color", Color.WHITE)
	mensaje_label.add_theme_font_size_override("font_size", 18)
	mensaje_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mensaje_label.custom_minimum_size.x = 460
	vbox.add_child(mensaje_label)
	
	# Espaciador
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Label de instrucción
	var instruccion_label = Label.new()
	instruccion_label.text = "🔑 [Presiona F para continuar]"
	instruccion_label.add_theme_color_override("font_color", Color.YELLOW)
	instruccion_label.add_theme_font_size_override("font_size", 16)
	instruccion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruccion_label)
	
	# Agregar a la escena principal (no al gato)
	get_tree().root.add_child(canvas_layer)
	print("✅ UI del diálogo agregada a la pantalla")
	
	# Esperar a que el jugador presione F para cerrar
	_esperar_cerrar_dialogo(canvas_layer)

func _esperar_cerrar_dialogo(canvas_layer: CanvasLayer) -> void:
	print("⏳ Esperando que el jugador presione F para cerrar...")
	
	# Esperar a que presione F de nuevo
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact"):
			print("🔑 Jugador presionó F - Cerrando diálogo")
			break
	
	_cerrar_dialogo(canvas_layer)

func _cerrar_dialogo(canvas_layer: CanvasLayer) -> void:
	print("✅ Diálogo del gato cerrado")
	
	# Eliminar el CanvasLayer completo (que contiene la UI)
	if canvas_layer:
		canvas_layer.queue_free()
	
	dialogo_ui = null
	dialogo_activo = false
	
	# Despausar el juego
	get_tree().paused = false
	print("▶️ Juego reanudado")
	
	emit_signal("dialogo_terminado")
	
	# Si el jugador sigue cerca, mostrar label de nuevo
	if jugador_cerca and label_interactuar:
		label_interactuar.visible = true

func cambiar_mensaje(nuevo_mensaje: String) -> void:
	"""Permite cambiar el mensaje del gato"""
	mensaje_agradecimiento = nuevo_mensaje
