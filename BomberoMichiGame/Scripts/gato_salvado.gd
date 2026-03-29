extends Node2D

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

# Configuración del diálogo
@export var nombre_gato: String = "Miel"
@export var mensaje_agradecimiento: String = "¡Miau! Gracias por salvarme~"
@export var mostrar_dialogo_automatico: bool = true

# Referencias
var dialogo_activo: bool = false
var jugador_cerca: bool = false
var label_interactuar: Label = null
var dialogo_ui: Control = null
var animated_sprite: AnimatedSprite2D = null

# Control del rescate
var fuego_apagado: bool = false
var enemigos_derrotados: bool = false
var dialogo_final_mostrado: bool = false

# Señal para cuando el jugador interactúa
signal dialogo_iniciado
signal dialogo_terminado

func _ready():
	# Configurar para que funcione durante pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Agregar al grupo de gatos salvados
	add_to_group("gatos_salvados")
	add_to_group("localizable")
	print("🐱 Gato", nombre_gato, "agregado al grupo 'gatos_salvados'")

	label_interactuar = Label.new()
	label_interactuar.text = _t("npc.talk")
	label_interactuar.position = Vector2(-30, -80)
	label_interactuar.visible = false
	label_interactuar.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label_interactuar)
	
	# Buscar el AnimatedSprite2D para controlar la animación
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D
	else:
		# Buscar en hijos si no está directamente
		for child in get_children():
			if child is AnimatedSprite2D:
				animated_sprite = child
				break
	
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
	# Verificar si se completó el rescate (fuego apagado y enemigos derrotados)
	if fuego_apagado and enemigos_derrotados and not dialogo_final_mostrado:
		_detener_animacion()
		_mostrar_dialogo_final()
		dialogo_final_mostrado = true
	
	# Detectar si el jugador presiona F cuando está cerca
	if jugador_cerca and not dialogo_activo:
		if Input.is_action_just_pressed("interact"):
			_mostrar_dialogo()

func update_texts() -> void:
	if label_interactuar:
		label_interactuar.text = _t("npc.talk")

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
	
	# Limpiar cualquier diálogo anterior que pueda estar en la escena
	_limpiar_dialogos_anteriores()
	
	print("💬 Mostrando diálogo del gato:", nombre_gato)
	print("  Mensaje:", mensaje_agradecimiento)
	
	dialogo_activo = true
	emit_signal("dialogo_iniciado")
	
	# NO pausar el juego - el diálogo se muestra mientras el juego continúa
	
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
	canvas_layer.add_to_group("dialogo_gato")  # Agregar al grupo para limpieza
	
	# Crear contenedor principal
	dialogo_ui = Control.new()
	dialogo_ui.name = "DialogoGato"
	dialogo_ui.set_anchors_preset(Control.PRESET_FULL_RECT)  # Ocupar toda la pantalla
	canvas_layer.add_child(dialogo_ui)
	
	# Panel del diálogo (encima del gato)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 100)
	# Posicionar encima del gato
	var pos_gato = global_position
	panel.position = Vector2(pos_gato.x - 200, pos_gato.y - 150)  # Encima del gato
	panel.size = Vector2(400, 100)
	
	# Estilo del panel - fondo semi-transparente oscuro
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.85)  # Gris muy oscuro semi-transparente
	style_box.border_color = Color(1, 0.6, 0, 0.9)  # Naranja (tema bombero)
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style_box)
	dialogo_ui.add_child(panel)
	
	# Contenedor vertical
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(15, 15)
	vbox.custom_minimum_size = Vector2(370, 70)
	panel.add_child(vbox)
	
	# Label del nombre
	var nombre_label = Label.new()
	nombre_label.text = "🐱 " + nombre_gato + ":"
	nombre_label.add_theme_color_override("font_color", Color(1, 0.6, 0))  # Naranja
	nombre_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(nombre_label)
	
	# Espaciador pequeño
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer1)
	
	# Label del mensaje
	var mensaje_label = Label.new()
	mensaje_label.text = mensaje_agradecimiento
	mensaje_label.add_theme_color_override("font_color", Color.WHITE)
	mensaje_label.add_theme_font_size_override("font_size", 15)
	mensaje_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mensaje_label.custom_minimum_size.x = 370
	vbox.add_child(mensaje_label)
	
	# El diálogo se cerrará automáticamente en 3 segundos
	# No se necesita instrucción de presionar F
	
	# Agregar a la escena principal (no al gato)
	get_tree().root.add_child(canvas_layer)
	print("✅ UI del diálogo agregada a la pantalla")
	
	# Cerrar automáticamente después de 3 segundos
	# Usar un Timer en lugar de await para evitar problemas si el nodo se elimina
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): 
		if is_instance_valid(canvas_layer):
			_cerrar_dialogo(canvas_layer)
	)

