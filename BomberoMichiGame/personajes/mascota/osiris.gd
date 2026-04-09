extends CharacterBody2D
# Script para Osiris en el nivel Osiris
# Se queda quieto hasta que interactúes → muestra diálogo → ilumina puerta → comienza a seguir

@export var nombre_gato: String = "Osiris"
@export var mensaje_habilidad: String = "¡Habilidades Adquiridas:\n• Agua Recargable\n• Mejor Capacidad Pulmonar!"
@export var portrait_texture: Texture2D = null
@export var velocidad_movimiento: float = 400.0
@export var distancia_minima_seguimiento: float = 80.0

# Estado de Osiris
var siguiendo: bool = false
var puede_interactuar: bool = true
var dialogo_activo: bool = false
var jugador_cerca: bool = false
var label_interactuar: Label = null
var animated_sprite: AnimatedSprite2D = null
var puerta_iluminada: bool = false
var flecha_nodo: Label = null

# Referencias
var puerta_nodo: Node = null

const INTERACT_RADIUS := 130.0

signal dialogo_iniciado
signal dialogo_terminado
signal habilidad_adquirida

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("mascota")
	
	# Buscar el AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D
	else:
		for child in get_children():
			if child is AnimatedSprite2D:
				animated_sprite = child
				break
	
	# Registrar tecla E para interacción
	if not InputMap.has_action("interact_cat"):
		InputMap.add_action("interact_cat")
	
	var tiene_e := false
	for ev in InputMap.action_get_events("interact_cat"):
		if ev is InputEventKey and ev.keycode == KEY_E:
			tiene_e = true
			break
	
	if not tiene_e:
		var e_key := InputEventKey.new()
		e_key.keycode = KEY_E
		InputMap.action_add_event("interact_cat", e_key)
	
	# Crear label de interacción
	label_interactuar = Label.new()
	label_interactuar.text = "[E] Hablar"
	label_interactuar.visible = false
	label_interactuar.add_theme_color_override("font_color", Color.YELLOW)
	label_interactuar.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label_interactuar.add_theme_constant_override("outline_size", 3)
	label_interactuar.add_theme_font_size_override("font_size", 14)
	
	if animated_sprite:
		label_interactuar.position = animated_sprite.position + Vector2(-28, -50)
	else:
		label_interactuar.position = Vector2(-28, -80)
	
	add_child(label_interactuar)
	
	# Buscar la puerta
	_buscar_puerta()
	
	# Crear flecha de interacción inmediatamente (verde animada)
	_crear_flecha_interaccion()
	
	print("🐱 Osiris listo en nivel Osiris - ESPERANDO INTERACCIÓN")

func _buscar_puerta() -> void:
	"""Busca la puerta en la escena para iluminarla después"""
	var scene = get_tree().current_scene
	if scene:
		# Intentar diferentes nombres de puerta
		puerta_nodo = scene.find_child("Salida", true, false)
		if not puerta_nodo:
			puerta_nodo = scene.find_child("Puerta", true, false)
		if not puerta_nodo:
			puerta_nodo = scene.find_child("Door", true, false)
		if not puerta_nodo:
			puerta_nodo = scene.find_child("SalidaCueva", true, false)
		
		if puerta_nodo:
			print("✅ Puerta encontrada:", puerta_nodo.name)
		else:
			print("⚠️ Puerta no encontrada en la escena")

func _physics_process(delta: float) -> void:
	# Detectar proximidad del jugador
	var ref_pos = animated_sprite.global_position if animated_sprite else global_position
	var players = get_tree().get_nodes_in_group("player_main")
	jugador_cerca = false
	
	for p in players:
		if ref_pos.distance_to(p.global_position) <= INTERACT_RADIUS:
			jugador_cerca = true
			break
	
	# Mostrar/ocultar label de interacción
	if label_interactuar:
		label_interactuar.visible = jugador_cerca and not dialogo_activo and puede_interactuar and not siguiendo
	
	# Detectar tecla E para interacción
	if jugador_cerca and not dialogo_activo and puede_interactuar and not siguiendo:
		if Input.is_action_just_pressed("interact_cat"):
			_iniciar_interaccion()
	
	# Movimiento: según estado
	if siguiendo and not dialogo_activo:
		_seguir_jugador(delta, players)
	else:
		# Quieto esperando
		velocity = Vector2.ZERO
	
	move_and_slide()

