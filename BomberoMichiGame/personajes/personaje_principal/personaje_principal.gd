extends "res://personajes/personaje_base.gd"
class_name Bomber

# Propiedades exportadas
@export var gravity = 100
@export var axe_damage = 5
@export var parry_window = 0.4
@export var attack_cooldown_time = 0.2
@export var parry_cooldown_time = 0.1

# Propiedades de la manguera
@export var hose_range = 50  # Alcance en cuadros (tiles) - AUMENTADO
@export var tile_size = 20  # Tamaño de cada cuadro en píxeles
@export var hose_width = 40  # Ancho del chorro de agua
@export var hose_drain_rate = 10.0  # Carga consumida por segundo
@export var water_pressure = 10.0  # Daño por segundo al fuego (ajustado para apagar en 0.5s)
@export var hose_origin_offset = Vector2(50, 0)  # Punto de origen del agua
@export var hose_nozzle_offset = Vector2(130, 30)  # Punta de la manguera (boquilla)

# Estados del hacha
enum AxeState {
	IDLE,
	ATTACKING,
	PARRYING,
	COOLDOWN
}

# Enum para el arma actual
enum Weapon {
	AXE,
	HOSE
}

# Variables de estado
var current_axe_state = AxeState.IDLE
var parry_timer = 0.0
var can_attack = true
var hose_charge = 100.0
var is_using_hose = false
var current_weapon = Weapon.HOSE  # Iniciar con MANGUERA equipada
var is_dead: bool = false

# Marcador calculado para la punta de la manguera
 

# Referencias a nodos (guardadas con get_node_or_null para evitar errores en escenas de prueba)
@onready var axe_hitbox = get_node_or_null("Axe/AxeHitbox")
@onready var axe_sprite = get_node_or_null("Axe")
@onready var hose_sprite = get_node_or_null("hose")
@onready var attack_cooldown_timer = get_node_or_null("AttackCooldownTimer")
@onready var animation_player = get_node_or_null("AnimationPlayer")  # Para animaciones
@onready var character_sprite = get_node_or_null("AnimatedSprite")  # Sprite del bombero para detectar dirección

# Nodos para la manguera (guardadas con get_node_or_null para evitar errores en escenas de prueba)
@onready var hose_area = get_node_or_null("HoseArea")  # Area2D para detectar fuego
@onready var hose_raycast = get_node_or_null("HoseRaycast")  # RayCast2D para dirección
@onready var water_particles = get_node_or_null("WaterParticles")  # Partículas de agua (opcional)

# Señales
signal hose_recharged(new_charge)
signal extinguisher_box_broken
signal parry_successful
signal attack_performed
signal hose_activated
signal hose_deactivated
signal fire_extinguished(fire_node)
signal weapon_switched(new_weapon)

@export var min_x := -1000.0
@export var max_x := 1000.0
@export var min_y := -1000.0
@export var max_y := 1000.0
@export var enforce_bounds := false # set true to enable min/max clamping

func _ready():
	# Llama a la inicialización del padre (conexión Hitbox, init vida, etc.)
	super._ready()
	
	# Añadir al grupo para que HUD/etc. nos encuentre
	add_to_group("player_main")
	
	# Conectar señal de muerte para pausar el juego solo cuando vida = 0
	if not is_connected("personaje_muerto", Callable(self, "die")):
		connect("personaje_muerto", Callable(self, "die"))
	
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
		axe_hitbox.add_to_group("player_weapon")  # Identificar el hacha como arma del jugador
		# Configurar máscara de colisión para que NO detecte al jugador
		if axe_hitbox.has_method("add_collision_exception_with"):
			axe_hitbox.add_collision_exception_with(self)
		if axe_hitbox.has_signal("body_entered"):
			axe_hitbox.body_entered.connect(_on_axe_hit)
		if axe_hitbox.has_signal("area_entered"):
			axe_hitbox.area_entered.connect(_on_axe_area_hit)

	# Asegurarse de que el hacha esté en posición inicial
	if axe_sprite:
		axe_sprite.rotation_degrees = 0
	
	# Configurar sistema de manguera
	_setup_hose_system()
	
	# Actualizar visuales iniciales (manguera visible, hacha oculta)
	_update_weapon_visuals()
	print("✓ Juego iniciado con MANGUERA equipada")

	# Add to player group for collision filtering
	add_to_group("player")

	# Desactivar clamp al viewport para el jugador (una sola vez)
	clamp_to_viewport = false
	
	# Emitir valores iniciales para que el HUD se actualice
	emit_signal("hose_recharged", hose_charge)  # Emitir carga inicial de agua

