extends "res://personajes/personaje_base.gd"

var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0
var tiempo_disparo := 0.0
var tiempo_desde_disparo := 0.0
var FireballScene: PackedScene = null

func _ready():
	# no se usan disparos en minions ahora
	pass

var can_shoot = true
var fireball_scene = preload("res://Scenes/Entities/FireBall.tscn")

func _ready():
	$AttackTimer.timeout.connect(_on_AttackTimer_timeout)

func _on_AttackTimer_timeout():
	can_shoot = true

func shoot():
	if can_shoot:
		# Determinar objetivo en el momento de disparar
		var target_dir = direccion
		var current_scene = get_tree().get_current_scene()
		var player = null
		if current_scene:
			# Try common node names, prefer the snake_case `personaje_principal`
			player = current_scene.get_node_or_null("personaje_principal")
			if not player:
				player = current_scene.get_node_or_null("personajePrincipal")
			if not player:
				player = current_scene.find_node("personaje_principal", true, false)
			if not player:
				player = current_scene.find_node("personajePrincipal", true, false)
		if player:
			# Calcular dirección desde la posición del minion hacia la posición del player
			target_dir = (player.global_position - global_position).normalized()

		if target_dir == Vector2.ZERO:
			return

		can_shoot = false
		$AttackTimer.start()
		var fireball = fireball_scene.instantiate()
		# Posicionar la bola de fuego justo delante del minion en la dirección calculada
		var offset = target_dir * 100
		fireball.global_position = global_position + offset
		fireball.set_direction(target_dir)
		var root_scene = get_tree().get_current_scene()
		if root_scene:
			root_scene.add_child(fireball)
		else:
			get_parent().add_child(fireball)

func mover_personaje(delta):
	tiempo_actual += delta
	if tiempo_actual > tiempo_cambio:
		direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tiempo_actual = 0.0
	velocity = direccion * speed
	move_and_slide()
	shoot()
	# Ensure minion stays inside viewport/world bounds
	_clamp_to_viewport()

func _physics_process(delta):
	mover_personaje(delta)

	# Mantener dentro del viewport
	keep_in_viewport()


	
