extends CharacterBody2D

# MOVIMIENTO GENERAL
@export var speed: float = 400.0
@export var screen_margin: int = 8
@export var clamp_to_viewport := true
@export var movement_debug_logs: bool = false

# --- Vida / Knockback (from HEAD) ---
# Salud (por defecto 5 -> personaje principal)
# CAMBIADO A FLOAT para soportar daño de 0.5 de las bolas de minions
# ACTUALIZADO A 100.0 para usar escala 0-100 (oxígeno)
@export var vida_maxima: float = 100.0
var vida_actual: float = 0.0
var vivo: bool = true
var _last_health_percentage: int = 100  # Para rastrear cambios de porcentaje

# i-frames y feedback de daño del jugador principal
@export var player_iframe_duration: float = 0.45
@export var player_hit_flash_time: float = 0.12
@export var player_hit_shake_time: float = 0.10
@export var player_hit_shake_strength: float = 4.0

var _damage_invulnerable_until_ms: int = 0
var _is_hit_feedback_playing: bool = false

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

# Estado de ataque especial (usado por personaje_principal.gd)
var is_performing_special_attack: bool = false

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
		_play_dash_roll_animation()
		_handle_dash(delta)
		return

	# Movimiento normal y lectura de input
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	
	# Debug para movimiento (opcional)
	if movement_debug_logs and input_vector.x < 0 and input_vector.y < 0:
		print_debug("⬉ Movimiento diagonal arriba-izquierda detectado")
		print_debug("  Input:", input_vector, "Speed:", speed)
		print_debug("  Velocity ANTES:", velocity)
		print_debug("  Position ANTES:", global_position)
	
	move_and_slide()
	
	# Debug DESPUÉS del move_and_slide (opcional)
	if movement_debug_logs and input_vector.x < 0 and input_vector.y < 0:
		print_debug("  Velocity DESPUÉS:", velocity)
		print_debug("  Position DESPUÉS:", global_position)
		print_debug("  is_on_wall():", is_on_wall())
		print_debug("  is_on_floor():", is_on_floor())
		print_debug("  is_on_ceiling():", is_on_ceiling())

	# Actualizar animaciones basadas en el input (from main)
	# NO actualizar si está en ataque especial (solo para personaje principal)
	var should_update_animation = true
	if is_in_group("player_main") and is_performing_special_attack:
		should_update_animation = false
	
	if should_update_animation:
		_update_animation(input_vector)

	# Mantener en viewport si se quiere
	keep_in_viewport()

# --- Vida ---
func recibir_dano(cantidad: float):
	if not vivo:
		return

	if _is_player_main() and _is_in_damage_iframes():
		return

	if _is_player_main():
		_start_damage_iframes()
		_play_player_hit_feedback()

	vida_actual = max(0.0, vida_actual - cantidad)
	emit_signal("vida_actualizada", vida_actual)
	_check_health_percentage()
	if vida_actual <= 0.0:
		_vencer()

func curar(cantidad: float):
	# Permitir curar si estaba vivo; si quieres que un pickup reviva, elimina la comprobación
	if not vivo:
		# Si quieres permitir curar desde 0 para revivir, comenta la siguiente línea
		return
	vida_actual = min(vida_maxima, vida_actual + cantidad)
	emit_signal("vida_actualizada", vida_actual)
	_check_health_percentage()

func _check_health_percentage() -> void:
	"""Muestra el porcentaje de salud solo cuando cambia de rango (25%, 50%, 75%, 100%)"""
	var health_percentage: int = int((vida_actual / vida_maxima) * 100)
	
	# Determinar rango
	var current_range: int
	if health_percentage <= 25:
		current_range = 25
	elif health_percentage <= 50:
		current_range = 50
	elif health_percentage <= 75:
		current_range = 75
	else:
		current_range = 100
	
	# Solo mostrar si cambió el rango
	if current_range != _last_health_percentage:
		_last_health_percentage = current_range
		print("❤️  ", self.name, " - Salud: ", current_range, "%")

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

func _is_player_main() -> bool:
	return is_in_group("player_main")

func _is_in_damage_iframes() -> bool:
	return Time.get_ticks_msec() < _damage_invulnerable_until_ms