func _setup_hose_system():
	"""Configura los nodos necesarios para el sistema de manguera"""
	# Asegurar que las variables tengan valores por defecto válidos
	var safe_hose_range = hose_range if hose_range != null else 50
	var safe_tile_size = tile_size if tile_size != null else 20
	var safe_hose_width = hose_width if hose_width != null else 40
	var safe_hose_nozzle_offset = hose_nozzle_offset if hose_nozzle_offset != null else Vector2(80, 0)
	
	# Si no existen los nodos, crearlos
	if not hose_area:
		hose_area = Area2D.new()
		hose_area.name = "HoseArea"
		add_child(hose_area)
		
		# Configurar la máscara de colisión para que NO detecte al jugador
		# Asumiendo que el jugador está en la capa 1 (collision_layer = 1)
		# El HoseArea debería detectar enemigos y fuego, no al jugador
		hose_area.collision_mask = 0  # Resetear máscara
		hose_area.set_collision_mask_value(2, true)  # Detectar capa 2 (enemigos/fuego)
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(safe_hose_range * safe_tile_size, safe_hose_width)
		collision.shape = shape
		collision.position = Vector2((safe_hose_range * safe_tile_size) / 2.0, 0) + safe_hose_nozzle_offset
		collision.disabled = true  # Desactivar la colisión por defecto
		hose_area.add_child(collision)
		
		hose_area.monitoring = false
	else:
		# Actualizar shape existente con nuevos valores
		if hose_area.get_child_count() > 0:
			var collision = hose_area.get_child(0)
			if collision.shape:
				collision.shape.size = Vector2(safe_hose_range * safe_tile_size, safe_hose_width)
				collision.position = Vector2((safe_hose_range * safe_tile_size) / 2.0, 0) + safe_hose_nozzle_offset
	
	if not hose_raycast:
		hose_raycast = RayCast2D.new()
		hose_raycast.name = "HoseRaycast"
		hose_raycast.position = safe_hose_nozzle_offset
		hose_raycast.target_position = Vector2(safe_hose_range * safe_tile_size, 0)
		hose_raycast.enabled = false
		add_child(hose_raycast)
	else:
		# Actualizar raycast existente
		hose_raycast.position = safe_hose_nozzle_offset
		hose_raycast.target_position = Vector2(safe_hose_range * safe_tile_size, 0)
	
	# Crear partículas de agua si no existen
	if not water_particles:
		water_particles = CPUParticles2D.new()
		water_particles.name = "WaterParticles"
		add_child(water_particles)
		
		# Configurar propiedades de las partículas
		water_particles.emitting = false
		water_particles.amount = 80
		water_particles.lifetime = 0.9
		water_particles.speed_scale = 1.0
		
		# Dirección y velocidad
		water_particles.direction = Vector2(1, 0)
		water_particles.spread = 10.0
		water_particles.initial_velocity_min = 350.0
		water_particles.initial_velocity_max = 600.0
		
		# Gravedad
		water_particles.gravity = Vector2(0, 60)
		water_particles.damping_min = 6.0
		water_particles.damping_max = 12.0
		
		# Apariencia
		water_particles.scale_amount_min = 6.0
		water_particles.scale_amount_max = 10.0
		water_particles.color = Color(0.3, 0.7, 1.0, 0.8)  # Azul agua
		
		# Emisión en rectángulo
		water_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		# Pequeño rectángulo en la boquilla
		water_particles.emission_rect_extents = Vector2(2, 4)
		
		# Posición inicial en la boquilla de la manguera
		water_particles.position = safe_hose_nozzle_offset
		water_particles.visible = true  # Visible al inicio (manguera equipada)
		
		print("Partículas de agua creadas automáticamente")
	else:
		# Actualizar configuración para mayor alcance
		water_particles.emitting = false
		water_particles.visible = true  # Visible al inicio
		water_particles.lifetime = 0.9
		water_particles.initial_velocity_min = 350.0
		water_particles.initial_velocity_max = 600.0
		water_particles.gravity = Vector2(0, 60)
		water_particles.damping_min = 6.0
		water_particles.damping_max = 12.0
		water_particles.emission_rect_extents = Vector2(2, 4)
		water_particles.position = safe_hose_nozzle_offset

