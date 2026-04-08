extends Area2D
# Script para animar la puerta de salida
# Anima el ColorRect de negro a blanco y las luces de apagado a encendido
# También detecta cuando el jugador toca la puerta y verifica si puede pasar

@export var duracion_fade: float = 3.0  # Tiempo de transición en segundos
@export var color_cerrado: Color = Color.BLACK  # Color inicial
@export var color_abierto: Color = Color.WHITE  # Color final
@export var energia_luz_abierto: float = 27.7  # Energía final de la luz

# Parámetros para cambio de escena
@export var nombre_gato_requerido: String = "Osiris"  # Nombre del gato que debe ser rescatado
@export var escena_destino: String = "res://Scenes/Levels/NewHellLevel/hell01.tscn"  # Escena siguiente
@export var offset_spawn: Vector2 = Vector2(50, 0)  # Distancia desde la puerta al aparecer

var color_rect: ColorRect = null
var punto_luz: PointLight2D = null
var esta_animada: bool = false

signal puerta_iluminada

func _ready():
	# Retrasar un frame para evitar que otros scripts sobreescriban los valores iniciales
	# Pero intentar apagar la luz inmediatamente si se puede
	punto_luz = find_child("PointLight2D", true, false)
	if punto_luz:
		punto_luz.energy = 0.0
		if "intensidad_destellos" in punto_luz:
			punto_luz.intensidad_destellos = false
	
	# Conectar señales de colisión
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
			
	call_deferred("_inicializar_puerta")

func _inicializar_puerta():
	# Buscar el ColorRect (ahora es hijo directo de Salida)
	color_rect = find_child("fondoPuerta", true, false)
	if not color_rect:
		color_rect = find_child("ColorRect", true, false)
	if not color_rect:
		for child in get_children():
			if child is ColorRect:
				color_rect = child
				break
	
	if color_rect:
		print("✅ ColorRect encontrado para puerta: ", color_rect.name)
		color_rect.color = color_cerrado
	else:
		print("⚠️ ColorRect no encontrado para puerta")
	
	# Si no encontramos la luz, buscar en los hijos
	if not punto_luz:
		punto_luz = find_child("PointLight2D", true, false)
		if punto_luz:
			punto_luz.energy = 0.0
			if "intensidad_destellos" in punto_luz:
				punto_luz.intensidad_destellos = false
				
	if punto_luz:
		print("✅ PointLight2D encontrado y configurado: ", punto_luz.name)
	else:
		print("⚠️ PointLight2D no encontrado para puerta")

func animar_apertura() -> void:
	"""Anima la apertura de la puerta - fade del color y energía de la luz"""
	if esta_animada:
		print("⚠️ Puerta ya está animada")
		return
	
	esta_animada = true
	print("🚪 Iniciando animación de puerta...")
	
	# Crear tween para animar el ColorRect
	var tween = create_tween()
	tween.set_parallel(true)  # Animar en paralelo
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Animar el ColorRect de negro a blanco
	if color_rect:
		tween.tween_property(color_rect, "color", color_abierto, duracion_fade)
		print("💡 Animando ColorRect de negro a blanco...")
	else:
		print("⚠️ ColorRect no está inicializado")
	
	# Animar la luz de 0 a la energía final
	if punto_luz:
		tween.tween_property(punto_luz, "energy", energia_luz_abierto, duracion_fade)
		print("💡 Animando PointLight2D...")
	else:
		print("⚠️ PointLight2D no está inicializado")
	
	# Al terminar
	await tween.finished
	esta_animada = false
	
	if punto_luz and "intensidad_destellos" in punto_luz:
		punto_luz.energia_base = energia_luz_abierto
		punto_luz.intensidad_destellos = true
		
	print("✅ Puerta iluminada completamente")
	emit_signal("puerta_iluminada")

# ============================================
# DETECCIÓN DE COLISIÓN Y CAMBIO DE ESCENA
# ============================================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_main"):
		print("👤 Jugador toca la puerta de salida")
		
		# Verificar si el gato fue rescatado
		if GameManager.fue_gato_rescatado(nombre_gato_requerido):
			print("✅ Gato rescatado - ¡Cambiando de escena!")
			_cambiar_escena(body)
		else:
			print("🔒 Aún no has rescatado a %s" % nombre_gato_requerido)

func _on_body_exited(body: Node2D) -> void:
	pass

func _cambiar_escena(jugador: Node2D) -> void:
	"""Cambia a la siguiente escena"""
	print("🚪 Cambiando de escena...")
	GameManager.guardar_estado_jugador(jugador)
	GameManager.offset_spawn = offset_spawn
	get_tree().call_deferred("change_scene_to_file", escena_destino)
