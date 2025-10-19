extends "res://personajes/personaje_base.gd"
class_name Bomber

# Propiedades exportadas
@export var gravity = 100
@export var axe_damage = 5
@export var parry_window = 0.2
@export var attack_cooldown_time = 0.2
@export var parry_cooldown_time = 0.3

# Propiedades de la manguera
@export var hose_range = 50  # Alcance en cuadros (tiles) - AUMENTADO
@export var tile_size = 20  # Tamaño de cada cuadro en píxeles
@export var hose_width = 40  # Ancho del chorro de agua
@export var hose_drain_rate = 10.0  # Carga consumida por segundo
@export var water_pressure = 5.0  # Daño/efecto por segundo al fuego
@export var hose_origin_offset = Vector2(50, 0)  # Punto de origen del agua
@export var hose_nozzle_offset = Vector2(80, 0)  # Punta de la manguera (boquilla)

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
 

# Referencias a nodos
@onready var axe_hitbox = $Axe/AxeHitbox
@onready var axe_sprite = $Axe
@onready var hose_sprite = $hose
@onready var attack_cooldown_timer = $AttackCooldownTimer
@onready var animation_player = $AnimationPlayer
@onready var character_sprite = $Sprite2D

# Nodos para la manguera
@onready var hose_area = $HoseArea  # Area2D para detectar fuego
@onready var hose_raycast = $HoseRaycast  # RayCast2D para dirección
@onready var water_particles = $WaterParticles  # Partículas de agua (opcional)

# Señales
signal hose_recharged(new_charge)
signal extinguisher_box_broken
signal parry_successful
signal attack_performed
signal hose_activated
signal hose_deactivated
signal fire_extinguished(fire_node)
signal weapon_switched(new_weapon)

func _ready():
	# Configurar timer de cooldown
	if not attack_cooldown_timer:
		attack_cooldown_timer = Timer.new()
		attack_cooldown_timer.one_shot = true
		add_child(attack_cooldown_timer)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	
	# Configurar hitbox del hacha
	if axe_hitbox:
		axe_hitbox.monitoring = false
		axe_hitbox.body_entered.connect(_on_axe_hit)
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

func _setup_hose_system():
	"""Configura los nodos necesarios para el sistema de manguera"""
	# Si no existen los nodos, crearlos
	if not hose_area:
		hose_area = Area2D.new()
		hose_area.name = "HoseArea"
		add_child(hose_area)
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(hose_range * tile_size, hose_width)
		collision.shape = shape
		collision.position = Vector2((hose_range * tile_size) / 2.0, 0) + hose_nozzle_offset
		hose_area.add_child(collision)
		
		hose_area.monitoring = false
	else:
		# Actualizar shape existente con nuevos valores
		if hose_area.get_child_count() > 0:
			var collision = hose_area.get_child(0)
			if collision.shape:
				collision.shape.size = Vector2(hose_range * tile_size, hose_width)
				collision.position = Vector2((hose_range * tile_size) / 2.0, 0) + hose_nozzle_offset
	
	if not hose_raycast:
		hose_raycast = RayCast2D.new()
		hose_raycast.name = "HoseRaycast"
		hose_raycast.position = hose_nozzle_offset
		hose_raycast.target_position = Vector2(hose_range * tile_size, 0)
		hose_raycast.enabled = false
		add_child(hose_raycast)
	else:
		# Actualizar raycast existente
		hose_raycast.position = hose_nozzle_offset
		hose_raycast.target_position = Vector2(hose_range * tile_size, 0)
	
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
		water_particles.position = hose_nozzle_offset
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
		water_particles.position = hose_nozzle_offset

func _physics_process(delta):
	# Movimiento WASD
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
			attack()
		
		# Sistema de parry
		elif Input.is_action_just_pressed("parry"):
			parry()

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
	
	# Activar área de detección
	if hose_area:
		hose_area.monitoring = true
	
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
		print("Alcance de manguera: ", hose_range * tile_size, " píxeles")
	else:
		print("ERROR: WaterParticles no encontrado!")
	
	print("Manguera activada - Carga: ", hose_charge, "%")

func _deactivate_hose():
	"""Desactiva la manguera de agua"""
	is_using_hose = false
	emit_signal("hose_deactivated")
	
	# Desactivar área de detección
	if hose_area:
		hose_area.monitoring = false
	
	# Desactivar raycast
	if hose_raycast:
		hose_raycast.enabled = false
	
	# Desactivar partículas de agua
	if water_particles:
		water_particles.emitting = false

func _update_hose(delta):
	"""Actualiza el sistema de manguera mientras está activa"""
	# Consumir carga y usar esa misma cantidad como "daño de agua"
	var water_used: float = hose_drain_rate * delta
	reduce_hose_charge(water_used)
	
	# Actualizar dirección de la manguera según hacia dónde mira el personaje
	_update_hose_direction()
	
	# Detectar y apagar fuego
	_detect_and_extinguish_fire(water_used)
	
	# Si se acabó la carga, desactivar
	if hose_charge <= 0:
		_deactivate_hose()
		print("¡Manguera vacía!")