func _physics_process(delta):
	# Movimiento estándar (mover_personaje en la base maneja dash internamente)
	mover_personaje(delta)
	
	# Actualizar timer de parry
	if current_axe_state == AxeState.PARRYING:
		parry_timer -= delta
		if parry_timer <= 0:
			current_axe_state = AxeState.IDLE
	
	# Actualizar sistema de manguera
	if is_using_hose:
		_update_hose(delta)
	
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
			character_sprite.flip_h = true  # Mirar a la izquierda
		elif velocity.x > 0:
			character_sprite.flip_h = false   # Mirar a la derecha

	# Actualizar posición y rotación de las armas según la dirección de movimiento
	_update_weapon_orientation()

	# adicionalmente asegurar que el personaje no salga del viewport
	# (no-op porque clamp_to_viewport está desactivado para el jugador)
	# keep_in_viewport()

func _unhandled_input(event):
	# Si el jugador está muerto, cualquier tecla reinicia la escena
	if is_dead and event is InputEventKey and event.pressed:
		get_tree().paused = false
		var err = get_tree().reload_current_scene()
		if err != OK:
			# Fallback por si falla
			var current = get_tree().get_current_scene()
			if current and current.has_method("get_scene_file_path"):
				get_tree().change_scene_to_file(current.get_scene_file_path())
		return

	# Detectar scroll del mouse para cambiar arma
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				switch_weapon()

func _handle_input():
	# Intercambiar arma con Q
	if Input.is_action_just_pressed("ui_focus_next"):  # Q por defecto
		switch_weapon()
	
	# También puedes usar una acción personalizada si la configuras
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	# Sistema de manguera (botón mantenido) - solo si está equipada
	if current_weapon == Weapon.HOSE:
		if Input.is_action_pressed("use_hose") and can_use_hose():
			if not is_using_hose:
				_activate_hose()
		elif is_using_hose:
			_deactivate_hose()
	else:
		# Si cambiamos de arma mientras usamos la manguera, desactivarla
		if is_using_hose:
			_deactivate_hose()
	
	# Sistema de ataque con hacha - solo si está equipada
	if current_weapon == Weapon.AXE:
		if Input.is_action_just_pressed("attack"):
			attack()  # El ataque ahora funciona como parry automático

	# Dash: usar Shift ('ui_shift') como en el comportamiento original
	var shift_pressed := false
	if InputMap.has_action("ui_shift"):
		shift_pressed = Input.is_action_just_pressed("ui_shift")
	else:
		# Fallback a tecla Space si no existe la acción
		shift_pressed = Input.is_key_pressed(KEY_SPACE) and not Input.is_action_pressed("attack")

	if shift_pressed and can_dash:
		# Determinar dirección de dash: preferir input vector, caer a dirección mirando
		var dir = Input.get_vector("left", "right", "up", "down")
		if dir == Vector2.ZERO:
			# Si no hay input, dash hacia donde mira el sprite
			if character_sprite:
				dir = Vector2(-1, 0) if character_sprite.flip_h else Vector2(1, 0)
			else:
				dir = Vector2(1, 0)

		# Llamar al dash implementado en la base
		_start_dash(dir)

# ============================================
# SISTEMA DE ORIENTACIÓN DE ARMAS
# ============================================

