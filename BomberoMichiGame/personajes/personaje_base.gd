extends CharacterBody2D

# MOVIMIENTO GENERAL
@export var speed: float = 400.0
@export var screen_margin: int = 8
@export var clamp_to_viewport := true

# --- Vida / Knockback (from HEAD) ---
# Salud (por defecto 5 -> personaje principal)
# CAMBIADO A FLOAT para soportar daño de 0.5 de las bolas de minions
@export var vida_maxima: float = 5.0
var vida_actual: float = 0.0
var vivo: bool = true

# Knockback settings: al tocar fuego empujar al personaje fuera y aplicar daño
@export var knockback_duration: float = 0.12
@export var knockback_strength: float = 700.0
@export var penetration_push: float = 8.0 # empuje inmediato para evitar quedar solapado
var knockback_remaining: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

# Señales
signal vida_actualizada(nueva_vida)
signal personaje_muerto

# --- Dash (from main) ---
@export var dash_speed: float = 1200.0  # Velocidad del dash
@export var dash_duration: float = 0.25  # Duración del dash en segundos
@export var dash_cooldown: float = 0.5  # Tiempo de espera entre dashes

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

# Referencias para animación (from main)
var last_direction = Vector2.ZERO
var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	# Inicializar vida según la export var (puedes cambiarla en cada escena)
	vida_actual = vida_maxima
	print("🔍 DEBUG personaje_base - Inicializando vida:")
	print("   - vida_maxima:", vida_maxima)
	print("   - vida_actual:", vida_actual)
	print("   - Personaje:", name)
	emit_signal("vida_actualizada", vida_actual)

	# Si el nodo hijo 'Hitbox' existe, conecta su señal para detectar areas
	if has_node("Hitbox"):
		var hb = $Hitbox
		var cb = Callable(self, "_on_Hitbox_area_entered")
		if not hb.is_connected("area_entered", cb):
			hb.connect("area_entered", cb)
	
	# Intentar obtener el AnimatedSprite2D (puede estar en el personaje hijo)
	animated_sprite = get_node_or_null("AnimatedSprite")
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		# Buscar en los hijos por si tiene un nombre diferente
		for child in get_children():
			if child is AnimatedSprite2D:
				animated_sprite = child
				break
	
	if not animated_sprite:
		print("Advertencia: No se encontró AnimatedSprite2D en ", name)
	else:
		if animated_sprite.sprite_frames:
			print("AnimatedSprite2D encontrado! Animaciones disponibles: ", animated_sprite.sprite_frames.get_animation_names())
		else:
			print("AnimatedSprite2D encontrado pero sin sprite_frames en ", name)
		# Iniciar en idle frontal si existe
		_play_idle_animation()

func mover_personaje(delta):
	# Si el personaje está muerto, no moverse
	if not vivo:
		velocity = Vector2.ZERO
		return

	# Si hay un knockback activo, aplicarlo en prioridad sobre el input
	if knockback_remaining > 0.0:
		knockback_remaining -= delta
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_strength * delta)
		move_and_slide()
		return

	# Si está haciendo dash, manejar el dash por frame
	if is_dashing:
		_handle_dash(delta)
		return

	# Movimiento normal y lectura de input
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	
	# Debug para diagonal arriba-izquierda
	if input_vector.x < 0 and input_vector.y < 0:
		print_debug("⬉ Movimiento diagonal arriba-izquierda detectado")
		print_debug("  Input:", input_vector, "Speed:", speed)
		print_debug("  Velocity ANTES:", velocity)
		print_debug("  Position ANTES:", global_position)
	
	move_and_slide()
	
	# Debug DESPUÉS del move_and_slide
	if input_vector.x < 0 and input_vector.y < 0:
		print_debug("  Velocity DESPUÉS:", velocity)
		print_debug("  Position DESPUÉS:", global_position)
		print_debug("  is_on_wall():", is_on_wall())
		print_debug("  is_on_floor():", is_on_floor())
		print_debug("  is_on_ceiling():", is_on_ceiling())

	# Actualizar animaciones basadas en el input (from main)
	_update_animation(input_vector)

	# Mantener en viewport si se quiere
	keep_in_viewport()

# --- Vida ---
func recibir_dano(cantidad: float):
	if not vivo:
		return
	vida_actual = max(0.0, vida_actual - cantidad)
	emit_signal("vida_actualizada", vida_actual)
	print(self.name, " - Daño recibido:", cantidad, " Vida:", vida_actual, "/", vida_maxima)
	if vida_actual <= 0.0:
		_vencer()

func curar(cantidad: float):
	# Permitir curar si estaba vivo; si quieres que un pickup reviva, elimina la comprobación
	if not vivo:
		# Si quieres permitir curar desde 0 para revivir, comenta la siguiente línea
		return
	vida_actual = min(vida_maxima, vida_actual + cantidad)
	emit_signal("vida_actualizada", vida_actual)
	print(self.name, " - Curado. Vida:", vida_actual)

