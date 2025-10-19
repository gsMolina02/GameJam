extends CharacterBody2D
# Implementación base de _start_dash
func _start_dash(direction: Vector2):
	if not can_dash:
		return
	is_dashing = true
	can_dash = false
	dash_direction = direction.normalized()
	dash_timer = dash_duration
	print_debug("[base] _start_dash called. direction:", dash_direction, "dash_timer:", dash_timer, "dash_speed:", dash_speed)


@export var speed = 400
@export var screen_margin: int = 8
@export var clamp_to_viewport := true

# Dash exports (original behavior requested)
@export var dash_speed = 1200  # Velocidad del dash
@export var dash_duration = 0.25  # Duración del dash en segundos
@export var dash_cooldown = 0.5  # Tiempo de espera entre dashes

# Variables de control del dash
var is_dashing = false
var can_dash = true
var dash_direction = Vector2.ZERO
var dash_timer = 0.0

# Referencias para animación

var last_direction = Vector2.ZERO
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready():
	# Intentar obtener el AnimatedSprite2D (puede estar en el personaje hijo)
	animated_sprite = get_node_or_null("AnimatedSprite")
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		print("Advertencia: No se encontró AnimatedSprite2D en ", name)
	else:
		print("AnimatedSprite2D encontrado! Animaciones disponibles: ", animated_sprite.sprite_frames.get_animation_names())
		# Iniciar en idle frontal si existe
		_play_idle_animation()

# Unificación de mover_personaje: combina dash, animación y movimiento normal
func mover_personaje(delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	var spd = speed if speed != null else 400

	# Si está haciendo dash, manejar el movimiento del dash
	if is_dashing:
		_handle_dash(delta)
		return

	# Movimiento normal
	velocity = input_vector * spd
	move_and_slide()

	# Actualizar animaciones basadas en el input
	_update_animation(input_vector)

	# Detectar input de dash (Shift)
	if Input.is_action_just_pressed("ui_shift") and can_dash and input_vector.length() > 0:
		_start_dash(input_vector)

	# Mantener al personaje dentro del viewport
	keep_in_viewport(screen_margin)

func _handle_dash(delta):
	"""Maneja el movimiento durante el dash"""
	dash_timer -= delta

	if dash_timer <= 0:
		# Terminar el dash
		is_dashing = false
		velocity = Vector2.ZERO

		# Iniciar cooldown
		can_dash = false
		await get_tree().create_timer(dash_cooldown).timeout
		can_dash = true
	else:
		# Mantener la velocidad del dash
		velocity = dash_direction * dash_speed
		move_and_slide()

func keep_in_viewport(margin := screen_margin):
	if not clamp_to_viewport:
		return

	var vp = get_viewport()
	if vp == null:
		return

	# Intentar usar la cámara 2D si existe para clamping en mundo
	var cam := vp.get_camera_2d()
	if cam:
		var vp_size = vp.get_visible_rect().size
		var world_size = vp_size * cam.zoom
		var world_pos = cam.global_position - world_size * 0.5
		var min_x_cam = world_pos.x + margin
		var min_y_cam = world_pos.y + margin
		var max_x_cam = world_pos.x + world_size.x - margin
		var max_y_cam = world_pos.y + world_size.y - margin
		global_position.x = clamp(global_position.x, min_x_cam, max_x_cam)
		global_position.y = clamp(global_position.y, min_y_cam, max_y_cam)
		return

	# Fallback a viewport rect
	var rect = vp.get_visible_rect()
	var min_x = rect.position.x + screen_margin
	var min_y = rect.position.y + screen_margin
	var max_x = rect.position.x + rect.size.x - screen_margin
	var max_y = rect.position.y + rect.size.y - screen_margin
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)

func _update_animation(input_vector: Vector2):
	"""Selecciona animación según la dirección (8 direcciones con fallbacks)"""
	if not animated_sprite:
		return

	# Si no hay movimiento, reproducir animación idle frontal si existe
	if input_vector.length() == 0:
		_play_idle_animation()
		return

	# Guardar la última dirección
	last_direction = input_vector

	var angle = input_vector.angle()
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360

	var candidates: Array[String] = []

	# 0° = derecha, 90° = abajo, 180° = izquierda, 270° = arriba
	if degrees >= 337.5 or degrees < 22.5:
		# Derecha
		candidates = [
			"move_right", "move-right",  # nombres alternativos
			"lat_inf_der", "lat_sup_der",  # fallbacks diagonales si no hay derecha pura
			"move_down", "move_up"  # último recurso, que algo se mueva
		]
	elif degrees >= 22.5 and degrees < 67.5:
		# Diagonal inferior derecha
		candidates = [
			"lat_inf_der", "move_right", "move-right", "move_down"
		]
	elif degrees >= 67.5 and degrees < 112.5:
		# Abajo
		candidates = [
			"move_down", "lat_inf_der", "lat_inf_izq", "idle_frente", "idl_frente", "lat_frente"
		]
	elif degrees >= 112.5 and degrees < 157.5:
		# Diagonal inferior izquierda
		candidates = [
			"lat_inf_izq", "move_left", "move-left", "move_down"
		]
	elif degrees >= 157.5 and degrees < 202.5:
		# Izquierda
		candidates = [
			"move_left", "move-left", "lat_inf_izq", "lat_sup_izq", "lat_frente"
		]
	elif degrees >= 202.5 and degrees < 247.5:
		# Diagonal superior izquierda
		candidates = [
			"lat_sup_izq", "move_left", "move-left", "move_up"
		]
	elif degrees >= 247.5 and degrees < 292.5:
		# Arriba
		candidates = [
			"move_up", "lat_sup_der", "lat_sup_izq", "idle_up", "atras"
		]
	elif degrees >= 292.5 and degrees < 337.5:
		# Diagonal superior derecha
		candidates = [
			"lat_sup_der", "move_right", "move-right", "move_up"
		]

	_play_first_available(candidates)

func _play_idle_animation():
	"""Reproduce la animación idle frontal si existe; si no, detiene la animación."""
	if not animated_sprite:
		return

	# Intentar animaciones de idle conocidas
	if animated_sprite.sprite_frames:
		var played_before := animated_sprite.animation
		_play_first_available(["idl_frente", "idle_frente", "idle"])  # prioriza tu 'idl_frente'
		# Si ninguna idle existe, detener para mantener el último frame
		if animated_sprite.animation == played_before and animated_sprite.is_playing():
			animated_sprite.stop()

func _play_animation(anim_name: String):
	"""Reproduce una animación si existe"""
	if not animated_sprite:
		return
	
	if not animated_sprite.sprite_frames:
		return
	
	# Verificar si la animación existe
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	else:
		print("Advertencia: Animación '", anim_name, "' no encontrada")

func _play_first_available(names: Array[String]):
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	for n in names:
		if animated_sprite.sprite_frames.has_animation(n):
			if animated_sprite.animation != n:
				animated_sprite.play(n)
			return
	# Si no encontró ninguna, loggear para depurar
	print("No se encontró ninguna animación en la lista: ", names)
