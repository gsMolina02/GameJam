extends CharacterBody2D

@export var speed: float = 260.0
@export var detection_radius: float = 220.0
@export var attack_radius: float = 70.0
@export var chase_stop_distance: float = 92.0
@export var target_group: StringName = &"player_main"
@export var max_health: float = 40.0

@export var idle_animation: StringName = &"SabuesoIdle"
@export var run_animation: StringName = &"SabuesoRun"
@export var attack_idle_animation: StringName = &"SabuesoAtackIdle"
@export var jump_attack_animation: StringName = &"SabuesoSalt"
@export var hurt_water_animation: StringName = &"SabuesoDanioAgua"
@export var hurt_axe_animation: StringName = &"SabuesoDanioAxe"
@export var hurt_general_animation: StringName = &"SabuesoDanioGenrl"
@export var death_animation: StringName = &"SabuesoMuert"
@export var hurt_animation_time: float = 0.5  # Aumentado para animacion visible
@export var death_queue_free_delay: float = 0.9
@export var sprite_faces_right_by_default: bool = false

# Parámetros de ataque
@export var general_attack_damage: float = 8.0
@export var jump_attack_damage: float = 12.0
@export var jump_attack_distance: float = 150.0  # Distancia que se lanza en el salto
@export var jump_attack_duration: float = 0.6  # Duración del salto
@export var attack_cooldown: float = 1.5  # Tiempo entre ataques
@export var attack_telegraph_general: float = 0.35
@export var attack_telegraph_jump: float = 0.45
@export var jump_recovery_time: float = 0.8  # Ventana de castigo despues del salto
@export var phase_two_health_ratio: float = 0.5
@export var phase_two_jump_chance: float = 0.65
@export var phase_two_cooldown_multiplier: float = 0.75
@export var health_bar_show_time: float = 1.8

# Variables de IA mejorada
@export var patrol_speed: float = 100.0
@export var wander_change_interval: float = 2.0

# Sistema de detección mejorado con visión en cono
@export var vision_fov_angle: float = 120.0
@export var vision_ray_count: int = 7
@export var vision_debug: bool = false

var _wander_direction: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _search_state: String = "idle"
var _last_known_direction: Vector2 = Vector2.RIGHT
var _sprite_base_position: Vector2 = Vector2.ZERO
var _attack_push_offset: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var health_bar: ProgressBar = $HealthBar

var target: Node2D = null
var _search_cooldown: int = 0
var _deep_search_cooldown: int = 0
var _current_health: float = 0.0
var _is_dead: bool = false
var _anim_lock_timer: float = 0.0
var _locked_animation: StringName = &""
var _attack_cooldown_timer: float = 0.0
var _is_attacking: bool = false
var _last_attack_type: String = "general"  # "general" o "jump"
var _attack_state: String = "idle"  # idle | windup | executing | recovery
var _health_bar_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("hellhound")
	_current_health = max_health
	_sprite_base_position = sprite.position if sprite else Vector2.ZERO
	_configure_detection_area()

	if detection_area.body_entered.is_connected(_on_detection_body_entered) == false:
		detection_area.body_entered.connect(_on_detection_body_entered)
	if detection_area.body_exited.is_connected(_on_detection_body_exited) == false:
		detection_area.body_exited.connect(_on_detection_body_exited)

	_sync_detection_shape()
	_configure_health_bar()
	_play_animation_if_exists(idle_animation, run_animation)
	target = _find_player()
	_update_facing_direction()

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# DEBUG: mostrar estado actual
	if vision_debug and int(get_physics_process_delta_time() * 60) % 30 == 0:
		print("─ Estado HellHound: pos=%s, estado=%s, target=%s, area_bodies=%d" % [
			global_position,
			_search_state,
			target.name if target else "NONE",
			detection_area.get_overlapping_bodies().size() if detection_area else 0
		])

	if _anim_lock_timer > 0.0:
		_anim_lock_timer -= delta
		if _anim_lock_timer <= 0.0:
			_anim_lock_timer = 0.0
			_locked_animation = &""

	# Cooldown del ataque
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	if health_bar and health_bar.visible and _health_bar_timer > 0.0:
		_health_bar_timer -= delta
		if _health_bar_timer <= 0.0 and not _is_dead:
			health_bar.visible = false

	# Sistema de busqueda mejorado CON visión de cono
	if target == null or not is_instance_valid(target):
		_search_cooldown -= 1
		if _search_cooldown <= 0:
			# 1. Intentar detección con raycast en cono de visión
			target = _detect_player_with_vision()
			if target == null:
				# 2. Fallback: búsqueda básica si no ve nada
				target = _find_player()
			_search_cooldown = 15  # Más rápido ahora (15 frames en lugar de 30)
			if target == null:
				_search_state = "wandering"
		else:
			_search_state = "chasing"

	if target and is_instance_valid(target):
		var target_pos := _get_target_focus_position(target)
		var dir := (target_pos - global_position)
		var distance := dir.length()
		if _is_attacking:
			velocity = Vector2.ZERO
			_search_state = "attacking"
			_last_known_direction = dir.normalized() if distance > 0.1 else _last_known_direction
		elif distance <= attack_radius:
			velocity = Vector2.ZERO
			_search_state = "attacking"
			_last_known_direction = dir.normalized() if distance > 0.1 else _last_known_direction
		elif distance <= chase_stop_distance:
			velocity = Vector2.ZERO
			_search_state = "attacking"
			_last_known_direction = dir.normalized() if distance > 0.1 else _last_known_direction
		elif distance <= detection_radius:
			velocity = dir.normalized() * speed
			_search_state = "chasing"
			_last_known_direction = dir.normalized()
		else:
			velocity = Vector2.ZERO
			_search_state = "idle"
	else:
		# Sin objetivo: movimiento de busqueda / patrulla
		_update_wander_behavior(delta)

	_update_attack_visual_push(target if target and is_instance_valid(target) else null)

	move_and_slide()
	_update_facing_direction()
	_update_facing()
	_update_animation_state()

