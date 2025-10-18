extends CharacterBody2D

@export var speed = 400
@export var screen_margin: int = 16
@export var clamp_to_viewport := true

# Dash exports (origin/main additions) — keep them available for characters that want dash
@export var dash_speed = 1200  # Velocidad del dash
@export var dash_duration = 0.25  # Duración del dash en segundos
@export var dash_cooldown = 0.5  # Tiempo de espera entre dashes

# Variables de control del dash (por defecto inactivas; los hijos pueden habilitarlas)
var is_dashing = false
var can_dash = true
var dash_direction = Vector2.ZERO
var dash_timer = 0.0

func mover_personaje(delta):
	# Movimiento por defecto: input vector simple
	# Si un hijo implementa dash, puede usar/overridear estas variables
	var input_vector = Input.get_vector("left", "right", "up", "down")
	var spd = speed if speed != null else 400
	velocity = input_vector * spd
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