func _update_weapon_orientation():
	"""Actualiza la posición y rotación de las armas hacia la posición del mouse"""
	# Obtener la posición del mouse en el mundo
	var mouse_pos = get_global_mouse_position()
	
	# Calcular la dirección desde el personaje hacia el mouse
	var direction = (mouse_pos - global_position).normalized()
	
	# Si el mouse está muy cerca del personaje, usar dirección por defecto
	if (mouse_pos - global_position).length() < 10:
		direction = Vector2.RIGHT
	
	# Calcular el ángulo de la dirección
	var angle = direction.angle()
	
	# Actualizar orientación del hacha
	if axe_sprite:
		_orient_axe(direction, angle)
	
	# Actualizar orientación de la manguera
	if hose_sprite:
		_orient_hose(direction, angle)

func _orient_axe(direction: Vector2, angle: float):
	"""Orienta el hacha según la dirección de movimiento"""
	var base_offset = 50.0  # Distancia desde el centro del personaje
	
	# Calcular posición del hacha alrededor del personaje
	var axe_position = direction * base_offset
	
	# Ajustar la posición vertical para que no esté en el centro exacto
	axe_position.y += 10.0
	
	axe_sprite.position = axe_position
	
	# Rotar el hacha para que apunte en la dirección de movimiento
	# +90 grados porque el sprite del hacha está orientado verticalmente
	axe_sprite.rotation = angle + PI / 2

func _orient_hose(direction: Vector2, angle: float):
	"""Orienta la manguera según la dirección de movimiento"""
	var base_offset = 60.0  # Un poco más lejos que el hacha
	
	# Calcular posición de la manguera
	var hose_position = direction * base_offset
	
	# Ajustar posición vertical
	hose_position.y += 15.0
	
	hose_sprite.position = hose_position
	
	# Rotar la manguera para que apunte en la dirección de movimiento
	hose_sprite.rotation = angle
	
	# Actualizar también la dirección de las partículas de agua si están activas
	if water_particles:
		# Posicionar las partículas en la punta de la manguera
		var nozzle_offset = direction * (base_offset + 30.0)
		water_particles.position = nozzle_offset
		water_particles.direction = direction

# ============================================
# SISTEMA DE INTERCAMBIO DE ARMAS
# ============================================

func switch_weapon():
	"""Intercambia entre hacha y manguera"""
	# Desactivar manguera si está activa
	if is_using_hose:
		_deactivate_hose()
	
	# Cambiar arma
	if current_weapon == Weapon.AXE:
		current_weapon = Weapon.HOSE
		print("✓ Arma cambiada a: MANGUERA (Carga: ", hose_charge, "%)")
	else:
		current_weapon = Weapon.AXE
		print("✓ Arma cambiada a: HACHA")
	
	# Actualizar visuales
	_update_weapon_visuals()
	
	# Emitir señal
	emit_signal("weapon_switched", current_weapon)

func _update_weapon_visuals():
	"""Actualiza los visuales según el arma equipada"""
	if axe_sprite:
		axe_sprite.visible = (current_weapon == Weapon.AXE)
	
	# Mostrar/Ocultar sprite de la manguera
	if hose_sprite:
		hose_sprite.visible = (current_weapon == Weapon.HOSE)
	
	# Ocultar las partículas de agua cuando no está equipada la manguera
	if water_particles:
		if current_weapon == Weapon.HOSE:
			water_particles.visible = true
		else:
			water_particles.visible = false
			water_particles.emitting = false

# ============================================
# SISTEMA DE MANGUERA
# ============================================

func _activate_hose():
	"""Activa la manguera de agua"""
	if not can_use_hose():
		print("¡Manguera sin carga!")
		return
	
	is_using_hose = true
	emit_signal("hose_activated")
	
	# Activar área de detección Y su CollisionShape2D
	if hose_area:
		hose_area.monitoring = true
		# Activar el CollisionShape2D para que sea visible/activo
		if hose_area.get_child_count() > 0:
			var collision = hose_area.get_child(0)
			if collision is CollisionShape2D:
				collision.disabled = false
	
	# Activar raycast
	if hose_raycast:
		hose_raycast.enabled = true
	
	# Activar partículas de agua
	if water_particles:
		water_particles.emitting = true
		water_particles.visible = true
		print("Partículas activadas en posición: ", water_particles.position)
		print("Partículas emitting: ", water_particles.emitting)
		print("Partículas visible: ", water_particles.visible)
		var safe_hose_range = hose_range if hose_range != null else 50
		var safe_tile_size = tile_size if tile_size != null else 20
		print("Alcance de manguera: ", safe_hose_range * safe_tile_size, " píxeles")
	else:
		print("ERROR: WaterParticles no encontrado!")
	
	print("Manguera activada - Carga: ", hose_charge, "%")