func _update_hose_direction():
	"""Actualiza la dirección de la manguera según la orientación del personaje"""
	var direction = 1
	if character_sprite and character_sprite.flip_h:
		direction = -1
	
	# Actualizar posición del área de colisión
	if hose_area and hose_area.get_child_count() > 0:
		var collision = hose_area.get_child(0)
		var base_offset = (hose_range * tile_size) / 2.0
		collision.position = Vector2(base_offset * direction, 0) + Vector2(hose_nozzle_offset.x * direction, hose_nozzle_offset.y)
	
	# Actualizar dirección del raycast
	if hose_raycast:
		hose_raycast.position = Vector2(hose_nozzle_offset.x * direction, hose_nozzle_offset.y)
		hose_raycast.target_position = Vector2((hose_range * tile_size) * direction, 0)
	
	# Actualizar dirección de las partículas
	if water_particles:
		water_particles.direction = Vector2(direction, 0)
		water_particles.position = Vector2(hose_nozzle_offset.x * direction, hose_nozzle_offset.y)

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
	# Aplicar agua o daño a cualquier objetivo compatible (fuego, enemigos, etc.)
	if target.has_method("apply_water") or target.has_method("take_damage") or target.is_in_group("Fire") or target.has_method("extinguish"):
		# Si el objetivo acepta agua, pásale la cantidad de agua usada literalmente
		if target.has_method("apply_water"):
			target.apply_water(water_amount)
		# Si recibe daño, usa el agua como daño directo: 1 agua = 1 daño
		elif target.has_method("take_damage"):
			target.take_damage(water_amount)
		elif target.has_method("extinguish"):
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
func die() -> void:
	# Detener el juego por ahora al morir
	if is_dead:
		return
	is_dead = true
	# Asegurar que este nodo siga recibiendo input durante la pausa (Godot 4)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	# Aquí podrías reproducir animación/sonido de muerte
	print("El Bombero ha muerto. Juego pausado.")

# ============================================
# SISTEMA DE ATAQUE CON HACHA
# ============================================
func attack():
	if can_attack and current_axe_state == AxeState.IDLE:
		current_axe_state = AxeState.ATTACKING
		can_attack = false
		
		if axe_hitbox:
			axe_hitbox.monitoring = true
		
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
		
		_reset_axe_position()
		attack_cooldown_timer.start(attack_cooldown_time)

func _animate_axe_swing():
	if not axe_sprite:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var direction = 1
	if character_sprite and character_sprite.flip_h:
		direction = -1
	
	tween.tween_property(axe_sprite, "rotation_degrees", 90 * direction, 0.15)
	tween.tween_property(axe_sprite, "rotation_degrees", 0, 0.15)

func _reset_axe_position():
	if axe_sprite:
		axe_sprite.rotation_degrees = 0

func _perform_axe_attack():
	if not axe_hitbox:
		return
	
	var overlapping_bodies = axe_hitbox.get_overlapping_bodies()
	var overlapping_areas = axe_hitbox.get_overlapping_areas()
	
	for body in overlapping_bodies:
		_process_attack_target(body)
	
	for area in overlapping_areas:
		if area.get_parent():
			_process_attack_target(area.get_parent())

func _process_attack_target(target):
	if target.is_in_group("ExtinguisherBox"):
		_break_extinguisher_box(target)
	elif target.has_method("take_damage"):
		target.take_damage(axe_damage)
	elif target.has_method("break_object"):
		target.break_object()

# ============================================
# SISTEMA DE PARRY
# ============================================
func parry():
	if can_attack and current_axe_state == AxeState.IDLE:
		current_axe_state = AxeState.PARRYING
		parry_timer = parry_window
		can_attack = false
		
		if animation_player and animation_player.has_animation("axe_parry"):
			animation_player.play("axe_parry")
		
		if axe_hitbox:
			axe_hitbox.monitoring = true
		
		attack_cooldown_timer.start(parry_cooldown_time)

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
	print("¡Parry exitoso!")

# ============================================
# SISTEMA DE CAJAS DE EXTINTOR
# ============================================
func _break_extinguisher_box(box):
	var old_charge = hose_charge
	hose_charge = min(hose_charge + 25.0, 100.0)
	var actual_recharge = hose_charge - old_charge
	
	print("Caja rota! Manguera recargada: +", actual_recharge, "% (Total: ", hose_charge, "%)")
	
	emit_signal("hose_recharged", hose_charge)
	emit_signal("extinguisher_box_broken")
	
	_play_box_break_effect(box)
	
	if box.has_method("break_with_effect"):
		box.break_with_effect()
	else:
		box.queue_free()

func _play_box_break_effect(_box):
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