func _seguir_jugador(delta: float, players: Array) -> void:
	"""Osiris sigue al jugador"""
	if players.is_empty():
		velocity = Vector2.ZERO
		return
	
	var jugador = players[0]
	var distancia = global_position.distance_to(jugador.global_position)
	
	if distancia > distancia_minima_seguimiento:
		var direccion = (jugador.global_position - global_position).normalized()
		velocity = direccion * velocidad_movimiento
	else:
		velocity = Vector2.ZERO
	
	# Reproducir animación de caminar
	if animated_sprite and velocity != Vector2.ZERO:
		if animated_sprite.animation != "GhostCat":
			animated_sprite.animation = "GhostCat"
		if not animated_sprite.is_playing():
			animated_sprite.play()

func _iniciar_interaccion() -> void:
	"""Inicia la interacción con Osiris"""
	print("🐱 ¡ Interactuando con Osiris !")
	
	puede_interactuar = false
	dialogo_activo = true
	emit_signal("dialogo_iniciado")
	
	# Mostrar el diálogo de habilidad
	_mostrar_dialogo_habilidad()
	
	# Esperar 10 segundos para que el jugador lea el mensaje
	await get_tree().create_timer(10.0).timeout
	
	# Eliminar el diálogo cuando termine
	var dialogos = get_tree().get_nodes_in_group("dialogo_habilidad")
	for d in dialogos:
		if d:
			d.queue_free()
	
	# Iluminar la puerta
	await _iluminar_puerta()
	
	# Registrar que Osiris fue rescatado
	GameManager.rescatar_gato(nombre_gato)
	
	# Osiris comienza a seguir
	siguiendo = true
	emit_signal("habilidad_adquirida")
	
	dialogo_activo = false
	print("✅ Osiris ahora está siguiendo al jugador")

func _mostrar_dialogo_habilidad() -> void:
	"""Muestra el diálogo de habilidad con el mismo estilo que los demás gatos (pergamino con portrait)"""
	print("💬 Mostrando diálogo de habilidad")

	# Limpiar diálogos anteriores
	var dialogos = get_tree().get_nodes_in_group("dialogo_habilidad")
	for d in dialogos:
		if d:
			d.queue_free()

	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogoHabilidadLayer"
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_to_group("dialogo_habilidad")

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control)

	var vp = get_viewport().get_visible_rect().size

	const BOX_H      := 150.0
	const BOX_W      := 620.0
	const BANNER_H   := 28.0
	const PORTRAIT_W := 90.0
	var   box_x       = (vp.x - BOX_W) * 0.5

	var box = Panel.new()
	box.position = Vector2(box_x, vp.y - BOX_H - 10.0)
	box.size     = Vector2(BOX_W, BOX_H)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color                   = Color(0.86, 0.77, 0.57, 0.97)
	pstyle.border_color               = Color(0.42, 0.25, 0.07)
	pstyle.border_width_left          = 3
	pstyle.border_width_right         = 3
	pstyle.border_width_top           = 3
	pstyle.border_width_bottom        = 3
	pstyle.corner_radius_top_left     = 10
	pstyle.corner_radius_top_right    = 10
	pstyle.corner_radius_bottom_left  = 10
	pstyle.corner_radius_bottom_right = 10
	pstyle.shadow_color  = Color(0, 0, 0, 0.45)
	pstyle.shadow_size   = 6
	pstyle.shadow_offset = Vector2(2, 3)
	box.add_theme_stylebox_override("panel", pstyle)
	control.add_child(box)

	# Banner con nombre del gato
	var banner = Panel.new()
	banner.position = Vector2(0, 0)
	banner.size     = Vector2(BOX_W, BANNER_H)
	var bstyle = StyleBoxFlat.new()
	bstyle.bg_color                   = Color(0.22, 0.12, 0.03, 0.96)
	bstyle.corner_radius_top_left     = 10
	bstyle.corner_radius_top_right    = 10
	bstyle.corner_radius_bottom_left  = 0
	bstyle.corner_radius_bottom_right = 0
	banner.add_theme_stylebox_override("panel", bstyle)
	box.add_child(banner)

	var lbl_name = Label.new()
	lbl_name.text = "  " + nombre_gato
	lbl_name.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl_name.add_theme_color_override("font_color", Color(1.0, 0.87, 0.45))
	lbl_name.add_theme_font_size_override("font_size", 15)
	banner.add_child(lbl_name)

	# Portrait del gato
	var portrait_rect = TextureRect.new()
	portrait_rect.position     = Vector2(8, BANNER_H + 6)
	portrait_rect.size         = Vector2(PORTRAIT_W, BOX_H - BANNER_H - 12)
	portrait_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if portrait_texture:
		portrait_rect.texture = portrait_texture
	elif animated_sprite and animated_sprite.sprite_frames:
		portrait_rect.texture = animated_sprite.sprite_frames.get_frame_texture(
			animated_sprite.animation, 0)
	box.add_child(portrait_rect)

	# Área de mensaje a la derecha del portrait
	var msg_x = PORTRAIT_W + 14
	var msg_margin = MarginContainer.new()
	msg_margin.position = Vector2(msg_x, BANNER_H)
	msg_margin.size     = Vector2(BOX_W - msg_x - 6, BOX_H - BANNER_H)
	msg_margin.add_theme_constant_override("margin_left",   8)
	msg_margin.add_theme_constant_override("margin_right",  8)
	msg_margin.add_theme_constant_override("margin_top",    10)
	msg_margin.add_theme_constant_override("margin_bottom", 10)
	box.add_child(msg_margin)

	var lbl_msg = Label.new()
	lbl_msg.text                = mensaje_habilidad
	lbl_msg.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_msg.add_theme_color_override("font_color", Color(0.14, 0.07, 0.02))
	lbl_msg.add_theme_font_size_override("font_size", 14)
	msg_margin.add_child(lbl_msg)

	# Flecha indicadora abajo a la derecha
	var arrow_lbl = Label.new()
	arrow_lbl.text     = "▼"
	arrow_lbl.position = Vector2(BOX_W - 24, BOX_H - 22)
	arrow_lbl.add_theme_color_override("font_color", Color(0.42, 0.25, 0.07, 0.8))
	arrow_lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(arrow_lbl)

	get_tree().root.add_child(canvas_layer)
	print("✅ Diálogo de Osiris mostrado con estilo pergamino + portrait")