func _deactivate_hose():
	"""Desactiva la manguera de agua"""
	is_using_hose = false
	emit_signal("hose_deactivated")
	
	# Desactivar área de detección Y su CollisionShape2D
	if hose_area:
		hose_area.monitoring = false
		# Desactivar el CollisionShape2D para que no sea visible
		if hose_area.get_child_count() > 0:
			var collision = hose_area.get_child(0)
			if collision is CollisionShape2D:
				collision.disabled = true
	
	# Desactivar raycast
	if hose_raycast:
		hose_raycast.enabled = false
	
	# Desactivar partículas de agua
	if water_particles:
		water_particles.emitting = false

func _update_hose(delta):
	"""Actualiza el sistema de manguera mientras está activa"""
	# Consumir carga de agua
	var safe_drain_rate = hose_drain_rate if hose_drain_rate != null else 10.0
	reduce_hose_charge(safe_drain_rate * delta)
	
	# Calcular daño de agua usando water_pressure
	var safe_water_pressure = water_pressure if water_pressure != null else 5.0
	var water_damage = safe_water_pressure * delta
	
	# Actualizar dirección de la manguera según hacia dónde mira el personaje
	_update_hose_direction()
	
	# Detectar y apagar fuego con el daño calculado
	_detect_and_extinguish_fire(water_damage)
	
	# Si se acabó la carga, desactivar
	if hose_charge <= 0:
		_deactivate_hose()
		print("¡Manguera vacía!")

func _update_hose_direction():
	"""Actualiza la dirección de la manguera hacia la posición del mouse"""
	# Valores seguros para evitar operaciones con null
	var safe_hose_range = hose_range if hose_range != null else 50
	var safe_tile_size = tile_size if tile_size != null else 20
	
	# Obtener la dirección hacia el mouse
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Si el mouse está muy cerca, usar dirección por defecto
	if (mouse_pos - global_position).length() < 10:
		direction = Vector2.RIGHT
	
	# Calcular el ángulo para el área de colisión
	var angle = direction.angle()
	
	# Actualizar posición y rotación del área de colisión de la manguera
	if hose_area and hose_area.get_child_count() > 0:
		var collision = hose_area.get_child(0)
		var range_distance = (safe_hose_range * safe_tile_size) / 2.0
		
		# Posicionar el área en la dirección de apuntado
		collision.position = direction * range_distance
		collision.rotation = angle
	
	# Actualizar dirección del raycast
	if hose_raycast:
		hose_raycast.target_position = direction * (safe_hose_range * safe_tile_size)
		hose_raycast.rotation = 0  # El raycast usa target_position relativo

func _detect_and_extinguish_fire(water_amount: float):
	"""Detecta y apaga el fuego en el área de la manguera"""
	if not hose_area:
		return
	
	# Obtener todas las áreas que están siendo alcanzadas por el agua
	var overlapping_areas = hose_area.get_overlapping_areas()
	var overlapping_bodies = hose_area.get_overlapping_bodies()
	
	# Procesar áreas (fuego como Area2D)
	for area in overlapping_areas:
		_try_extinguish_fire(area, water_amount)
	
	# Procesar cuerpos (fuego como cuerpo físico)
	for body in overlapping_bodies:
		_try_extinguish_fire(body, water_amount)

