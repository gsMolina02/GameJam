extends "res://personajes/personaje_base.gd"

@export var objetivo: NodePath
@export var distancia_minima := 80  

func mover_personaje(_delta):
	var principal = get_node_or_null(objetivo)
	var anim = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
	if not anim:
		print("[mascota.gd] No se encontró AnimatedSprite2D, intentando buscar mishiMuerto...")
		if has_node("mishiMuerto"):
			anim = $mishiMuerto
			print("[mascota.gd] Encontrado mishiMuerto como AnimatedSprite2D.")
		else:
			print("[mascota.gd] No se encontró mishiMuerto tampoco.")
	if principal:
		var distancia = global_position.distance_to(principal.global_position)
		if distancia > distancia_minima:
			var direccion = (principal.global_position - global_position).normalized()
			velocity = direccion * speed
			move_and_slide()
			if anim:
				print("[mascota.gd] Intentando reproducir animación GhostCat...")
				if anim.animation != "GhostCat":
					anim.animation = "GhostCat"
				if not anim.is_playing():
					anim.play()
					print("[mascota.gd] anim.play() ejecutado.")
		else:
			velocity = Vector2.ZERO  
			if anim:
				anim.stop()
				print("[mascota.gd] anim.stop() ejecutado.")

func _physics_process(delta):
	mover_personaje(delta)
	# Mantener dentro del viewport/campo
	keep_in_viewport()
