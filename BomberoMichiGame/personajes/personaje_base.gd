extends CharacterBody2D

# MOVIMIENTO GENERAL
@export var speed: float = 400.0
@export var screen_margin: int = 8
@export var clamp_to_viewport := true

# --- Vida / Knockback (from HEAD) ---
# Salud (por defecto 1 -> ideal para minions)
@export var vida_maxima: int = 1
var vida_actual: int = 0
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

func _ready() -> void:
	# Inicializar vida según la export var (puedes cambiarla en cada escena)
	vida_actual = vida_maxima
	emit_signal("vida_actualizada", vida_actual)

	# Si el nodo hijo 'Hitbox' existe, conecta su señal para detectar areas
	if has_node("Hitbox"):
		var hb = $Hitbox
		var cb = Callable(self, "_on_Hitbox_area_entered")
		if not hb.is_connected("area_entered", cb):
			hb.connect("area_entered", cb)

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
	move_and_slide()

	# Mantener en viewport si se quiere
	keep_in_viewport()

# --- Vida ---
func recibir_dano(cantidad: int):
	if not vivo:
		return
	vida_actual = max(0, vida_actual - cantidad)
	emit_signal("vida_actualizada", vida_actual)
	print(self.name, " - Daño recibido. Vida:", vida_actual)
	if vida_actual == 0:
		_vencer()

func curar(cantidad: int):
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
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

# --- Detección por Hitbox ---
func _on_Hitbox_area_entered(area):
	# SOLO procesar fuego/pickups si este personaje es el personaje principal
	if not is_in_group("player_main"):
		return

	# Daño por fuego (grupo 'fuego')
	if area.is_in_group("fuego"):
		recibir_dano(1)
		var dir = (global_position - area.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		global_position += dir * penetration_push
		knockback_velocity = dir * knockback_strength
		knockback_remaining = knockback_duration
		print(self.name, " - Knockback aplicado, dir:", dir, "vel:", knockback_velocity)
		return

	# Si el area es 'ataque_enemigo' (si lo usáis)
	if area.is_in_group("ataque_enemigo"):
		recibir_dano(1)
		return

	# Pickup de vida
	if area.is_in_group("pickup_vida"):
		# Si quieres que un pickup te reviva cuando estuviste a 0,
		# cambia curar() para permitir curar aunque !vivo.
		curar(1)
		area.queue_free()
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
		global_position.x = clamp(global_position.x, min_x_cam, max_x_cam)
		global_position.y = clamp(global_position.y, min_y_cam, max_y_cam)
		return

	# Fallback a viewport rect
	var rect = vp.get_visible_rect()
	var x = clamp(global_position.x, rect.position.x + margin, rect.position.x + rect.size.x - margin)
	var y = clamp(global_position.y, rect.position.y + margin, rect.position.y + rect.size.y - margin)
	global_position = Vector2(x, y)
