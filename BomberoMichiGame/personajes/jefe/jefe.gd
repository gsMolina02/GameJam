extends "res://personajes/personaje_base.gd"
@export ""
var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0
var tiempo_desde_disparo := 0.0
var FireballSceneBoss: PackedScene = null
var FireballSceneMinion: PackedScene = null

# Parámetros de las bolas de fuego orbitales
@export var orbit_count := 5  # Cantidad de bolas en órbita
@export var orbit_radius := 160.0
@export var orbit_angular_speed := 2.0
@export var fire_rate := 2.0  # Frecuencia de disparo (segundos entre disparos)
@export var respawn_delay := 1.2
@export var launch_spread_deg := 30.0
@export var launch_speed_multiplier := 1.0

# Sistema de vida del jefe
@export var max_health := 100.0
var health := 100.0

var orbit_fireballs := []
var orbit_angles := []

# Minion spawning
@export var minion_scene: PackedScene = null
@export var minion_spawn_interval := 5.0  # Spawn minion cada 5 segundos
@export var min_spawn_distance := 150.0  # Distancia mínima del bombero para spawn
var minion_spawn_timer := 0.0

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

	# Manejo de disparos: dispara cada fire_rate segundos
	tiempo_desde_disparo += delta
	if tiempo_desde_disparo >= fire_rate:
		tiempo_desde_disparo = 0.0
		# si hay orbs listos, lanzarlas; si no, spawnearlas
		if orbit_fireballs.size() == 0:
			_spawn_orbit_fireballs()
		else:
			_lanzar_orbita()
	
	# Spawn minions periódicamente
	minion_spawn_timer += delta
	if minion_spawn_timer >= minion_spawn_interval:
		minion_spawn_timer = 0.0
		_spawn_minion()


func _ready():
	FireballSceneBoss = load("res://personajes/minions/fireball_boss.tscn")
	FireballSceneMinion = load("res://personajes/minions/fireball_visual.tscn")
	minion_scene = load("res://personajes/minions/minions.tscn")
	
	# Agregar el jefe al grupo "enemy" y "boss"
	add_to_group("enemy")
	add_to_group("boss")
	
	# Crear un HitArea para detectar colisiones con el jugador
	var hit_area = Area2D.new()
	hit_area.name = "HitArea"
	add_child(hit_area)
	
	# IMPORTANTE: Configurar en la capa 2 para que el Hitbox del jugador (mask=2) lo detecte
	hit_area.collision_layer = 2
	hit_area.collision_mask = 1  # Detectar capa 1 (jugador)
	
	# Agregar el HitArea al grupo para que el Hitbox del jugador lo detecte
	hit_area.add_to_group("ataque_jefe")
	
	# Crear un CollisionShape circular para el área de ataque
	var hit_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 70.0  # El jefe es más grande, su área de ataque también
	hit_shape.shape = circle
	hit_area.add_child(hit_shape)
	
	# Conectar señales
	if hit_area.has_signal("area_entered"):
		hit_area.area_entered.connect(_on_hit_area_area_entered)

	# Crear DamageArea para recibir daño de la manguera
	var damage_area = Area2D.new()
	damage_area.name = "DamageArea"
	add_child(damage_area)
	
	# Configurar en la capa 2 para que la manguera (mask=2) lo detecte
	damage_area.collision_layer = 2
	damage_area.collision_mask = 0  # No necesita detectar nada
	
	# Crear CollisionShape para el DamageArea (más grande para facilitar el disparo)
	var damage_shape = CollisionShape2D.new()
	var damage_circle = CircleShape2D.new()
	damage_circle.radius = 100.0  # Radio generoso para recibir agua
	damage_shape.shape = damage_circle
	damage_area.add_child(damage_shape)
	
	print("✓ Jefe inicializado con HitArea (ataque) y DamageArea (recibe agua)")

	# inicialmente crear orbs para el jefe
	_spawn_orbit_fireballs()


func _disparar_triple():
	var scene = get_tree().current_scene
	if scene == null:
		return
	var jugador: Node = scene.get_node_or_null("personajePrincipal")
	if jugador == null:
		jugador = scene.get_node_or_null("../personajePrincipal")
	if jugador == null:
		return

	var base_dir = (jugador.global_position - global_position).normalized()
	var spread_deg = 15
	var dirs = [base_dir.rotated(deg_to_rad(-spread_deg)), base_dir, base_dir.rotated(deg_to_rad(spread_deg))]

	for d in dirs:
		if FireballSceneBoss == null:
			continue
		var fb = FireballSceneBoss.instantiate()
		if fb.has_method("set_shooter"):
			fb.set_shooter(self)
		# Instanciar como hijo del jefe y usar posición local
		fb.position = Vector2.ZERO
		fb.velocity = d * fb.speed
		call_deferred("add_child", fb)
		# Lanzar inmediatamente: reparent al root y mantener posición global
		var root = get_tree().current_scene if get_tree() else null
		if root:
			var world_pos = fb.get_global_position()
			fb.set_global_position(world_pos)
			fb.get_parent().call_deferred("remove_child", fb)
			root.call_deferred("add_child", fb)