func _on_detection_body_entered(body: Node) -> void:
	"""El personaje entró al área de detección"""
	if body is Node2D and _is_player(body):
		target = body as Node2D
		if vision_debug:
			print("🔔 Personaje ENTRÓ al área - detectado!")

func _on_detection_body_exited(body: Node) -> void:
	"""El personaje salió del área de detección"""
	if body == target:
		target = null
		if vision_debug:
			print("💨 Personaje SALIÓ del área - perdido!")

func _is_player(node: Node) -> bool:
	if node.is_in_group(target_group):
		return true
	if node.is_in_group("player"):
		return true
	return node.name in ["personajePrincipal", "Player", "player"]

# ============================================
# SISTEMA DE DETECCIÓN CON VISIÓN EN CONO
# ============================================
func _detect_player_with_vision() -> Node2D:
	"""Detecta al jugador usando Area2D (más confiable que raycast)"""
	if detection_area == null:
		return null
	
	# Usar el Area2D que ya está en el nodo
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if _is_player(body):
			if vision_debug:
				print("✅ Area2D detectó: ", body.name)
			return body as Node2D
	
	return null

func _raycast_omnidirectional() -> Node2D:
	"""Búsqueda en 360° cuando el HellHound está quieto"""
	var ray_count = vision_ray_count * 3  # Más raycast para cobertura total
	
	for i in range(ray_count):
		var angle = (float(i) / ray_count) * TAU
		var ray_direction = Vector2(cos(angle), sin(angle)).normalized()
		var hit_player = _raycast_check(ray_direction)
		
		if hit_player:
			_last_known_direction = ray_direction
			return hit_player
	
	return null

func _raycast_check(direction: Vector2) -> Node2D:
	"""Lanza un raycast en una dirección y verifica si toca al jugador"""
	var ray_distance = detection_radius
	var space_state = get_world_2d().direct_space_state
	var ray_start = global_position
	var ray_end = global_position + direction * ray_distance
	var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	
	query.exclude = [self]
	query.collision_mask = 3
	
	# Debug visual (descomenta el _draw() de abajo si quieres ver raycast)
	if vision_debug:
		add_point_for_debug(ray_end)
	
	var result = space_state.intersect_ray(query)
	
	if result and result.has("collider"):
		var collider = result.collider
		if _is_player(collider):
			if vision_debug:
				print("✓ Raycast detectó: ", collider.name, " en posición ", result.position)
			return collider as Node2D
	
	return null

var debug_points: Array[Vector2] = []

func add_point_for_debug(point: Vector2) -> void:
	if debug_points.size() > 100:
		debug_points.clear()
	debug_points.append(point)

