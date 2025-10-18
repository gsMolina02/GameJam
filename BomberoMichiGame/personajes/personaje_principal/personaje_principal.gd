extends "res://personajes/personaje_base.gd"
class_name Bomber


# Propiedades exportadas
@export var gravity = 100
@export var axe_damage = 2
@export var parry_window = 0.2  # Ventana de tiempo para parry
@export var attack_cooldown_time = 0.2
@export var parry_cooldown_time = 0.3

# Estados del hacha
enum AxeState {
	IDLE,
	ATTACKING,
	PARRYING,
	COOLDOWN
}

# Variables de estado
var current_axe_state = AxeState.IDLE
var parry_timer = 0.0
var can_attack = true
var hose_charge = 100.0  # Carga de la manguera (0-100%)

# Referencias a nodos (guardadas con get_node_or_null para evitar errores en escenas de prueba)
@onready var axe_hitbox = get_node_or_null("Axe/AxeHitbox")
@onready var axe_sprite = get_node_or_null("Axe")
@onready var attack_cooldown_timer = get_node_or_null("AttackCooldownTimer")
@onready var animation_player = get_node_or_null("AnimationPlayer")  # Para animaciones
@onready var character_sprite = get_node_or_null("Sprite2D")  # Sprite del bombero para detectar dirección

# Señales
signal hose_recharged(new_charge)
signal extinguisher_box_broken
signal parry_successful
signal attack_performed

@export var min_x := -1000.0
@export var max_x := 1000.0
@export var min_y := -1000.0
@export var max_y := 1000.0
@export var enforce_bounds := false # set true to enable min/max clamping

func _ready():
	# Configurar timer de cooldown
	if not attack_cooldown_timer:
		attack_cooldown_timer = Timer.new()
		attack_cooldown_timer.one_shot = true
		add_child(attack_cooldown_timer)
	if attack_cooldown_timer:
		attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)

	# Configurar hitbox del hacha
	if axe_hitbox:
		axe_hitbox.monitoring = false
		if axe_hitbox.has_signal("body_entered"):
			axe_hitbox.body_entered.connect(_on_axe_hit)
		if axe_hitbox.has_signal("area_entered"):
			axe_hitbox.area_entered.connect(_on_axe_area_hit)

	# Asegurarse de que el hacha esté en posición inicial
	if axe_sprite:
		axe_sprite.rotation_degrees = 0

	# Desactivar clamp al viewport para el jugador (una sola vez)
	clamp_to_viewport = false


func _physics_process(delta):
	# Movimiento estándar
	mover_personaje(delta)

	# Actualizar timer de parry
	if current_axe_state == AxeState.PARRYING:
		parry_timer -= delta
		if parry_timer <= 0:
			current_axe_state = AxeState.IDLE

	# Input de acciones
	_handle_input()

	# Limitar posición dentro del campo definido (se puede desactivar con enforce_bounds)
	var x = global_position.x
	var y = global_position.y
	if enforce_bounds:
		var minx = (min_x if min_x != null else -1000.0)
		var maxx = (max_x if max_x != null else 1000.0)
		var miny = (min_y if min_y != null else -1000.0)
		var maxy = (max_y if max_y != null else 1000.0)
		x = clamp(global_position.x, float(minx), float(maxx))
		y = clamp(global_position.y, float(miny), float(maxy))

	# Debug: imprimir cuando el jugador intenta moverse horizontalmente
	if abs(velocity.x) > 0:
		if enforce_bounds:
			print_debug("Player attempt move -> pos:", global_position, "vel.x:", velocity.x, "clamped_x:", x, "bounds_enabled")
		else:
			print_debug("Player attempt move -> pos:", global_position, "vel.x:", velocity.x, "clamped_x:", x, "(bounds disabled)")

	global_position = Vector2(x, y)

	# Girar el sprite horizontalmente según la dirección
	if character_sprite:
		if velocity.x < 0:
			character_sprite.scale.x = -1  # Mirar a la izquierda
		elif velocity.x > 0:
			character_sprite.scale.x = 1   # Mirar a la derecha

	# adicionalmente asegurar que el personaje no salga del viewport
	# (no-op porque clamp_to_viewport está desactivado para el jugador)
	# keep_in_viewport()


