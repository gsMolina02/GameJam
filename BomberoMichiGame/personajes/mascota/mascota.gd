extends "res://personajes/personaje_base.gd"

@export var objetivo: NodePath
@export var distancia_minima := 80
@export var follow_speed := 6.0 # mayor = más rápido para alcanzar la velocidad objetivo

func _find_node_by_name(root: Node, target_name: String) -> Node:
	# Recorrido recursivo para encontrar un nodo por nombre (similar a find_node en versiones antiguas)
	if root.name == target_name:
		return root
	for child in root.get_children():
		if child is Node:
			var found = _find_node_by_name(child, target_name)
			if found:
				return found
	return null

func _resolve_objetivo() -> Node:
	# 1) Si se proporcionó un NodePath en el inspector, intentar resolverlo
	if objetivo != null and str(objetivo) != "":
		var path_str = str(objetivo)
		# Si es absoluto, resolver desde current_scene
		if path_str.begins_with("/"):
			var cs = get_tree().current_scene
			if cs:
				return cs.get_node_or_null(path_str)
		# Intentar resolver relativo desde este nodo
		var n = get_node_or_null(objetivo)
		if n:
			return n

	# 2) Fallback: buscar por grupo 'player_main'
	var players = get_tree().get_nodes_in_group("player_main")
	if players.size() > 0:
		return players[0]

	# 3) Fallback: buscar un nodo llamado 'personajePrincipal' en la escena actual
	var cs2 = get_tree().current_scene
	if cs2:
		var named = _find_node_by_name(cs2, "personajePrincipal")
		if named:
			return named

	return null

func mover_personaje(delta):
	var principal = _resolve_objetivo()

	var anim: AnimatedSprite2D = null
	if has_node("AnimatedSprite2D"):
		anim = $AnimatedSprite2D
	elif has_node("mishiMuerto"):
		anim = $mishiMuerto

	if principal == null:
		# No hay objetivo válido: detener y salir
		velocity = Vector2.ZERO
		if anim:
			anim.stop()
		return

	var distancia = global_position.distance_to(principal.global_position)
	if distancia > distancia_minima:
		var direccion = (principal.global_position - global_position).normalized()
		var objetivo_vel = direccion * speed
		# Suavizar con interpolación hacia la velocidad objetivo
		var t = clamp(follow_speed * delta, 0.0, 1.0)
		velocity = velocity.lerp(objetivo_vel, t)
		move_and_slide()
		if anim:
			if anim.animation != "GhostCat":
				anim.animation = "GhostCat"
			if not anim.is_playing():
				anim.play()
	else:
		# Dentro de distancia mínima: parar
		velocity = Vector2.ZERO
		if anim:
			anim.stop()

func _physics_process(delta):
	mover_personaje(delta)
	keep_in_viewport()