func _start_damage_iframes() -> void:
	var safe_duration: float = max(player_iframe_duration, 0.0)
	_damage_invulnerable_until_ms = Time.get_ticks_msec() + int(safe_duration * 1000.0)

func _play_player_hit_feedback() -> void:
	if _is_hit_feedback_playing:
		return

	_is_hit_feedback_playing = true

	var hit_sprite: AnimatedSprite2D = animated_sprite
	if hit_sprite == null:
		hit_sprite = get_node_or_null("AnimatedSprite") as AnimatedSprite2D

	if hit_sprite:
		hit_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(hit_sprite, "modulate", Color(1, 1, 1, 1), max(player_hit_flash_time, 0.03))

	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		var original_offset: Vector2 = cam.offset
		var shake_until: int = Time.get_ticks_msec() + int(max(player_hit_shake_time, 0.03) * 1000.0)
		while Time.get_ticks_msec() < shake_until:
			cam.offset = original_offset + Vector2(
				randf_range(-player_hit_shake_strength, player_hit_shake_strength),
				randf_range(-player_hit_shake_strength, player_hit_shake_strength)
			)
			await get_tree().process_frame
		cam.offset = original_offset

	_is_hit_feedback_playing = false

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
		# Restar -10 de oxígeno (daño a la barra de vida que representa oxígeno)
		var damage_amount = 10.0
		print(self.name, " - 🔥 Golpeado por ataque de minion! Oxígeno perdido:", damage_amount)
		recibir_dano(damage_amount)
		var dir = (global_position - area.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		knockback_velocity = dir * knockback_strength
		knockback_remaining = knockback_duration
		return

	# Daño por ataque de jefe (grupo 'ataque_jefe')
	if area.is_in_group("ataque_jefe"):
		# Restar -10 de oxígeno (daño a la barra de vida que representa oxígeno)
		var damage_amount = 10.0
		print(self.name, " - 💥 Golpeado por ataque de jefe! Oxígeno perdido:", damage_amount)
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
			curar(25.0)  # Recupera +25% de oxígeno
			area.queue_free()
			print(self.name, " - Tanque de oxígeno recogido (+25). Oxígeno: ", vida_actual, "/", vida_maxima)
		else:
			print(self.name, " - Oxígeno al máximo, no se puede recoger el tanque")
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
		# Derecha (frontal)
		candidates = [
			"AxeWalkinFrontDer", "AxelWalkinFrontDer",
			"AxeWalkinFront", "AxelWalkinFront"
		]
	elif degrees >= 22.5 and degrees < 67.5:
		# Diagonal inferior derecha (frontal)
		candidates = [
			"AxeWalkinFrontDer", "AxelWalkinFrontDer",
			"AxeWalkinFront", "AxelWalkinFront"
		]
	elif degrees >= 67.5 and degrees < 112.5:
		# Abajo (frontal)
		candidates = [
			"AxeWalkinFront", "AxelWalkinFront",
			"AxeWalkinFrontDer", "AxelWalkinFrontDer",
			"AxeWalkinFrontIzq", "AxelWalkinFrontIzq"
		]
	elif degrees >= 112.5 and degrees < 157.5:
		# Diagonal inferior izquierda (frontal)
		candidates = [
			"AxeWalkinFrontIzq", "AxelWalkinFrontIzq",
			"AxeWalkinFront", "AxelWalkinFront"
		]
	elif degrees >= 157.5 and degrees < 202.5:
		# Izquierda (frontal)
		candidates = [
			"AxeWalkinFrontIzq", "AxelWalkinFrontIzq",
			"AxeWalkinFront", "AxelWalkinFront"
		]
	elif degrees >= 202.5 and degrees < 247.5:
		# Diagonal superior izquierda
		candidates = [
			"AxeWalkBackIzq", "AxelWalkBackIzq",
			"AxeWalkBack", "AxelWalkBack"
		]
	elif degrees >= 247.5 and degrees < 292.5:
		# Arriba
		candidates = [
			"AxeWalkBack", "AxelWalkBack",
			"AxeWalkBackDer", "AxelWalkBackDer",
			"AxeWalkBackIzq", "AxelWalkBackIzq"
		]
	elif degrees >= 292.5 and degrees < 337.5:
		# Diagonal superior derecha
		candidates = [
			"AxeWalkBackDer", "AxelWalkBackDer",
			"AxeWalkBack", "AxelWalkBack"
		]

	_play_first_available(candidates)

func _play_idle_animation():
	"""Reproduce la animación idle según la última dirección; con fallbacks."""
	if not animated_sprite:
		return

	# Priorizar idle mirando a izquierda/derecha según la última dirección.
	# Mantiene aliases para escenas antiguas.
	if animated_sprite.sprite_frames:
		var idle_candidates: Array[String] = []
		if last_direction.x < 0:
			idle_candidates = ["AxelIdleFrIzq", "AxeIdleFrIzq", "AxeIdl", "AxelIdl"]
		else:
			idle_candidates = ["AxelIdleFrDer", "AxeIdleFrDer", "AxeIdl", "AxelIdl"]
		var played_idle := _play_first_available(idle_candidates)
		# Si ninguna idle existe, detener para mantener el último frame
		if not played_idle and animated_sprite.is_playing():
			animated_sprite.stop()

func _play_dash_roll_animation():
	"""Reproduce roll según dirección del dash."""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	var dir := dash_direction
	if dir == Vector2.ZERO:
		dir = last_direction
	if dir == Vector2.ZERO:
		_play_first_available(["AxeRollFrontDer", "AxelRollFrontDer"])
		return

	if dir.y < -0.35:
		if dir.x < -0.2:
			_play_first_available(["AxeRollBackIzq", "AxelRollBackIzq"])
		elif dir.x > 0.2:
			_play_first_available(["AxeRollBackDer", "AxelRollBackDer"])
		else:
			_play_first_available(["AxeRollBackDer", "AxelRollBackDer", "AxeRollBackIzq", "AxelRollBackIzq"])
	else:
		if dir.x < 0:
			_play_first_available(["AxeRollFrontIzq", "AxelRollFrontIzq"])
		else:
			_play_first_available(["AxeRollFrontDer", "AxelRollFrontDer"])

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

func _play_first_available(names: Array[String]) -> bool:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return false
	for n in names:
		if animated_sprite.sprite_frames.has_animation(n):
			if animated_sprite.animation != n:
				animated_sprite.play(n)
			return true
	# Si no encontró ninguna, loggear para depurar
	print("No se encontró ninguna animación en la lista: ", names)
	return false



func _show_death_screen():
	print("Mostrando video de Game Over localizado...")

	get_tree().paused = true

	var video_layer = CanvasLayer.new()
	video_layer.layer = 128
	video_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(video_layer)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_layer.add_child(bg)

	var video_player = VideoStreamPlayer.new()

	# --- NUEVO: Selección de video según el idioma ---
	# IMPORTANTE: Reemplaza "GlobalManager" por el nombre exacto que
	# le pusiste a tu script de idiomas en Project Settings > Autoload
	var idioma_actual = Localization.language
	var ruta_video = "res://Assets/DeathEnd/deahtScreen.ogv" # Inglés por defecto ("en")

	if idioma_actual == "es":
		ruta_video = "res://Assets/DeathEnd/deahtScreenES.ogv"
	elif idioma_actual == "pt":
		ruta_video = "res://Assets/DeathEnd/deahtScreenBR.ogv"

	video_player.stream = load(ruta_video)
	# -------------------------------------------------

	video_player.expand = true
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Valores iniciales para el Fade In
	video_player.volume_db = -40.0
	video_player.modulate.a = 0.0

	video_layer.add_child(video_player)
	video_player.play()

	# Tween para la transición suave
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween.tween_property(video_player, "volume_db", -10.0, 1.5)
	tween.parallel().tween_property(video_player, "modulate:a", 1.0, 1.5)

	# Reinicio al terminar el video
	video_player.finished.connect(func():
		get_tree().paused = false
		video_layer.queue_free()
		get_tree().reload_current_scene()
	)

func _set_process_mode_recursive(node: Node, mode: Node.ProcessMode):
	"""Configura el process_mode recursivamente para todos los nodos hijos"""
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)
