extends Node2D

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

# Configuración del diálogo
@export var nombre_gato: String = "Miel"
@export var mensaje_agradecimiento: String = "¡Miau! Gracias por salvarme~"
@export var mensaje_agradecimiento_key: String = "cat.rescue_message"  # Clave de traducción
@export var mensaje_rescate: String = "¡Dirígete a la luz que acaba de aparecer para ir al siguiente nivel!"  # Mensaje custom al rescatar
@export var mostrar_dialogo_automatico: bool = true
@export var portrait_texture: Texture2D = null   # Foto del gato para la caja de diálogo
@export var tipo_poder: String = "resistencia_pulmonar"  # "resistencia_pulmonar" | "capacidad_manguera"
@export var mostrar_advertencia_casino: bool = false  # Si mostrar la advertencia sobre el casino

# --- Configuración del Teletransporte ---
@export_category("Teletransporte")
@export var teletransportar_al_terminar: bool = false
@export_file("*.tscn") var escena_destino: String = ""

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
var regalo_entregado: bool = false
var flecha_nodo: Label = null

# Señal para cuando el jugador interactúa
signal dialogo_iniciado
signal dialogo_terminado

const INTERACT_RADIUS := 130.0  # píxeles en espacio mundo

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	add_to_group("gatos_salvados")
	add_to_group("localizable")
	print("🐱 Gato", nombre_gato, "agregado al grupo 'gatos_salvados'")

	# Buscar el AnimatedSprite2D primero para poder usarlo en el label
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D
	else:
		for child in get_children():
			if child is AnimatedSprite2D:
				animated_sprite = child
				break

	# Registrar tecla E como acción de interacción con gatos
	if not InputMap.has_action("interact_cat"):
		InputMap.add_action("interact_cat")
	# Agregar E si no está ya
	var tiene_e := false
	for ev in InputMap.action_get_events("interact_cat"):
		if ev is InputEventKey and ev.keycode == KEY_E:
			tiene_e = true
			break
	if not tiene_e:
		var e_key := InputEventKey.new()
		e_key.keycode = KEY_E
		InputMap.action_add_event("interact_cat", e_key)

	# Label "[E] Hablar" posicionado encima del sprite visual
	label_interactuar = Label.new()
	label_interactuar.text = "[E] " + _t("npc.talk").substr(4)  # quitar "[F] "
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

	print("🐱 Gato", nombre_gato, "salvado apareció en la escena")

	# DESACTIVADO: Mensaje automático al entrar al nivel
	#if mostrar_dialogo_automatico:
	#	await get_tree().create_timer(0.5).timeout
	#	_mostrar_dialogo()

func _physics_process(_delta: float) -> void:
	# Verificar si se completó el rescate
	if fuego_apagado and enemigos_derrotados and not dialogo_final_mostrado:
		_detener_animacion()
		_crear_flecha_interaccion()
		dialogo_final_mostrado = true
		# ✅ Marcar como rescatado apenas se completan las condiciones
		GameManager.marcar_gato_rescatado(nombre_gato)
		print("✅ ¡GATO RESCATADO! Flecha mostrada, espera interacción")
		if escena_destino != "":
			print("🕵️‍♂️ [CARGA SECRETA] El nivel fue superado. Empezando a cargar en la RAM: ", escena_destino)
			ResourceLoader.load_threaded_request(escena_destino)

	# Detectar proximidad del jugador por distancia (no depende del Area2D)
	var ref_pos = animated_sprite.global_position if animated_sprite else global_position
	var players = get_tree().get_nodes_in_group("player_main")
	var estaba_cerca := jugador_cerca
	jugador_cerca = false
	for p in players:
		if ref_pos.distance_to(p.global_position) <= INTERACT_RADIUS:
			jugador_cerca = true
			break

	# Label solo aparece si el rescate fue completado y el regalo aún no fue entregado
	var puede_interactuar = dialogo_final_mostrado and not regalo_entregado
	if label_interactuar:
		label_interactuar.visible = jugador_cerca and not dialogo_activo and puede_interactuar

	# Interacción con tecla E — solo si el rescate ya ocurrió
	if jugador_cerca and not dialogo_activo and puede_interactuar:
		if Input.is_action_just_pressed("interact_cat"):
			_mostrar_dialogo_rescate()