func _try_extinguish_fire(target, water_amount: float):
	"""Intenta apagar un fuego"""
	# IMPORTANTE: No atacar al propio jugador
	if target == self or target.is_in_group("player") or target.is_in_group("player_main"):
		return
	
	# Debug: imprimir qué está siendo detectado
	print("Manguera detectó: ", target.name, " - Grupos: ", target.get_groups() if target.has_method("get_groups") else "sin grupos")
	
	# Aplicar agua o daño a cualquier objetivo compatible (fuego, enemigos, etc.)
	if target.has_method("apply_water") or target.has_method("take_damage") or target.is_in_group("Fire") or target.has_method("extinguish"):
		# Si el objetivo acepta agua, pásale la cantidad de agua usada literalmente
		if target.has_method("apply_water"):
			print("  -> Llamando apply_water con ", water_amount)
			target.apply_water(water_amount)
		# Si recibe daño, usa el agua como daño directo: 1 agua = 1 daño
		elif target.has_method("take_damage"):
			print("  -> Llamando take_damage con ", water_amount)
			target.take_damage(water_amount)
		elif target.has_method("extinguish"):
			print("  -> Llamando extinguish directamente")
			target.extinguish()
			emit_signal("fire_extinguished", target)
		
		if target.has_method("get_global_position"):
			_play_water_hit_effect(target.global_position)

func _play_water_hit_effect(_hit_position: Vector2):
	"""Reproduce efectos visuales cuando el agua golpea algo"""
	# Aquí puedes instanciar partículas de salpicadura, etc.
	pass

# ============================================
# SISTEMA DE MUERTE DEL JUGADOR
# ============================================
func take_damage(amount: float) -> void:
	"""Recibe daño de enemigos - usa el sistema de vida heredado"""
	print_debug("Bombero recibió", amount, "de daño!")
	# Usar el sistema de vida del padre (personaje_base)
	recibir_dano(int(amount))

func die() -> void:
	# Detener el juego cuando la vida llega a 0
	if is_dead:
		return
	is_dead = true
	# Asegurar que este nodo siga recibiendo input durante la pausa (Godot 4)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	# Aquí podrías reproducir animación/sonido de muerte
	print("💀 El Bombero ha muerto. Juego pausado.")

# ============================================
# SISTEMA DE ATAQUE CON HACHA
# ============================================
func attack():
	if can_attack and current_axe_state == AxeState.IDLE:
		current_axe_state = AxeState.ATTACKING
		can_attack = false
		
		if axe_hitbox:
			axe_hitbox.monitoring = true

		# Reproducir la animación del hacha si existe en el AnimatedSprite2D
		if axe_sprite and axe_sprite.has_method("play") and axe_sprite.sprite_frames and axe_sprite.sprite_frames.has_animation("animacionHacha"):
			axe_sprite.play("animacionHacha")
		
		if animation_player and animation_player.has_animation("axe_attack"):
			animation_player.play("axe_attack")
		else:
			_animate_axe_swing()
		
		emit_signal("attack_performed")
		
		await get_tree().create_timer(0.1).timeout
		_perform_axe_attack()
		
		await get_tree().create_timer(0.2).timeout
		if axe_hitbox:
			axe_hitbox.monitoring = false
		
		# Volver a la animación base del hacha (idle) si existe
		if axe_sprite and axe_sprite.sprite_frames and axe_sprite.sprite_frames.has_animation("hacha"):
			axe_sprite.play("hacha")
		elif axe_sprite and axe_sprite.has_method("stop"):
			axe_sprite.stop()

		_reset_axe_position()
		var safe_cooldown = attack_cooldown_time if attack_cooldown_time != null else 0.2
		attack_cooldown_timer.start(safe_cooldown)

func _animate_axe_swing():
	if not axe_sprite:
		return
	
	# Crear un tween para animar la rotación
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var direction = 1
	if character_sprite and character_sprite.flip_h:
		direction = -1
	
	# Animación del swing: de vertical a horizontal
	tween.tween_property(axe_sprite, "rotation_degrees", 90 * direction, 0.15)
	tween.tween_property(axe_sprite, "rotation_degrees", 0, 0.15)

