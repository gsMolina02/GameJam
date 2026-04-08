extends "res://personajes/personaje_base.gd"
@export ""
var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0
var tiempo_desde_disparo := 0.0
var FireballScene: PackedScene = null

# Variables de vida del jefe
@export var vida_maxima_jefe: float = 500.0
var vida_actual_jefe: float = 500.0
var hud_boss = null  # Referencia al HUD del jefe

# Parámetros de las bolas de fuego orbitales
@export var orbit_count := 5  # Cantidad de bolas en órbita
@export var orbit_radius := 160.0
@export var orbit_angular_speed := 2.0
@export var fire_rate := 2.0  # Frecuencia de disparo (segundos entre disparos)
@export var respawn_delay := 1.2
@export var launch_spread_deg := 30.0
@export var launch_speed_multiplier := 1.0



var orbit_fireballs := []
var orbit_angles := []

# Minion spawning
@export var minion_scene: PackedScene = null
@export var minion_spawn_interval := 180.0  # Spawn minion cada 3 minutos (180 segundos) SOLO si no hay minions
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
	
	# Spawn minions periódicamente - SOLO si no hay minions activos
	minion_spawn_timer += delta
	var minions_activos = _count_active_minions()
	if minion_spawn_timer >= minion_spawn_interval and minions_activos == 0:
		minion_spawn_timer = 0.0
		print("⚠️ 3 minutos pasaron sin minions. Spawneando nuevo minion...")
		_spawn_minion()
	elif minions_activos > 0 and minion_spawn_timer > 0.1:  # Resetear timer si hay minions
		print("👹 Aún hay ", minions_activos, " minions en el mapa. Esperando...")
		minion_spawn_timer = 0.0


func _ready():
	# Si ya fue destruido, no reaparecer
	if "nodos_destruidos" in GameManager and str(get_path()) in GameManager.nodos_destruidos:
		queue_free()
		return

	FireballScene = load("res://personajes/minions/fireball_visual.tscn")
	minion_scene = load("res://personajes/minions/minions.tscn")
	
	# ============ INICIALIZAR VIDA DEL JEFE ============
	vida_actual_jefe = vida_maxima_jefe
	print("✓ Jefe iniciado con vida: ", vida_actual_jefe, "/", vida_maxima_jefe)
	
	# ============ BUSCAR Y CONECTAR HUD ============
	# Buscar el HUD en la escena
	var scene = get_tree().current_scene
	if scene:
		# Intentar diferentes rutas
		hud_boss = scene.get_node_or_null("CanvasLayer2/HudBoss")  # Ruta correcta en CasinoBoss
		if not hud_boss:
			hud_boss = scene.get_node_or_null("CanvasLayer/HudBoss")  # Si está bajo CanvasLayer
		if not hud_boss:
			hud_boss = scene.get_node_or_null("HudBoss")  # O directamente en la raíz
		if not hud_boss:
			hud_boss = scene.get_node_or_null("../HudBoss")  # O un nivel arriba
		if not hud_boss:
			# Búsqueda más amplia
			hud_boss = scene.find_child("HudBoss", true, false)
	
	if hud_boss and hud_boss.has_method("actualizar_interfaz"):
		hud_boss.actualizar_interfaz(vida_actual_jefe, vida_maxima_jefe)
		print("✓ HUD del jefe conectado en: ", hud_boss.get_path())
	else:
		print("⚠️ HUD del jefe no encontrado. Buscando en escena...")
		print("   Escena actual: ", scene.name if scene else "Ninguna")
		if scene:
			for child in scene.get_children():
				print("   - Nodo: ", child.name)
	
	# Agregar el jefe al grupo "enemy" y "boss"
	add_to_group("enemy")
	add_to_group("boss")

	# Asegurar que el cuerpo físico del jefe esté en la capa de enemigos (2)
	# y detecte al jugador (máscara = 1). Esto permite que las áreas del jugador
	# (hacha/manguera) lo detecten correctamente.
	if has_method("set_collision_layer_value"):
		set_collision_layer_value(2, true)
		set_collision_mask_value(1, true)
	else:
		collision_layer = 2
		collision_mask = 1
	
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

	# Reproducir sonido de ataque de fuego
	if jugador.has_method("_play_fire_attack_sound"):
		jugador._play_fire_attack_sound()

	var base_dir = (jugador.global_position - global_position).normalized()
	var spread_deg = 15
	var dirs = [base_dir.rotated(deg_to_rad(-spread_deg)), base_dir, base_dir.rotated(deg_to_rad(spread_deg))]

	for d in dirs:
		if FireballScene == null:
			continue
		var fb = FireballScene.instantiate()
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
	if FireballScene == null:
		return
	for i in range(orbit_count):
		var fb = FireballScene.instantiate()
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


