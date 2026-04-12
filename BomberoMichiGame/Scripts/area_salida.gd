extends Area2D
# Script para el área de salida del nivel
# Se activa cuando se salva un gato y permite ir al siguiente nivel

@export var escena_destino: String = "res://Scenes/Levels/HellV2/HellV2.tscn"
@export var nombre_gato_requerido: String = "Osiris"
@export var texto_hint: String = "Presiona F para bajar al siguiente nivel"

var jugador_adentro: bool = false
var mensaje_visible: Label = null
var luz_salida: PointLight2D = null

func _ready():
	print("🚪 Inicializando área de salida...")
	
	# Buscar la luz salida - método 1: en el padre
	if get_parent():
		luz_salida = get_parent().find_child("luz salida", true, false)
	
	# Método 2: Si no está en el padre, buscar en la raíz del nivel
	if not luz_salida:
		var root = get_tree().root.get_child(0)  # El nivel actual
		if root:
			luz_salida = root.find_child("luz salida", true, false)
	
	# Método 3: Búsqueda en todo el árbol
	if not luz_salida:
		luz_salida = get_tree().root.find_child("luz salida", true, false)
	
	if luz_salida:
		print("💡 Luz de salida encontrada:", luz_salida.name, "en posición:", luz_salida.global_position)
		luz_salida.enabled = false  # Desactivada hasta que se salve el gato
	else:
		push_warning("⚠️ No se encontró 'luz salida' en el nivel")
	
	# Conectar señales
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	print("  - Collision Layer:", collision_layer)
	print("  - Collision Mask:", collision_mask)
	
	# Desactivar el área al inicio
	monitoring = false
	monitorable = false
	print("🚪 Área de salida inicializada (desactivada)")
	print("  - Position:", position)
	if has_node("CollisionShape2D"):
		print("  - CollisionShape encontrado en:", $CollisionShape2D.position)

func activar_salida() -> void:
	"""Activa el área de salida y enciende la luz"""
	print("\n==================================================")
	print("✨ ¡ACTIVANDO SALIDA DEL NIVEL!")
	print("==================================================")
	
	# Encender la luz
	if luz_salida:
		print("  → Encendiendo luz de salida...")
		luz_salida.enabled = true
		print("  ✅ Luz de salida ENCENDIDA")
		print("  → Posición luz:", luz_salida.global_position)
		print("  → Energía luz:", luz_salida.energy)
	else:
		print("  ❌ ERROR: No se encontró 'luz salida'")
	
	# Activar el área
	print("  → Activando área de colisión...")
	print("    - monitoring antes:", monitoring)
	print("    - monitorable antes:", monitorable)
	
	monitoring = true
	monitorable = true
	
	print("    - monitoring después:", monitoring)
	print("    - monitorable después:", monitorable)
	print("  → Posición área:", position)
	
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D
		print("  → CollisionShape2D encontrado")
		print("    - Shape:", shape.shape)
		print("    - Position relativa:", shape.position)
	
	print("🚪 ¡ÁREA DE SALIDA ACTIVADA!")
	print("==================================================\n")

func desactivar_salida() -> void:
	"""Desactiva el área de salida"""
	print("🌑 Desactivando salida del nivel")
	monitoring = false
	monitorable = false
	if luz_salida:
		luz_salida.enabled = false

func _on_body_entered(body: Node2D) -> void:
	"""Detecta cuando el jugador entra al área"""
	if body.is_in_group("player_main"):
		jugador_adentro = true
		print("👤 Jugador entró al área de salida")
		_mostrar_mensaje()

func _on_body_exited(body: Node2D) -> void:
	"""Detecta cuando el jugador sale del área"""
	if body.is_in_group("player_main"):
		jugador_adentro = false
		print("👤 Jugador salió del área de salida")
		_ocultar_mensaje()

func _on_area_entered(area: Area2D) -> void:
	"""Fallback por si el jugador es un Area2D"""
	if area.is_in_group("player_main"):
		jugador_adentro = true
		_mostrar_mensaje()

func _on_area_exited(area: Area2D) -> void:
	"""Fallback por si el jugador es un Area2D"""
	if area.is_in_group("player_main"):
		jugador_adentro = false
		_ocultar_mensaje()

func _physics_process(_delta: float) -> void:
	"""Detecta cuando el jugador presiona F dentro del área"""
	if jugador_adentro and Input.is_action_just_pressed("interact"):
		_cambiar_escena()

func _mostrar_mensaje() -> void:
	"""Muestra el mensaje de interacción con flecha verde animada"""
	if mensaje_visible:
		return
	
	print("📝 Mostrando mensaje de salida:", texto_hint)
	
	# Crear un CanvasLayer para asegurar que se vea encima
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "MensajeSalidaCanvas"
	canvas_layer.layer = 99  # Justo debajo de UI
	add_child(canvas_layer)
	
	# Crear contenedor
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(container)
	
	# Obtener tamaño de pantalla
	var screen_size = get_viewport().get_visible_rect().size
	var center_x = screen_size.x / 2
	var center_y = screen_size.y / 2
	
	# ===== FLECHA VERDE =====
	var flecha = Label.new()
	flecha.text = "▼"
	flecha.add_theme_color_override("font_color", Color(0.15, 0.95, 0.25))
	flecha.add_theme_color_override("font_outline_color", Color(0.0, 0.25, 0.0))
	flecha.add_theme_constant_override("outline_size", 4)
	flecha.add_theme_font_size_override("font_size", 32)
	
	# Posicionar flecha encima del texto
	var flecha_y = center_y - 80
	flecha.position = Vector2(center_x - 16, flecha_y)
	container.add_child(flecha)
	
	# Animar flecha con rebote suave
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(flecha, "position:y", flecha_y - 15, 0.45).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flecha, "position:y", flecha_y, 0.45).set_ease(Tween.EASE_IN_OUT)
	
	# ===== TEXTO DEL MENSAJE =====
	mensaje_visible = Label.new()
	mensaje_visible.text = texto_hint
	mensaje_visible.add_theme_color_override("font_color", Color.YELLOW)
	mensaje_visible.add_theme_color_override("font_outline_color", Color.BLACK)
	mensaje_visible.add_theme_constant_override("outline_size", 4)
	mensaje_visible.add_theme_font_size_override("font_size", 24)
	
	# Centrar en pantalla (debajo de la flecha)
	mensaje_visible.position = Vector2(center_x - 200, center_y - 20)
	mensaje_visible.custom_minimum_size = Vector2(400, 0)
	mensaje_visible.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	container.add_child(mensaje_visible)
	print("  ✅ Flecha y mensaje visibles en pantalla")

func _ocultar_mensaje() -> void:
	"""Oculta el mensaje de interacción"""
	if mensaje_visible:
		if mensaje_visible.get_parent():
			var canvas = mensaje_visible.get_parent().get_parent()  # El CanvasLayer
			if canvas:
				canvas.queue_free()
		mensaje_visible.queue_free()
		mensaje_visible = null
		print("📝 Mensaje de salida ocultado")

func _cambiar_escena() -> void:
	"""Cambia a la siguiente escena"""
	print("🚪 Cambiando a:", escena_destino)
	
	# Guardar estado del jugador si es necesario
	var jugador = get_tree().get_first_node_in_group("player_main")
	if jugador and GameManager:
		GameManager.guardar_estado_jugador(jugador)
	
	get_tree().call_deferred("change_scene_to_file", escena_destino)