func _handle_input():
	# 3.6.1 - Sistema de ataque con hacha
	if Input.is_action_just_pressed("attack"):
		attack()
	
	# 3.6.2 - Sistema de parry
	elif Input.is_action_just_pressed("parry"):
		parry()

	# Dash: detectar tecla de dash (acción 'dash' o tecla espacio)
	# Se ejecuta aquí para capturar el evento y delegar al mover_personaje
	# Detectar dash: preferir la acción 'dash', fallback a tecla SPACE
	var dash_pressed = false
	if Input.is_action_just_pressed("dash"):
		dash_pressed = true
	elif Input.is_key_pressed(Key.SPACE):
		dash_pressed = true

	if dash_pressed and can_dash:
		var iv = Input.get_vector("left", "right", "up", "down")
		print_debug("dash input detected, move vector:", iv, "can_dash:", can_dash)
		if iv.length() > 0:
			_start_dash(iv)


func mover_personaje(delta):
	# Si está haciendo dash, manejar el movimiento del dash
	if is_dashing:
		_handle_dash(delta)
		return

	# Usar la implementación base para movimiento normal
	.mover_personaje(delta)


func _start_dash(direction: Vector2):
	"""Inicia el dash en la dirección especificada"""
	if not can_dash:
		return
	is_dashing = true
	can_dash = false
	dash_direction = direction.normalized()
	dash_timer = dash_duration


func _handle_dash(delta):
	"""Maneja el movimiento durante el dash"""
	dash_timer -= delta
	if dash_timer <= 0:
		# Terminar el dash
		is_dashing = false
		velocity = Vector2.ZERO
		# iniciar cooldown antes de permitir otro dash
		await get_tree().create_timer(dash_cooldown).timeout
		can_dash = true
	else:
		velocity = dash_direction * dash_speed
		move_and_slide()

# ============================================
# 3.6.1 - SISTEMA DE ATAQUE CON HACHA
# ============================================
func attack():
	if can_attack and current_axe_state == AxeState.IDLE:
		current_axe_state = AxeState.ATTACKING
		can_attack = false
		
		# Activar hitbox del hacha
		if axe_hitbox:
			axe_hitbox.monitoring = true
		
		# Reproducir animación de ataque
		if animation_player and animation_player.has_animation("axe_attack"):
			animation_player.play("axe_attack")
		else:
			# Si no hay animación, animar manualmente el hacha
			_animate_axe_swing()
		
		# Emitir señal
		emit_signal("attack_performed")
		
		# Realizar el ataque después de un breve delay (para sincronizar con animación)
		await get_tree().create_timer(0.1).timeout
		_perform_axe_attack()
		
		# Desactivar hitbox y cooldown
		await get_tree().create_timer(0.2).timeout
		if axe_hitbox:
			axe_hitbox.monitoring = false
		
		# Resetear posición del hacha
		_reset_axe_position()
		
		attack_cooldown_timer.start(attack_cooldown_time)

func _animate_axe_swing():
	"""Anima el hacha girándola horizontalmente"""
	if not axe_sprite:
		print("ERROR: No se encontró el sprite del hacha!")
		return
	
	# Crear un tween para animar la rotación
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Determinar dirección del swing según hacia dónde mira el personaje
	var direction = 1
	if character_sprite and character_sprite.flip_h:
		direction = -1
	
	# Animación del swing: de vertical a horizontal
	tween.tween_property(axe_sprite, "rotation_degrees", 90 * direction, 0.15)
	tween.tween_property(axe_sprite, "rotation_degrees", 0, 0.15)

func _reset_axe_position():
	"""Resetea la posición y rotación del hacha"""
	if axe_sprite:
		axe_sprite.rotation_degrees = 0

# 3.6.4 - Ataque frontal
func _perform_axe_attack():
	if not axe_hitbox:
		return
	# Obtener todos los cuerpos en el área de ataque
	# Si el Area2D está con monitoring desactivado, activarlo temporalmente para poder leer overlaps
	var was_monitoring = true
	if not axe_hitbox.monitoring:
		was_monitoring = false
		axe_hitbox.monitoring = true
		# Esperar un frame de física para que el motor actualice las colisiones
		await get_tree().process_frame

	var overlapping_bodies = axe_hitbox.get_overlapping_bodies()
	var overlapping_areas = axe_hitbox.get_overlapping_areas()

	# Restaurar el estado de monitoring si estaba desactivado
	if not was_monitoring:
		axe_hitbox.monitoring = false
	
	# Procesar cuerpos (enemigos, cajas físicas)
	for body in overlapping_bodies:
		_process_attack_target(body)
	
	# Procesar áreas (hitboxes de enemigos)
	for area in overlapping_areas:
		if area.get_parent():
			_process_attack_target(area.get_parent())