func _vencer():
	vivo = false
	emit_signal("personaje_muerto")
	print(self.name, " - Ha muerto. Movilidad desactivada.")
	# Usar set_deferred para evitar modificar colisiones durante physics query
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	# Si es el personaje principal, mostrar pantalla de Game Over
	if is_in_group("player_main"):
		_show_death_screen()

# --- Detección por Hitbox ---
func _on_Hitbox_area_entered(area):
	# DEBUG: Imprimir TODAS las colisiones con el Hitbox
	print("🎯 HITBOX COLLISION DETECTED:")
	print("   - area:", area.name)
	print("   - area parent:", area.get_parent().name if area.get_parent() else "null")
	print("   - area groups:", area.get_groups())
	print("   - is player_main?:", is_in_group("player_main"))
	
	# SOLO procesar fuego/pickups si este personaje es el personaje principal
	if not is_in_group("player_main"):
		print("   ❌ NO ES PLAYER_MAIN, ignorando colisión")
		return

	# Daño por fuego (grupo 'fuego')
	if area.is_in_group("fuego"):
		recibir_dano(1.0)
		var dir = (global_position - area.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		global_position += dir * penetration_push
		knockback_velocity = dir * knockback_strength
		knockback_remaining = knockback_duration
		print(self.name, " - Knockback aplicado por fuego, dir:", dir, "vel:", knockback_velocity)
		return

	# Daño por ataque de minion (grupo 'ataque_minion')
	if area.is_in_group("ataque_minion"):
		# Si el área tiene una propiedad 'damage', usarla; si no, usar 1
		var damage_amount = 1.0
		if area.has_method("get") and area.get("damage") != null:
			damage_amount = area.get("damage")
			print(self.name, " - 🔥 Golpeado por ataque de minion! Daño:", damage_amount)
		else:
			print(self.name, " - Golpeado por minion! Daño: 1")
		
		recibir_dano(damage_amount)
		var dir = (global_position - area.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		knockback_velocity = dir * knockback_strength
		knockback_remaining = knockback_duration
		return

	# Daño por ataque de jefe (grupo 'ataque_jefe')
	if area.is_in_group("ataque_jefe"):
		# Si el área tiene una propiedad 'damage', usarla; si no, usar 1
		var damage_amount = 1.0
		if area.has_method("get") and area.get("damage") != null:
			damage_amount = area.get("damage")
			print(self.name, " - 💥 Golpeado por ataque de jefe! Daño:", damage_amount)
		else:
			print(self.name, " - Golpeado por jefe! Daño: 1")
		
		recibir_dano(damage_amount)
		var dir = (global_position - area.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		knockback_velocity = dir * knockback_strength * 1.5  # Jefe empuja más fuerte
		knockback_remaining = knockback_duration
		return

	# Si el area es 'ataque_enemigo' (genérico, si lo usáis)
	if area.is_in_group("ataque_enemigo"):
		recibir_dano(1.0)
		return

	# Pickup de vida (tanques de oxígeno)
	if area.is_in_group("pickup_vida"):
		# Solo recoger si la vida no está al máximo
		if vida_actual < vida_maxima:
			curar(1.0)
			area.queue_free()
			print(self.name, " - Tanque de oxígeno recogido. Vida: ", vida_actual, "/", vida_maxima)
		else:
			print(self.name, " - Vida al máximo, no se puede recoger el tanque")
		return

# --- Dash functions (from main) ---
func _start_dash(direction: Vector2) -> void:
	"""Inicia el dash en la dirección especificada (implementación base)."""
	if not can_dash:
		return
	if direction == Vector2.ZERO:
		return
	is_dashing = true
	can_dash = false
	dash_direction = direction.normalized()
	dash_timer = dash_duration
	print_debug("[base] _start_dash called. direction:", dash_direction, "dash_timer:", dash_timer, "dash_speed:", dash_speed)

func _handle_dash(delta) -> void:
	"""Maneja el movimiento durante el dash"""
	dash_timer -= delta

	if dash_timer <= 0:
		# Terminar el dash
		is_dashing = false
		velocity = Vector2.ZERO

		# Iniciar cooldown
		can_dash = false
		# esperar el cooldown (asíncrono)
		await get_tree().create_timer(dash_cooldown).timeout
		can_dash = true
	else:
		# Mantener la velocidad del dash
		velocity = dash_direction * dash_speed
		move_and_slide()

# --- Mantener en viewport ---
func keep_in_viewport(margin := screen_margin) -> void:
	if not clamp_to_viewport:
		return

	var vp = get_viewport()
	if vp == null:
		return

	var cam := vp.get_camera_2d()
	if cam:
		var vp_size = vp.get_visible_rect().size
		var world_size = vp_size * cam.zoom
		var world_pos = cam.global_position - world_size * 0.5
		var min_x_cam = world_pos.x + margin
		var min_y_cam = world_pos.y + margin
		var max_x_cam = world_pos.x + world_size.x - margin
		var max_y_cam = world_pos.y + world_size.y - margin
		
		# Clampar y asignar todo de una vez
		var clamped_pos_cam = Vector2(
			clamp(global_position.x, min_x_cam, max_x_cam),
			clamp(global_position.y, min_y_cam, max_y_cam)
		)
		global_position = clamped_pos_cam
		return

	# Fallback a viewport rect
	var rect = vp.get_visible_rect()
	var min_x = rect.position.x + screen_margin
	var min_y = rect.position.y + screen_margin
	var max_x = rect.position.x + rect.size.x - screen_margin
	var max_y = rect.position.y + rect.size.y - screen_margin
	
	# Clampar y asignar todo de una vez
	var clamped_pos_rect = Vector2(
		clamp(global_position.x, min_x, max_x),
		clamp(global_position.y, min_y, max_y)
	)
	global_position = clamped_pos_rect

func _update_animation(input_vector: Vector2):
	"""Selecciona animación según la dirección (8 direcciones con fallbacks)"""
	if not animated_sprite:
		return

	# Si no hay movimiento, reproducir animación idle frontal si existe
	if input_vector.length() == 0:
		_play_idle_animation()
		return

	# Guardar la última dirección
	last_direction = input_vector

	var angle = input_vector.angle()
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360

	var candidates: Array[String] = []

	# 0° = derecha, 90° = abajo, 180° = izquierda, 270° = arriba
	if degrees >= 337.5 or degrees < 22.5:
		# Derecha
		candidates = [
			"move_right", "move-right",  # nombres alternativos
			"lat_inf_der", "lat_sup_der",  # fallbacks diagonales si no hay derecha pura
			"move_down", "move_up"  # último recurso, que algo se mueva
		]
	elif degrees >= 22.5 and degrees < 67.5:
		# Diagonal inferior derecha
		candidates = [
			"lat_inf_der", "move_right", "move-right", "move_down"
		]
	elif degrees >= 67.5 and degrees < 112.5:
		# Abajo
		candidates = [
			"move_down", "lat_inf_der", "lat_inf_izq", "idle_frente", "idl_frente", "lat_frente"
		]
	elif degrees >= 112.5 and degrees < 157.5:
		# Diagonal inferior izquierda
		candidates = [
			"lat_inf_izq", "move_left", "move-left", "move_down"
		]
	elif degrees >= 157.5 and degrees < 202.5:
		# Izquierda
		candidates = [
			"move_left", "move-left", "lat_inf_izq", "lat_sup_izq", "lat_frente"
		]
	elif degrees >= 202.5 and degrees < 247.5:
		# Diagonal superior izquierda
		candidates = [
			"lat_sup_izq", "move_left", "move-left", "move_up"
		]
	elif degrees >= 247.5 and degrees < 292.5:
		# Arriba
		candidates = [
			"move_up", "lat_sup_der", "lat_sup_izq", "idle_up", "atras"
		]
	elif degrees >= 292.5 and degrees < 337.5:
		# Diagonal superior derecha
		candidates = [
			"lat_sup_der", "move_right", "move-right", "move_up"
		]

	_play_first_available(candidates)

func _play_idle_animation():
	"""Reproduce la animación idle frontal si existe; si no, detiene la animación."""
	if not animated_sprite:
		return

	# Intentar animaciones de idle conocidas
	if animated_sprite.sprite_frames:
		var played_before := animated_sprite.animation
		_play_first_available(["idl_frente", "idle_frente", "idle"])  # prioriza tu 'idl_frente'
		# Si ninguna idle existe, detener para mantener el último frame
		if animated_sprite.animation == played_before and animated_sprite.is_playing():
			animated_sprite.stop()

func _play_animation(anim_name: String):
	"""Reproduce una animación si existe"""
	if not animated_sprite:
		return
	
	if not animated_sprite.sprite_frames:
		return
	
	# Verificar si la animación existe
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	else:
		print("Advertencia: Animación '", anim_name, "' no encontrada")

func _play_first_available(names: Array[String]):
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	for n in names:
		if animated_sprite.sprite_frames.has_animation(n):
			if animated_sprite.animation != n:
				animated_sprite.play(n)
			return
	# Si no encontró ninguna, loggear para depurar
	print("No se encontró ninguna animación en la lista: ", names)

func _show_death_screen():
	"""Muestra la pantalla de Game Over cuando el personaje muere"""
	print("Mostrando pantalla de Game Over...")
	# Pausar el juego
	get_tree().paused = true
	# Cargar la escena de muerte
	var death_scene = load("res://Scenes/UI/deathEscene.tscn")
	if death_scene:
		var death_instance = death_scene.instantiate()
		# Asegurarse de que el menú de muerte no esté pausado (configurar ANTES de agregar)
		death_instance.process_mode = Node.PROCESS_MODE_ALWAYS
		# Agregar a la escena raíz para que aparezca sobre todo
		get_tree().root.add_child(death_instance)
		# Configurar todos los hijos para que también funcionen durante la pausa
		_set_process_mode_recursive(death_instance, Node.PROCESS_MODE_ALWAYS)
	else:
		print("Error: No se pudo cargar deathEscene.tscn")

func _set_process_mode_recursive(node: Node, mode: Node.ProcessMode):
	"""Configura el process_mode recursivamente para todos los nodos hijos"""
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)