func _count_active_minions() -> int:
	"""Cuenta cuántos minions hay activos en la escena"""
	var scene = get_tree().current_scene
	if not scene:
		return 0
	
	var minions = 0
	# Buscar todos los nodos que sean minions
	for child in scene.find_children("*", "CharacterBody2D", true, false):
		if child.is_in_group("minion") or child.name.contains("Minion") or child.name.contains("minion"):
			if child.is_inside_tree():
				minions += 1
	
	# Método alternativo: buscar por script
	for child in scene.get_children():
		if child.script and child.script.resource_path.contains("minion"):
			if child.is_inside_tree():
				minions += 1
	
	print("📊 Minions activos en escena: ", minions)
	return minions


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
	print("👹 Minion spawneado después de 3 minutos en: ", spawn_pos)


func take_damage(amount: float) -> void:
	"""Recibe daño y verifica si muere. Usa el sistema de vida propia del jefe."""
	vida_actual_jefe -= amount
	vida_actual_jefe = clamp(vida_actual_jefe, 0, vida_maxima_jefe)
	
	print("🔴 Jefe recibió daño: ", amount, " (Vida: ", vida_actual_jefe, "/", vida_maxima_jefe, ")")
	
	# Actualizar HUD
	if hud_boss and hud_boss.has_method("actualizar_interfaz"):
		hud_boss.actualizar_interfaz(vida_actual_jefe, vida_maxima_jefe)
		print("✓ HUD actualizado: ", vida_actual_jefe, "/", vida_maxima_jefe)
	else:
		print("⚠️ HUD no disponible para actualizar")
	
	# Efecto visual: cambiar color a rojo por un momento (ejecutar sin esperar)
	_flash_damage()
	
	if vida_actual_jefe <= 0:
		die()


func apply_water(amount: float) -> void:
	"""Recibe daño por agua de la manguera."""
	take_damage(amount)
	print("💧 Jefe recibió agua: ", amount)


func _flash_damage() -> void:
	"""Efecto visual de daño: flash rojo"""
	var animated_sprite = get_node_or_null("bossAnimated")
	
	if not animated_sprite:
		# Si no hay sprite con ese nombre, buscar el primer AnimatedSprite2D
		for child in get_children():
			if child is AnimatedSprite2D:
				animated_sprite = child
				break
	
	if animated_sprite:
		# Guardar color original
		var original_color = Color.WHITE
		# Flash rojo
		animated_sprite.modulate = Color.RED
		print("🔴 Flash de daño activado")
		
		# Esperar y restaurar usando un timer
		await get_tree().create_timer(0.2).timeout
		if is_inside_tree():  # Verificar que el nodo aún existe
			animated_sprite.modulate = original_color
			print("✓ Color restaurado")


func die() -> void:
	"""Muerte del jefe"""
	print("💀 ¡¡¡ JEFE DEL CASINO DERROTADO !!!")
	print("🎊 Victoria alcanzada después de una batalla épica")
	print("¡Jefe derrotado!")

	if "nodos_destruidos" in GameManager:
		GameManager.registrar_nodo_destruido(str(get_path()))

		


func _on_hit_area_area_entered(area: Node) -> void:
	"""Cuando el HitArea del jefe detecta un Area2D (como el Hitbox del jugador)"""
	# El daño se maneja automáticamente por el sistema de grupos
	# cuando el Hitbox del jugador detecta esta área que está en "ataque_jefe"
	if area.get_parent() and area.get_parent().is_in_group("player_main"):
		print_debug("Jefe HitArea entered player Hitbox - damage will be handled by player's system")