func _reset_axe_position():
	if axe_sprite:
		axe_sprite.rotation_degrees = 0

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
	
	for body in overlapping_bodies:
		_process_attack_target(body)
	
	for area in overlapping_areas:
		if area.get_parent():
			_process_attack_target(area.get_parent())

func _process_attack_target(target):
	# Ignorar al propio jugador - no atacarse a sí mismo
	if target == self or target.is_in_group("player"):
		return
	
	# Parry de bolas de fuego - destruir proyectiles
	if target.is_in_group("Fire") or target.is_in_group("enemy"):
		if target.has_method("queue_free") and (target.has_method("apply_water") or target.has_method("extinguish")):
			# Es una bola de fuego - ¡parry exitoso!
			print("¡Parry exitoso! Bola de fuego destruida")
			emit_signal("parry_successful")
			_play_parry_effect()
			target.queue_free()
			return
	
	# Ataque normal a otros objetivos
	if target.is_in_group("ExtinguisherBox"):
		_break_extinguisher_box(target)
	elif target.has_method("take_damage"):
		var safe_axe_damage = axe_damage if axe_damage != null else 5
		target.take_damage(safe_axe_damage)
	elif target.has_method("break_object"):
		target.break_object()

# ============================================
# SISTEMA DE PARRY
# ============================================
func parry():
	if can_attack and current_axe_state == AxeState.IDLE:
		current_axe_state = AxeState.PARRYING
		var safe_parry_window = parry_window if parry_window != null else 0.4
		parry_timer = safe_parry_window
		can_attack = false
		
		if animation_player and animation_player.has_animation("axe_parry"):
			animation_player.play("axe_parry")
		
		if axe_hitbox:
			axe_hitbox.monitoring = true
		
		var safe_parry_cooldown = parry_cooldown_time if parry_cooldown_time != null else 0.1
		attack_cooldown_timer.start(safe_parry_cooldown)

func attempt_parry(incoming_attack):
	if current_axe_state == AxeState.PARRYING:
		emit_signal("parry_successful")
		
		if incoming_attack.has_method("reflect"):
			incoming_attack.reflect()
		elif incoming_attack.has_method("cancel"):
			incoming_attack.cancel()
		
		_play_parry_effect()
		return true
	return false

func _play_parry_effect():
	print("¡Parry exitoso! Bola de fuego bloqueada con el hacha")
	# Aquí podrías agregar efectos visuales, sonidos, etc.

# ============================================
# SISTEMA DE CAJAS DE EXTINTOR
# ============================================
func _break_extinguisher_box(box):
	# Recarga la manguera al romper la caja
	var old_charge = hose_charge
	hose_charge = min(hose_charge + 25.0, 100.0)
	var _actual_recharge = hose_charge - old_charge

	emit_signal("hose_recharged", hose_charge)
	emit_signal("extinguisher_box_broken")

	_play_box_break_effect(box)

	# Si el nodo recibido es el Area2D (boxHitbox), obtener el padre (Box)
	var box_node = box
	if box is Area2D and box.name == "boxHitbox" and box.get_parent():
		box_node = box.get_parent()

	if box_node.has_method("break_with_effect"):
		box_node.break_with_effect()
	else:
		box_node.queue_free()

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
	if current_axe_state == AxeState.ATTACKING:
		_process_attack_target(body)

func _on_axe_area_hit(area):
	if current_axe_state == AxeState.ATTACKING:
		# Procesar el área directamente si es una bola de fuego
		if area.is_in_group("Fire") or area.is_in_group("enemy"):
			_process_attack_target(area)
		elif area.get_parent():
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

func is_hose_active() -> bool:
	return is_using_hose

func get_current_weapon() -> Weapon:
	return current_weapon

# Setters
func set_hose_charge(value: float):
	hose_charge = clamp(value, 0.0, 100.0)
	emit_signal("hose_recharged", hose_charge)

func reduce_hose_charge(amount: float):
	"""Reduce la carga de la manguera al usarla"""
	set_hose_charge(hose_charge - amount)

func add_hose_charge(amount: float):
	"""Añade carga a la manguera"""
	set_hose_charge(hose_charge + amount)