func _process_attack_target(target):
	# 3.6.3 - Romper cajas de extintor
	if target.is_in_group("ExtinguisherBox"):
		_break_extinguisher_box(target)
	
	# Atacar enemigos
	elif target.has_method("take_damage"):
		# Ataque frontal con daño
		target.take_damage(axe_damage)
	
	# Otros objetos rompibles
	elif target.has_method("break_object"):
		target.break_object()

# ============================================
# 3.6.2 - SISTEMA DE PARRY
# ============================================
func parry():
	if can_attack and current_axe_state == AxeState.IDLE:
		current_axe_state = AxeState.PARRYING
		parry_timer = parry_window
		can_attack = false
		
		# Reproducir animación de parry
		if animation_player and animation_player.has_animation("axe_parry"):
			animation_player.play("axe_parry")
		
		# Activar hitbox brevemente para detectar ataques
		if axe_hitbox:
			axe_hitbox.monitoring = true
		
		attack_cooldown_timer.start(parry_cooldown_time)

func attempt_parry(incoming_attack):
	"""Intenta hacer parry de un ataque entrante"""
	if current_axe_state == AxeState.PARRYING:
		# Parry exitoso
		emit_signal("parry_successful")
		
		# Reflejar el ataque si es posible
		if incoming_attack.has_method("reflect"):
			incoming_attack.reflect()
		elif incoming_attack.has_method("cancel"):
			incoming_attack.cancel()
		
		# Efectos visuales/sonoros aquí
		_play_parry_effect()
		
		return true
	return false

func _play_parry_effect():
	# Aquí puedes añadir efectos de partículas, sonido, etc.
	print("¡Parry exitoso!")

# ============================================
# 3.6.3 - SISTEMA DE CAJAS DE EXTINTOR
# ============================================
func _break_extinguisher_box(box):
	"""Rompe una caja de extintor y recarga la manguera en 25%"""
	
	# Recargar manguera
	var old_charge = hose_charge
	hose_charge = min(hose_charge + 25.0, 100.0)
	var _actual_recharge = hose_charge - old_charge
	
	# Emitir señales
	emit_signal("hose_recharged", hose_charge)
	emit_signal("extinguisher_box_broken")
	
	# Reproducir efectos de ruptura
	_play_box_break_effect(box)
	
	# Destruir la caja
	if box.has_method("break_with_effect"):
		box.break_with_effect()
	else:
		box.queue_free()

func _play_box_break_effect(_box):
	# Efectos visuales y sonoros al romper la caja (implementar si se desea)
	pass

# ============================================
# UTILIDADES Y CALLBACKS
# ============================================
func _on_attack_cooldown_timeout():
	can_attack = true
	if current_axe_state != AxeState.PARRYING:
		current_axe_state = AxeState.IDLE

func _on_axe_hit(body):
	"""Callback cuando el hacha colisiona con un cuerpo"""
	if current_axe_state == AxeState.ATTACKING:
		_process_attack_target(body)

func _on_axe_area_hit(area):
	"""Callback cuando el hacha colisiona con un área"""
	if current_axe_state == AxeState.ATTACKING:
		if area.get_parent():
			_process_attack_target(area.get_parent())

# Getters
func is_parrying() -> bool:
	return current_axe_state == AxeState.PARRYING

func is_attacking() -> bool:
	return current_axe_state == AxeState.ATTACKING

func get_hose_charge() -> float:
	return hose_charge

func can_use_hose() -> bool:
	return hose_charge > 0

# Setters
func set_hose_charge(value: float):
	hose_charge = clamp(value, 0.0, 100.0)
	emit_signal("hose_recharged", hose_charge)

func reduce_hose_charge(amount: float):
	"""Reduce la carga de la manguera al usarla"""
	set_hose_charge(hose_charge - amount)
	# (Merged) sprite flip handled earlier via `character_sprite` when available
