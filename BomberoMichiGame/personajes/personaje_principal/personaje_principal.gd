extends "res://personajes/personaje_base.gd"

func _physics_process(delta):
	mover_personaje(delta)
	
	# Girar el sprite horizontalmente según la dirección
	if velocity.x < 0:
		$Sprite2D.scale.x = -1  # Mirar a la izquierda
		print("Izquierda")
	elif velocity.x > 0:
		$Sprite2D.scale.x = 1   # Mirar a la derecha
		print("Derecha")
