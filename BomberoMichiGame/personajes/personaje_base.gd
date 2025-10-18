extends CharacterBody2D

@export var speed = 400
@export var screen_margin: int = 16

func mover_personaje(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	move_and_slide()

func keep_in_viewport(margin := screen_margin):
	# Limita la posición global del personaje al rectángulo visible del viewport menos un margen
	var vp = get_viewport()
	if vp == null:
		return
	var rect = vp.get_visible_rect()
	var x = clamp(global_position.x, rect.position.x + margin, rect.position.x + rect.size.x - margin)
	var y = clamp(global_position.y, rect.position.y + margin, rect.position.y + rect.size.y - margin)
	global_position = Vector2(x, y)
