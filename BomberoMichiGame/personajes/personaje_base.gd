extends CharacterBody2D

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

func mover_personaje(_delta):
	# Movimiento normal por defecto
	var input_vector = Input.get_vector("left", "right", "up", "down")
	var spd = speed if speed != null else 400
	velocity = input_vector * spd
	move_and_slide()

	# Si está haciendo dash, manejar el dash por frame (espera usada dentro del handler)
	if is_dashing:
		_handle_dash(_delta)
		return


func _start_dash(direction: Vector2):
	"""Inicia el dash en la dirección especificada (implementación base)."""
	if not can_dash:
		return
	is_dashing = true
	can_dash = false
	dash_direction = direction.normalized()
	dash_timer = dash_duration
	print_debug("[base] _start_dash called. direction:", dash_direction, "dash_timer:", dash_timer, "dash_speed:", dash_speed)


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
	var x = clamp(global_position.x, rect.position.x + margin, rect.position.x + rect.size.x - margin)
	var y = clamp(global_position.y, rect.position.y + margin, rect.position.y + rect.size.y - margin)
	global_position = Vector2(x, y)
