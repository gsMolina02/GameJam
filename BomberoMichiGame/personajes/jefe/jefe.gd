extends "res://personajes/personaje_base.gd"

var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0
var tiempo_disparo := 0.6
var tiempo_desde_disparo := 0.0
var FireballScene: PackedScene = null
@export var orbit_count := 7
@export var orbit_radius := 48.0
@export var orbit_angular_speed := 2.0
@export var respawn_delay := 1.2
@export var launch_spread_deg := 30.0
@export var launch_speed_multiplier := 1.0

var orbit_fireballs := []
var orbit_angles := []

func mover_personaje(delta):
	tiempo_actual += delta
	if tiempo_actual > tiempo_cambio:
		direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tiempo_actual = 0.0
	velocity = direccion * speed
	move_and_slide()

func _physics_process(delta):
	mover_personaje(delta)

	# Mantener dentro del viewport
	keep_in_viewport()

	# actualizar órbita de fireballs
	_update_orbit(delta)

	# Manejo de disparos: dispara cada tiempo_disparo segundos
	tiempo_desde_disparo += delta
	if tiempo_desde_disparo >= tiempo_disparo:
		tiempo_desde_disparo = 0.0
		# si hay orbs listos, lanzarlas; si no, spawnearlas
		if orbit_fireballs.size() == 0:
			_spawn_orbit_fireballs()
		else:
			_lanzar_orbita()


func _ready():
	FireballScene = load("res://personajes/minions/fireball_visual.tscn")

	# inicialmente crear orbs para el jefe
	_spawn_orbit_fireballs()


func _disparar_triple():
	var scene = get_tree().current_scene
	if scene == null:
		return
	var jugador: Node = null
	if scene.has_node("personajePrincipal"):
		jugador = scene.get_node("personajePrincipal")
	else:
		jugador = scene.get_node_or_null("../personajePrincipal")
	if jugador == null:
		return

	var base_dir = (jugador.global_position - global_position).normalized()
	var spread_deg = 15
	var dirs = [base_dir.rotated(deg_to_rad(-spread_deg)), base_dir, base_dir.rotated(deg_to_rad(spread_deg))]

	for d in dirs:
		if FireballScene == null:
			continue
		var fb = FireballScene.instantiate()
		fb.position = global_position
		fb.velocity = d * fb.speed
		scene.call_deferred("add_child", fb)


func _spawn_orbit_fireballs():
	# limpiar anteriores si existen
	for fb in orbit_fireballs:
		if fb and fb.is_inside_tree():
			fb.queue_free()
	orbit_fireballs.clear()
	orbit_angles.clear()
	if FireballScene == null:
		return
	# generar N fireballs alrededor del jefe
	var scene = get_tree().current_scene
	for i in range(orbit_count):
		var fb = FireballScene.instantiate()
		# iniciar en la posición del jefe
		fb.position = global_position
		# las fireballs orbitan, por eso no tendrán velocidad hasta lanzarlas
		fb.velocity = Vector2.ZERO
		scene.call_deferred("add_child", fb)
		orbit_fireballs.append(fb)
		var angle = TAU * i / orbit_count
		orbit_angles.append(angle)


func _update_orbit(delta):
	# actualizar ángulos y posiciones de las fireballs si existen
	for i in range(orbit_fireballs.size()):
		var fb = orbit_fireballs[i]
		if not fb or not fb.is_inside_tree():
			continue
		orbit_angles[i] += orbit_angular_speed * delta
		var pos = Vector2(cos(orbit_angles[i]), sin(orbit_angles[i])) * orbit_radius
		fb.global_position = global_position + pos


func _lanzar_orbita():
	# lanzar todas las fireballs hacia el jugador
	var scene = get_tree().current_scene
	if scene == null:
		return
	var jugador: Node = null
	if scene.has_node("personajePrincipal"):
		jugador = scene.get_node("personajePrincipal")
	else:
		jugador = scene.get_node_or_null("../personajePrincipal")
	if jugador == null:
		return

	# para cada orb, calcular una dirección desde su posición hacia el jugador
	for i in range(orbit_fireballs.size()):
		var fb = orbit_fireballs[i]
		if not fb or not fb.is_inside_tree():
			continue
		# dirección base desde la orb hacia el jugador
		var dir = (jugador.global_position - fb.global_position).normalized()
		# calcular offset angular de dispersión según el índice (distribuido entre -launch_spread_deg y +launch_spread_deg)
		var n = orbit_fireballs.size()
		var t = 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		else:
			t = 0.5
		# proteger launch_spread_deg por si está a null
		var ls := 0.0
		if launch_spread_deg != null:
			ls = float(launch_spread_deg)
		var angle_offset = lerp(-ls, ls, t)
		# aplicar rotación para dispersar la dirección
		dir = dir.rotated(deg_to_rad(angle_offset))
		# aplicar multiplicador de velocidad
		fb.velocity = dir * fb.speed * launch_speed_multiplier
	# vaciar la lista (las instancias siguen en escena pero ya tienen velocidad)
	orbit_fireballs.clear()
	orbit_angles.clear()
	# regenerar inmediatamente nuevas bolas para que el jefe siempre aparezca cargado
	_spawn_orbit_fireballs()