func _spawn_orbit_fireballs():
	# limpiar anteriores si existen
	for fb in orbit_fireballs:
		if fb and fb.is_inside_tree():
			fb.queue_free()
	orbit_fireballs.clear()
	orbit_angles.clear()
	if FireballSceneBoss == null:
		return
	for i in range(orbit_count):
		var fb = FireballSceneBoss.instantiate()
		if fb.has_method("set_shooter"):
			fb.set_shooter(self)
		fb.position = Vector2.ZERO
		fb.velocity = Vector2.ZERO
		call_deferred("add_child", fb)
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
		fb.position = pos


func _lanzar_orbita():
	# lanzar todas las fireballs hacia el jugador
	var scene = get_tree().current_scene
	if scene == null:
		return
	var jugador: Node = scene.get_node_or_null("personajePrincipal")
	if jugador == null:
		jugador = scene.get_node_or_null("../personajePrincipal")
	if jugador == null:
		return

	# para cada orb, calcular una dirección desde su posición hacia el jugador
	for i in range(orbit_fireballs.size()):
		var fb = orbit_fireballs[i]
		if not fb or not fb.is_inside_tree():
			continue
		# Calcular posición global antes de lanzar
		var world_pos = fb.get_global_position()
		var dir = (jugador.global_position - world_pos).normalized()
		var n = orbit_fireballs.size()
		var t = 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		else:
			t = 0.5
		var ls := 0.0
		if launch_spread_deg != null:
			ls = float(launch_spread_deg)
		var angle_offset = lerp(-ls, ls, t)
		dir = dir.rotated(deg_to_rad(angle_offset))
		if fb.has_method("set_shooter"):
			fb.set_shooter(self)
		if fb.has_method("set_direction"):
			fb.set_direction(dir.rotated(0))
			var try_vel = fb.get("velocity")
			if try_vel != null:
				fb.set("velocity", dir * (fb.get("speed") if fb.get("speed") != null else fb.speed) * launch_speed_multiplier)
		else:
			fb.set("velocity", dir * (fb.get("speed") if fb.get("speed") != null else fb.speed) * launch_speed_multiplier)
		# Reparent to scene root and keep world position
		var root = get_tree().current_scene if get_tree() else null
		if root:
			fb.set_global_position(world_pos)
			fb.get_parent().call_deferred("remove_child", fb)
			root.call_deferred("add_child", fb)
	# vaciar la lista (las instancias siguen en escena pero ya tienen velocidad)
	orbit_fireballs.clear()
	orbit_angles.clear()
	# regenerar inmediatamente nuevas bolas para que el jefe siempre aparezca cargado
	_spawn_orbit_fireballs()


func _spawn_minion():
	"""Spawns a minion away from the firefighter"""
	if minion_scene == null:
		return
	
	var scene = get_tree().current_scene
	if scene == null:
		return

	# Predeclare instance variable to avoid confusable redeclaration warnings
	var m: Node2D = null
	
	# Buscar al bombero (firefighter)
	var bombero: Node = scene.get_node_or_null("personajePrincipal")
	if bombero == null:
		bombero = scene.get_node_or_null("../personajePrincipal")
	
	if bombero == null:
		# Si no hay bombero, spawn cerca del jefe
		m = minion_scene.instantiate()
		var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		m.global_position = global_position + offset
		scene.call_deferred("add_child", m)
		return
	
	# Calcular posición de spawn lejos del bombero
	var spawn_pos := Vector2.ZERO
	var attempts := 0
	var max_attempts := 10
	
	while attempts < max_attempts:
		# Generar posición aleatoria alrededor del jefe
		var angle = randf() * TAU
		var distance = randf_range(100, 300)
		spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Verificar que esté lejos del bombero
		var distance_to_bombero = spawn_pos.distance_to(bombero.global_position)
		if distance_to_bombero >= min_spawn_distance:
			break
		
		attempts += 1
	
	# Instanciar el minion
	m = minion_scene.instantiate()
	m.global_position = spawn_pos
	scene.call_deferred("add_child", m)
	print_debug("Jefe spawned minion at:", spawn_pos, "distance from bombero:", spawn_pos.distance_to(bombero.global_position))


func take_damage(amount: float) -> void:
	"""Recibe daño y verifica si muere"""
	health -= amount
	print_debug("Jefe took damage:", amount, "health remaining:", health)
	
	if health <= 0:
		die()


func apply_water(amount: float) -> void:
	"""Recibe daño por agua de la manguera"""
	take_damage(amount)


func die() -> void:
	"""Muerte del jefe"""
	print("¡Jefe derrotado!")
	# Aquí puedes agregar efectos de muerte, sonidos, etc.
	queue_free()


func _on_hit_area_area_entered(area: Node) -> void:
	"""Cuando el HitArea del jefe detecta un Area2D (como el Hitbox del jugador)"""
	# El daño se maneja automáticamente por el sistema de grupos
	# cuando el Hitbox del jugador detecta esta área que está en "ataque_jefe"
	if area.get_parent() and area.get_parent().is_in_group("player_main"):
		print_debug("Jefe HitArea entered player Hitbox - damage will be handled by player's system")