func _draw() -> void:
	if not vision_debug:
		return
	
	# Dibujar círculo de detección
	draw_circle(Vector2.ZERO, detection_radius, Color(1, 1, 0, 0.2))
	draw_circle(Vector2.ZERO, detection_radius, Color.YELLOW, false, 2.0)
	
	# Dibujar puntos de raycast si existen
	for point in debug_points:
		draw_circle(point - global_position, 3, Color.YELLOW)
	
	# Dibujar dirección de búsqueda actual
	if _last_known_direction != Vector2.ZERO:
		draw_line(Vector2.ZERO, _last_known_direction * 50, Color.RED, 2.0)
	
	# Mostrar estado
	var state_color = Color.RED if _is_dead else Color.YELLOW
	if _search_state == "chasing":
		state_color = Color.RED
	elif _search_state == "wandering":
		state_color = Color.YELLOW
	else:
		state_color = Color.GREEN
	
	draw_circle(Vector2(0, -detection_radius - 20), 5, state_color)

func _update_facing_direction() -> void:
	"""Actualiza la dirección hacia la que mira el HellHound"""
	if velocity.length_squared() > 0.1:
		_last_known_direction = velocity.normalized()
	
	# Atajo para debug: presionar D
	if Input.is_action_just_pressed("ui_select"):  # Espacio
		vision_debug = !vision_debug
		print("Debug HellHound: ", "ACTIVADO" if vision_debug else "DESACTIVADO")

func _find_player() -> Node2D:
	# Fast path: no crea arrays y funciona bien con muchas instancias.
	var main_player := get_tree().get_first_node_in_group(target_group)
	if main_player and main_player is Node2D:
		return main_player as Node2D

	var fallback_player := get_tree().get_first_node_in_group("player")
	if fallback_player and fallback_player is Node2D:
		return fallback_player as Node2D

	# Deep path: búsqueda por nombre, pero solo cada cierto tiempo para evitar picos.
	_deep_search_cooldown -= 1
	if _deep_search_cooldown <= 0:
		_deep_search_cooldown = 120
		var scene := get_tree().current_scene
		if scene:
			for candidate_name in ["personajePrincipal", "Player", "player"]:
				var n := scene.find_child(candidate_name, true, false)
				if n and n is Node2D:
					return n as Node2D

	return null

func _ready() -> void:
	if "nodos_destruidos" in GameManager and str(get_path()) in GameManager.nodos_destruidos:
		queue_free()
		return

	# Asegurar que los nodos existan
	if anim_player == null:
		push_error("HellHound: no se encontró AnimatedSprite2D!")
	if wait_timer == null:
		push_error("HellHound: no se encontró el Timer de espera!")

func _sync_detection_shape() -> void:
	var shape_node := detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return

	var circle := shape_node.shape as CircleShape2D
	if circle:
		circle.radius = detection_radius

func _configure_detection_area() -> void:
	if detection_area == null:
		return

	# Esta area es solo para IA (deteccion), no para hacer dano.
	detection_area.monitoring = true
	detection_area.monitorable = false
	detection_area.collision_layer = 0
	# Detectar cuerpos del jugador en capas comunes (1 y 2).
	detection_area.collision_mask = 1 | 2

	for group_name in ["ataque_minion", "ataque_enemigo", "ataque_jefe", "fuego"]:
		if detection_area.is_in_group(group_name):
			detection_area.remove_from_group(group_name)

func _configure_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.min_value = 0.0
	health_bar.max_value = max_health
	health_bar.value = _current_health
	health_bar.visible = false

func _refresh_health_bar(show_temporarily: bool = true) -> void:
	if health_bar == null:
		return

	health_bar.max_value = max_health
	health_bar.value = clampf(_current_health, 0.0, max_health)
	if show_temporarily:
		health_bar.visible = true
		_health_bar_timer = max(health_bar_show_time, 0.1)

func _play_run() -> void:
	_play_animation_if_exists(run_animation, idle_animation)

