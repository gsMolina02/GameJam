extends CharacterBody2D

@export var speed = 400
@export var screen_margin := 8.0

func mover_personaje(delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	move_and_slide()
	_clamp_to_viewport()

func _clamp_to_viewport():
	var vp = get_viewport()
	if not vp:
		return

	# If there's an active Camera2D, compute visible rect in world coords using camera position and zoom
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

	# Fallback to viewport visible rect (may be in canvas coords)
	var rect = vp.get_visible_rect()
	var min_x = rect.position.x + screen_margin
	var min_y = rect.position.y + screen_margin
	var max_x = rect.position.x + rect.size.x - screen_margin
	var max_y = rect.position.y + rect.size.y - screen_margin
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)