func update_texts() -> void:
	if label_interactuar:
		label_interactuar.text = "[E] " + _t("npc.talk").substr(4)

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
	nombre_label.text = " " + nombre_gato + ":"
	nombre_label.add_theme_color_override("font_color", Color(1, 0.6, 0))  # Naranja
	nombre_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(nombre_label)
	
	# Espaciador pequeño
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer1)
	
	# Label del mensaje
	var mensaje_label = Label.new()
	mensaje_label.text = _t(mensaje_agradecimiento_key)
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
	
	if canvas_layer and is_instance_valid(canvas_layer):
		canvas_layer.queue_free()
	
	dialogo_ui = null
	dialogo_activo = false
	emit_signal("dialogo_terminado")
	
	# --- TELETRANSPORTE CONDICIONAL ---
	# Solo teletransportamos si el gato ya entregó el regalo (o sea, ya lo rescataste)
	if teletransportar_al_terminar and escena_destino != "" and regalo_entregado:
		print("🚀 Rescate completo. Viajando a: ", escena_destino)
		get_tree().change_scene_to_file(escena_destino)
	else:
		print("😺 Diálogo inicial terminado. El gato se queda esperando el rescate.")

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

func _crear_flecha_interaccion() -> void:
	"""Flecha verde animada encima del gato que indica que puede interactuar"""
	if flecha_nodo and is_instance_valid(flecha_nodo):
		return
	if regalo_entregado:
		return

	flecha_nodo = Label.new()
	flecha_nodo.text = "▼"
	flecha_nodo.add_theme_color_override("font_color", Color(0.15, 0.95, 0.25))
	flecha_nodo.add_theme_color_override("font_outline_color", Color(0.0, 0.25, 0.0))
	flecha_nodo.add_theme_constant_override("outline_size", 4)
	flecha_nodo.add_theme_font_size_override("font_size", 22)

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
	print("✅ Flecha de interacción creada encima del gato")

func _mostrar_dialogo_rescate() -> void:
	"""Caja de pergamino con cat.rescue_message; entrega el poder y muestra notificación"""
	if dialogo_activo:
		return
	
	if not is_inside_tree() or get_viewport() == null:
		print("⚠️ No se puede mostrar diálogo: el nodo no está en el árbol o viewport es null")
		return

	_limpiar_dialogos_anteriores()
	dialogo_activo = true
	emit_signal("dialogo_iniciado")

	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogoRescateCanvasLayer"
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_to_group("dialogo_gato")

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control)

	var vp = get_viewport().get_visible_rect().size

	const BOX_H      := 120.0
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
	else:
		var fallback = load("res://Assets/gatos/GatoGris_0000.png")
		if fallback:
			portrait_rect.texture = fallback
	box.add_child(portrait_rect)

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
	lbl_msg.text                = _t(mensaje_agradecimiento_key)
	lbl_msg.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_msg.add_theme_color_override("font_color", Color(0.14, 0.07, 0.02))
	lbl_msg.add_theme_font_size_override("font_size", 14)
	msg_margin.add_child(lbl_msg)

	var arrow_lbl = Label.new()
	arrow_lbl.text     = "▼"
	arrow_lbl.position = Vector2(BOX_W - 24, BOX_H - 22)
	arrow_lbl.add_theme_color_override("font_color", Color(0.42, 0.25, 0.07, 0.8))
	arrow_lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(arrow_lbl)

	get_tree().root.add_child(canvas_layer)

	# Entregar poder inmediatamente al interactuar
	_entregar_regalo()

	# Primer diálogo: mensaje de agradecimiento (3 segundos)
	var timer1 = get_tree().create_timer(3.0)
	timer1.timeout.connect(func():
		if is_instance_valid(canvas_layer):
			_cerrar_dialogo(canvas_layer)
		# Mostrar segundo diálogo después
		_mostrar_dialogo_rescate_segunda_parte()
	)


func _mostrar_dialogo_rescate_segunda_parte() -> void:
	"""Segunda parte: muestra el mensaje de dirígete a la luz"""
	if not is_inside_tree() or get_viewport() == null:
		print("⚠️ No se puede mostrar diálogo: el nodo no está en el árbol o viewport es null")
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogoRescateCanvasLayer2"
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_to_group("dialogo_gato")

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control)

	var vp = get_viewport().get_visible_rect().size

	const BOX_H      := 120.0
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
	else:
		var fallback = load("res://Assets/gatos/GatoGris_0000.png")
		if fallback:
			portrait_rect.texture = fallback
	box.add_child(portrait_rect)

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
	lbl_msg.text                = _t("cat.rescue_go_to_light")
	lbl_msg.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_msg.add_theme_color_override("font_color", Color(0.14, 0.07, 0.02))
	lbl_msg.add_theme_font_size_override("font_size", 14)
	msg_margin.add_child(lbl_msg)

	var arrow_lbl = Label.new()
	arrow_lbl.text     = "▼"
	arrow_lbl.position = Vector2(BOX_W - 24, BOX_H - 22)
	arrow_lbl.add_theme_color_override("font_color", Color(0.42, 0.25, 0.07, 0.8))
	arrow_lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(arrow_lbl)

	get_tree().root.add_child(canvas_layer)

	# Segundo diálogo: mensaje de dirígete (3 segundos) y luego mostrar tercer diálogo o activar salida
	var timer2 = get_tree().create_timer(3.0)
	timer2.timeout.connect(func():
		if is_instance_valid(canvas_layer):
			_cerrar_dialogo(canvas_layer)
		
		# Mostrar tercer diálogo solo si está configurado para mostrar advertencia del casino
		if mostrar_advertencia_casino:
			_mostrar_dialogo_rescate_tercera_parte()
		else:
			# Si no hay advertencia del casino, activar la salida directamente
			_activar_salida_nivel()
			print("✨ ¡SALIDA DEL NIVEL ACTIVADA SIN ADVERTENCIA DEL CASINO!")
			
			# Mostrar notificación de poder
			var mensaje_poder = ""
			match tipo_poder:
				"resistencia_pulmonar":
					mensaje_poder = _t("cat.power_lung")
				"capacidad_manguera":
					mensaje_poder = _t("cat.power_hose")
				_:
					mensaje_poder = _t("cat.power_generic")

			_mostrar_notificacion_pantalla(mensaje_poder)
	)