func _update_animation_state() -> void:
	if sprite == null:
		return

	if _is_dead:
		_play_animation_if_exists(death_animation, idle_animation)
		return

	if _anim_lock_timer > 0.0 and _locked_animation != &"":
		_play_animation_if_exists(_locked_animation, idle_animation)
		return

	if _is_attacking:
		if _attack_state == "recovery":
			_play_animation_if_exists(attack_idle_animation, idle_animation)
		return

	if target and is_instance_valid(target) and global_position.distance_to(_get_target_focus_position(target)) <= chase_stop_distance:
		# Está en rango de ataque
		if _attack_cooldown_timer <= 0.0 and not _is_attacking:
			# Es momento de atacar
			_trigger_random_attack()
		_play_animation_if_exists(attack_idle_animation, idle_animation)
	elif velocity.length_squared() > 1.0:
		_play_animation_if_exists(run_animation, idle_animation)
	else:
		_play_animation_if_exists(idle_animation, run_animation)

func _update_attack_visual_push(current_target: Node2D) -> void:
	if sprite == null:
		return

	if current_target == null or not is_instance_valid(current_target):
		_attack_push_offset = _attack_push_offset.lerp(Vector2.ZERO, 0.2)
		sprite.position = _sprite_base_position + _attack_push_offset
		return

	var target_pos := _get_target_focus_position(current_target)
	var delta_to_target := target_pos - global_position
	var distance := delta_to_target.length()

	if distance <= chase_stop_distance and distance > 0.1:
		var push_direction := -delta_to_target.normalized()
		var push_strength := 6.0
		var closeness := clampf(1.0 - (distance / chase_stop_distance), 0.0, 1.0)
		_attack_push_offset = push_direction * push_strength * closeness
	else:
		_attack_push_offset = _attack_push_offset.lerp(Vector2.ZERO, 0.2)

	sprite.position = _sprite_base_position + _attack_push_offset

func _get_target_focus_position(node: Node2D) -> Vector2:
	# Usa un punto de referencia mas estable del jugador para evitar sesgo arriba/abajo.
	var hitbox := node.get_node_or_null("Hitbox") as Node2D
	if hitbox:
		return hitbox.global_position

	var body_shape := node.get_node_or_null("CollisionShape2D") as Node2D
	if body_shape:
		return body_shape.global_position

	return node.global_position

func _play_animation_if_exists(primary: StringName, fallback: StringName = &"") -> bool:
	if sprite == null or sprite.sprite_frames == null:
		return false

	if primary != &"" and sprite.sprite_frames.has_animation(primary):
		if sprite.animation != primary or not sprite.is_playing():
			sprite.play(primary)
		return true

	if fallback != &"" and sprite.sprite_frames.has_animation(fallback):
		if sprite.animation != fallback or not sprite.is_playing():
			sprite.play(fallback)
		return true

	return false

func _play_temporary_animation(anim_name: StringName, duration: float) -> void:
	if _is_dead:
		return
	if sprite and sprite.sprite_frames and anim_name != &"" and sprite.sprite_frames.has_animation(anim_name):
		# Reinicia siempre la animación de daño para que el impacto sea visible.
		sprite.play(anim_name)
		sprite.frame = 0
		_locked_animation = anim_name
		_anim_lock_timer = max(duration, 0.01)
		return

	if _play_animation_if_exists(anim_name, idle_animation):
		_locked_animation = anim_name
		_anim_lock_timer = max(duration, 0.01)

func take_damage(amount: float, source: StringName = &"general") -> void:
	if _is_dead:
		return

	_current_health -= amount
	_refresh_health_bar(true)
	
	match source:
		&"agua", &"water":
			_play_temporary_animation(hurt_water_animation, hurt_animation_time)
			var health_percentage: int = int((_current_health / max_health) * 100)
			print("HellHound recibiendo agua - Salud: ", health_percentage, "%")
		&"hacha", &"axe":
			_play_temporary_animation(hurt_axe_animation, hurt_animation_time)
		_:
			_play_temporary_animation(hurt_general_animation, hurt_animation_time)
	
	if _current_health <= 0.0:
		print("HellHound derrotado!")
		die()
		return

func _trigger_random_attack() -> void:
	"""Selecciona ataque aleatorio con telegrafia previa y fase dinamica por vida."""
	if _is_attacking or _is_dead:
		return

	_is_attacking = true
	_attack_state = "windup"

	var jump_chance: float = 0.35
	if _is_phase_two():
		jump_chance = clampf(phase_two_jump_chance, 0.0, 1.0)

	var attack_type: String = "jump" if randf() < jump_chance else "general"
	_last_attack_type = attack_type

	if attack_type == "jump":
		_play_temporary_animation(jump_attack_animation, attack_telegraph_jump)
		await get_tree().create_timer(max(attack_telegraph_jump, 0.05)).timeout
		await _perform_jump_attack()
	else:
		_play_temporary_animation(attack_idle_animation, attack_telegraph_general)
		await get_tree().create_timer(max(attack_telegraph_general, 0.05)).timeout
		_perform_general_attack()

	_attack_state = "idle"
	_is_attacking = false
	_attack_cooldown_timer = _get_current_attack_cooldown()
	print("HellHound atacando: ", attack_type, " | fase2=", _is_phase_two())