func _iluminar_puerta() -> void:
	"""Ilumina la puerta cuando se adquiere la habilidad - con animación suave"""
	if not puerta_nodo:
		print("⚠️ No hay puerta para iluminar")
		return
	
	print("🚪 Iniciando apertura suave de puerta...")
	puerta_iluminada = true
	
	# Llamar al método de animación de la puerta si existe
	if puerta_nodo.has_method("animar_apertura"):
		await puerta_nodo.animar_apertura()
		print("✅ Animación de puerta completada")
	else:
		print("⚠️ El nodo puerta no tiene método animar_apertura")


func _crear_flecha_interaccion() -> void:
	"""Flecha verde animada encima de Osiris que indica que puede interactuar"""
	if flecha_nodo and is_instance_valid(flecha_nodo):
		return
	
	flecha_nodo = Label.new()
	flecha_nodo.text = "▼"
	flecha_nodo.add_theme_color_override("font_color", Color(0.15, 0.95, 0.25))  # Verde brillante
	flecha_nodo.add_theme_color_override("font_outline_color", Color(0.0, 0.25, 0.0))  # Verde oscuro
	flecha_nodo.add_theme_constant_override("outline_size", 4)
	flecha_nodo.add_theme_font_size_override("font_size", 24)
	
	var base_pos: Vector2
	if animated_sprite:
		base_pos = animated_sprite.position + Vector2(-6, -35)
	else:
		base_pos = Vector2(-6, -80)
	
	flecha_nodo.position = base_pos
	add_child(flecha_nodo)
	
	# Animación de rebote suave
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(flecha_nodo, "position:y", base_pos.y - 12, 0.45).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flecha_nodo, "position:y", base_pos.y,      0.45).set_ease(Tween.EASE_IN_OUT)
	print("✅ Flecha verde de interacción creada encima de Osiris")

func detener_seguimiento() -> void:
	"""Detiene el seguimiento de Osiris"""
	siguiendo = false
	velocity = Vector2.ZERO
	print("🛑 Osiris dejó de seguir")