func _mostrar_dialogo_rescate_tercera_parte() -> void:
	"""Tercera parte: advertencia sobre el casino con "El casino" en rojo oscuro y bold"""
	if not is_inside_tree() or get_viewport() == null:
		print("⚠️ No se puede mostrar diálogo: el nodo no está en el árbol o viewport es null")
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogoRescateCanvasLayer3"
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_to_group("dialogo_gato")

	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(control)

	var vp = get_viewport().get_visible_rect().size

	const BOX_H      := 140.0  # Más alto para el mensaje más largo
	const BOX_W      := 680.0  # Más ancho también
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
	else:
		var fallback = load("res://Assets/gatos/GatoGris_0000.png")
		if fallback:
			portrait_rect.texture = fallback
	box.add_child(portrait_rect)

	var msg_x = PORTRAIT_W + 14
	var msg_margin = MarginContainer.new()
	msg_margin.position = Vector2(msg_x, BANNER_H)
	msg_margin.size     = Vector2(BOX_W - msg_x - 6, BOX_H - BANNER_H)
	msg_margin.add_theme_constant_override("margin_left",   8)
	msg_margin.add_theme_constant_override("margin_right",  8)
	msg_margin.add_theme_constant_override("margin_top",    10)
	msg_margin.add_theme_constant_override("margin_bottom", 10)
	box.add_child(msg_margin)

	# Usar RichTextLabel para poder formatear el nombre del casino en rojo oscuro y bold
	var lbl_msg = RichTextLabel.new()
	lbl_msg.text = _t("cat.casino_warning")
	lbl_msg.bbcode_enabled = true
	lbl_msg.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_msg.fit_content = true
	lbl_msg.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl_msg.add_theme_font_size_override("font_size", 14)
	# Desactivar la interacción del RichTextLabel
	lbl_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_margin.add_child(lbl_msg)

	var arrow_lbl = Label.new()
	arrow_lbl.text     = "▼"
	arrow_lbl.position = Vector2(BOX_W - 24, BOX_H - 22)
	arrow_lbl.add_theme_color_override("font_color", Color(0.42, 0.25, 0.07, 0.8))
	arrow_lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(arrow_lbl)

	get_tree().root.add_child(canvas_layer)

	# Tercer diálogo: mensaje de advertencia (7 segundos) y luego mostrar poder y activar salida
	var timer3 = get_tree().create_timer(7.0)
	timer3.timeout.connect(func():
		if is_instance_valid(canvas_layer):
			_cerrar_dialogo(canvas_layer)
		
		# Activar la salida cuando termine el tercer diálogo
		_activar_salida_nivel()
		print("✨ ¡SALIDA DEL NIVEL ACTIVADA POR TERCER DIÁLOGO!")
		
		# Mostrar notificación de poder
		var mensaje_poder = ""
		match tipo_poder:
			"resistencia_pulmonar":
				mensaje_poder = _t("cat.power_lung")
			"capacidad_manguera":
				mensaje_poder = _t("cat.power_hose")
			_:
				mensaje_poder = _t("cat.power_generic")
		
		_mostrar_notificacion_pantalla(mensaje_poder)
	)


func _entregar_regalo() -> void:
	"""Aplica el poder del gato al jugador según tipo_poder, oculta la flecha"""
	if regalo_entregado:
		return
	regalo_entregado = true

	if flecha_nodo and is_instance_valid(flecha_nodo):
		flecha_nodo.queue_free()
		flecha_nodo = null

	var players = get_tree().get_nodes_in_group("player_main")
	if players.size() == 0:
		return
	var player = players[0]

	match tipo_poder:
		"resistencia_pulmonar":
			if player.has_method("aumentar_resistencia_pulmonar"):
				player.aumentar_resistencia_pulmonar()
				print("💨 Resistencia pulmonar aumentada")
		"capacidad_manguera":
			if player.has_method("mejorar_manguera"):
				player.mejorar_manguera()
				print("💧 Manguera mejorada")