func _perform_general_attack() -> void:
	"""Ataque general: mantiene la posición y ataca"""
	_attack_state = "executing"
	if target and is_instance_valid(target):
		var target_distance := global_position.distance_to(_get_target_focus_position(target))
		if target_distance <= attack_radius * 1.2 and target.has_method("take_damage"):
			target.take_damage(general_attack_damage)

func _perform_jump_attack() -> void:
	"""Ataque de salto: se lanza hacia el jugador con animación"""
	if not target or not is_instance_valid(target):
		return

	_attack_state = "executing"
	
	# Crear el movimiento del salto
	var target_pos := _get_target_focus_position(target)
	var direction := (target_pos - global_position).normalized()
	var jump_distance := direction * jump_attack_distance
	var initial_pos := global_position
	var end_pos := initial_pos + jump_distance

	var jump_tween := create_tween()
	jump_tween.tween_property(self, "global_position", end_pos, max(jump_attack_duration, 0.1)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await jump_tween.finished
	
	# Aplicar daño al jugador al final del salto si realmente cae cerca.
	if target and is_instance_valid(target):
		var impact_distance := global_position.distance_to(_get_target_focus_position(target))
		if impact_distance <= attack_radius * 1.5 and target.has_method("take_damage"):
			target.take_damage(jump_attack_damage)

	# Ventana de castigo: se queda vulnerable tras caer del salto.
	_attack_state = "recovery"
	_play_temporary_animation(attack_idle_animation, jump_recovery_time)
	await get_tree().create_timer(max(jump_recovery_time, 0.05)).timeout

func _is_phase_two() -> bool:
	if max_health <= 0.0:
		return false
	return _current_health <= max_health * clampf(phase_two_health_ratio, 0.05, 0.95)

func _get_current_attack_cooldown() -> float:
	var value := attack_cooldown
	if _is_phase_two():
		value *= max(phase_two_cooldown_multiplier, 0.2)
	return max(value, 0.2)

func apply_water(amount: float) -> void:
	take_damage(amount, &"agua")

func _die_sequence_finished() -> void:
	if is_inside_tree():
		if "nodos_destruidos" in GameManager:
			GameManager.registrar_nodo_destruido(str(get_path()))
		queue_free()

func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	velocity = Vector2.ZERO
	if detection_area:
		detection_area.monitoring = false
	if health_bar:
		health_bar.visible = false

	print("☠️  HellHound está muriendo...")
	_play_animation_if_exists(death_animation, idle_animation)
	
	# Extender el delay de muerte para que sea visible la animación (0.9 -> 1.5 segundos)
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		print("☠️  HellHound ha sido removido del juego")
		queue_free()

func _update_wander_behavior(delta: float) -> void:
	"""Comportamiento de busqueda/patrulla cuando no hay objetivo"""
	_wander_timer -= delta
	
	if _wander_timer <= 0.0:
		# Generar nueva dirección aleatoria
		var angle = randf() * TAU
		_wander_direction = Vector2(cos(angle), sin(angle)).normalized()
		_wander_timer = wander_change_interval
	
	# Movimiento lento mientras busca
	velocity = _wander_direction * patrol_speed

func _get_detection_area_info() -> Dictionary:
	"""Retorna informacion sobre el area de deteccion (para debugging)"""
	if detection_area == null:
		return {"error": "detection_area es null"}
	
	return {
		"monitoring": detection_area.monitoring,
		"collision_layer": detection_area.collision_layer,
		"collision_mask": detection_area.collision_mask,
		"overlapping_areas": detection_area.get_overlapping_areas().size(),
		"overlapping_bodies": detection_area.get_overlapping_bodies().size()
	}

func _update_facing() -> void:
	if sprite == null:
		return
	if absf(velocity.x) < 1.0:
		return
	# Si el sprite original mira a la izquierda, invertir cuando se mueve a la derecha.
	if sprite_faces_right_by_default:
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.flip_h = velocity.x > 0.0
