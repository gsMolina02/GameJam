extends "res://personajes/personaje_base.gd"

@export var objetivo: NodePath
@export var distancia_minima := 120  

func mover_personaje(delta):
	var principal = get_node(objetivo)
	if principal:
		var distancia = global_position.distance_to(principal.global_position)
		if distancia > distancia_minima:
			var direccion = (principal.global_position - global_position).normalized()
			velocity = direccion * speed
			position += velocity * delta  
		else:
			velocity = Vector2.ZERO  

func _physics_process(delta):
	mover_personaje(delta)