func _mostrar_notificacion_pantalla(texto: String) -> void:
	"""Notificación flotante al lado de la barra de vida con el mensaje del poder recibido"""
	if not is_inside_tree() or get_viewport() == null:
		return
		
	var vp = get_viewport().get_visible_rect().size
	var pw := 280.0  # Ancho más delgado

	var cl = CanvasLayer.new()
	cl.layer = 110
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Raíz: Control que ocupa toda la pantalla
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.modulate = Color(1, 1, 1, 0)
	cl.add_child(root_ctrl)

	# Contenedor: a la derecha de la barra de vida, sin tapar el HUD
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(pw, 0)
	# Posición: más a la derecha, lejos del HUD
	container.position = Vector2(530, 35)
	root_ctrl.add_child(container)

	# --- Borde dorado exterior (Panel que envuelve todo el VBox) ---
	var outer = Panel.new()
	var ostyle = StyleBoxFlat.new()
	ostyle.bg_color                   = Color(0.72, 0.55, 0.05, 1.0)
	ostyle.corner_radius_top_left     = 12
	ostyle.corner_radius_top_right    = 12
	ostyle.corner_radius_bottom_left  = 12
	ostyle.corner_radius_bottom_right = 12
	ostyle.shadow_color  = Color(0.9, 0.7, 0.0, 0.55)
	ostyle.shadow_size   = 16
	ostyle.shadow_offset = Vector2(0, 0)
	ostyle.content_margin_left   = 4
	ostyle.content_margin_right  = 4
	ostyle.content_margin_top    = 4
	ostyle.content_margin_bottom = 4
	outer.add_theme_stylebox_override("panel", ostyle)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(outer)

	# --- Fondo oscuro interior con VBoxContainer para el contenido ---
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 3)
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color                   = Color(0.07, 0.05, 0.02, 0.97)
	inner_style.corner_radius_top_left     = 9
	inner_style.corner_radius_top_right    = 9
	inner_style.corner_radius_bottom_left  = 9
	inner_style.corner_radius_bottom_right = 9
	inner_style.content_margin_left   = 12
	inner_style.content_margin_right  = 12
	inner_style.content_margin_top    = 8
	inner_style.content_margin_bottom = 8
	inner_vbox.add_theme_stylebox_override("panel", inner_style)
	# Usar un PanelContainer para aplicar el estilo al VBox
	var inner_panel = PanelContainer.new()
	inner_panel.add_theme_stylebox_override("panel", inner_style)
	inner_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(inner_panel)
	inner_panel.add_child(inner_vbox)

	# Título
	var title_lbl = Label.new()
	title_lbl.text = _t("cat.power_title")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.2, 0.10, 0.0, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.add_theme_font_size_override("font_size", 16)
	inner_vbox.add_child(title_lbl)

	# Separador dorado
	var sep = ColorRect.new()
	sep.color = Color(1.0, 0.80, 0.10, 0.5)
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_vbox.add_child(sep)

	# Texto del poder
	var lbl = Label.new()
	lbl.text = texto
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 1)
	lbl.add_theme_font_size_override("font_size", 12)
	inner_vbox.add_child(lbl)

	get_tree().root.add_child(cl)

	# Fade in → espera visible → fade out → eliminar
	var tw = cl.create_tween()
	tw.tween_property(root_ctrl, "modulate", Color(1, 1, 1, 1), 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_interval(6.0)  # 6 segundos visible
	tw.tween_property(root_ctrl, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(cl.queue_free)


func _activar_salida_nivel() -> void:
	"""Activa la luz de salida y el área de salida cuando el gato es rescatado"""
	print("🔍 Buscando área de salida...")
	
	var area_salida = null
	var root = get_tree().root.get_child(0)
	if root:
		area_salida = root.find_child("area salida", false, false)
	
	if not area_salida:
		area_salida = get_tree().root.find_child("area salida", true, false)
	
	if not area_salida:
		push_warning("⚠️ No se encontró el nodo 'area salida' en el nivel")
		return
	
	print("✅ Área de salida encontrada:", area_salida.name)
	
	# ⚡ NUEVO: Le pasamos la escena_destino al área de salida para que sepa a dónde ir
	if area_salida.has_method("activar_salida"):
		# Le enviamos la ruta que hemos estado cargando en secreto
		area_salida.activar_salida(escena_destino)
		print("✨ Área de salida activada exitosamente con destino: ", escena_destino)
	else:
		push_warning("⚠️ El nodo 'area salida' no tiene el método 'activar_salida'")