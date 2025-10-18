extends CharacterBody2D

@export var speed = 400
@export var dash_speed = 1200  # Velocidad del dash
@export var dash_duration = 0.25  # Duración del dash en segundos
@export var dash_cooldown = 0.5  # Tiempo de espera entre dashes
@export var screen_margin := 8.0

# Variables de control del dash
var is_dashing = false
var can_dash = true
var dash_direction = Vector2.ZERO
var dash_timer = 0.0

func mover_personaje(delta):
	# Si está haciendo dash, manejar el movimiento del dash
	if is_dashing:
		_handle_dash(delta)
		return
	
	# Movimiento normal
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	move_and_slide()
	
	# Detectar input de dash (Shift)
	if Input.is_action_just_pressed("ui_shift") and can_dash and input_vector.length() > 0:
		_start_dash(input_vector)
	
	# Mantener al personaje dentro del viewport
	_clamp_to_viewport()

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

func _start_dash(direction: Vector2):
	"""Inicia el dash en la dirección especificada"""
	is_dashing = true
	dash_direction = direction.normalized()
	dash_timer = dash_duration
	
	# Aquí puedes añadir efectos visuales/sonoros del dash
	print("¡Dash activado!")

func _clamp_to_viewport():
	var vp = get_viewport()
	if not vp:
		return

	var cam := vp.get_camera_2d()
	if cam:
		var vp_size = vp.get_visible_rect().size
		var world_size = vp_size * cam.zoom
		var world_pos = cam.global_position - world_size * 0.5
		var min_x_cam = world_pos.x + screen_margin
		var min_y_cam = world_pos.y + screen_margin
		var max_x_cam = world_pos.x + world_size.x - screen_margin
		var max_y_cam = world_pos.y + world_size.y - screen_margin
		global_position.x = clamp(global_position.x, min_x_cam, max_x_cam)
		global_position.y = clamp(global_position.y, min_y_cam, max_y_cam)
		return

	# Fallback a viewport
	var rect = vp.get_visible_rect()
	var min_x = rect.position.x + screen_margin
	var min_y = rect.position.y + screen_margin
	var max_x = rect.position.x + rect.size.x - screen_margin
	var max_y = rect.position.y + rect.size.y - screen_margin
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)