func _limpiar_dialogos_anteriores() -> void:
	"""Elimina cualquier diálogo anterior que pueda estar en la escena"""
	var dialogos_anteriores = get_tree().get_nodes_in_group("dialogo_gato")
	for dialogo in dialogos_anteriores:
		if dialogo:
			dialogo.queue_free()
	print("🧹 Limpiados", dialogos_anteriores.size(), "diálogos anteriores")

func _cerrar_dialogo(canvas_layer: CanvasLayer) -> void:
	print("✅ Diálogo del gato cerrado")
	
	# Eliminar el CanvasLayer completo (que contiene la UI)
	if canvas_layer and is_instance_valid(canvas_layer):
		canvas_layer.queue_free()
	
	dialogo_ui = null
	dialogo_activo = false
	
	# El juego nunca se pausó, así que no hay que despausarlo
	
	emit_signal("dialogo_terminado")
	
	# Si el jugador sigue cerca, mostrar label de nuevo
	if jugador_cerca and label_interactuar:
		label_interactuar.visible = true

func cambiar_mensaje(nuevo_mensaje: String) -> void:
	"""Permite cambiar el mensaje del gato"""
	mensaje_agradecimiento = nuevo_mensaje

func _detener_animacion() -> void:
	"""Detiene la animación del gato cuando el fuego está apagado"""
	if animated_sprite:
		animated_sprite.stop()
		# Dejar en el último frame de la animación actual
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) - 1
		print("🛑 Animación del gato detenida en frame:", animated_sprite.frame)

func marcar_fuego_apagado() -> void:
	"""Llamar desde el script del fuego cuando sea apagado"""
	fuego_apagado = true
	print("🔥 Fuego apagado registrado en gato", nombre_gato)

func marcar_enemigos_derrotados() -> void:
	"""Llamar cuando todos los enemigos sean derrotados"""
	enemigos_derrotados = true
	print("⚔️ Enemigos derrotados registrados en gato", nombre_gato)

func _mostrar_dialogo_final() -> void:
	"""Muestra el diálogo final de agradecimiento cuando todo está completado"""
	print("💬 Mostrando diálogo FINAL del gato:", nombre_gato)
	
	# Limpiar cualquier diálogo anterior que pueda estar en la escena
	_limpiar_dialogos_anteriores()
	
	dialogo_activo = true
	emit_signal("dialogo_iniciado")
	
	# Crear UI de diálogo final
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogoFinalCanvasLayer"
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_to_group("dialogo_gato")  # Agregar al grupo para limpieza
	
	dialogo_ui = Control.new()
	dialogo_ui.name = "DialogoFinalGato"
	dialogo_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(dialogo_ui)
	
	# Panel del diálogo (encima del gato)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(450, 120)
	# Posicionar encima del gato
	var pos_gato = global_position
	panel.position = Vector2(pos_gato.x - 225, pos_gato.y - 170)  # Encima del gato
	panel.size = Vector2(450, 120)
	
	# Estilo del panel - fondo semi-transparente oscuro
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.15, 0.05, 0.9)  # Verde muy oscuro (rescate exitoso)
	style_box.border_color = Color(0.2, 1, 0.3, 1)  # Verde brillante (éxito)
	style_box.border_width_left = 4
	style_box.border_width_right = 4
	style_box.border_width_top = 4
	style_box.border_width_bottom = 4
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style_box)
	dialogo_ui.add_child(panel)
	
	# Contenedor vertical
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(15, 15)
	vbox.custom_minimum_size = Vector2(420, 90)
	panel.add_child(vbox)
	
	# Label del nombre
	var nombre_label = Label.new()
	nombre_label.text = "🐱✨ " + nombre_gato
	nombre_label.add_theme_color_override("font_color", Color(0.3, 1, 0.4))  # Verde claro
	nombre_label.add_theme_font_size_override("font_size", 20)
	nombre_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nombre_label)
	
	# Espaciador
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer1)
	
	# Label del mensaje final
	var mensaje_label = Label.new()
	mensaje_label.text = "¡Gracias por salvarme! 💕\n¡Eres mi héroe!"
	mensaje_label.add_theme_color_override("font_color", Color.WHITE)
	mensaje_label.add_theme_font_size_override("font_size", 16)
	mensaje_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mensaje_label.custom_minimum_size.x = 420
	mensaje_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(mensaje_label)
	
	# Agregar a la escena
	get_tree().root.add_child(canvas_layer)
	print("✅ Diálogo FINAL agregado a la pantalla")
	
	# Cerrar automáticamente después de 3 segundos
	# Usar un Timer en lugar de await para evitar problemas si el nodo se elimina
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): 
		if is_instance_valid(canvas_layer):
			_cerrar_dialogo(canvas_layer)
	)
