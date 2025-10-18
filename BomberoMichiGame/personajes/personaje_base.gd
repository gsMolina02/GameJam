extends CharacterBody2D

@export var speed = 400

func mover_personaje(delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	move_and_slide()
