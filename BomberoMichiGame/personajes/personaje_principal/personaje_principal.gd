extends "res://personajes/personaje_base.gd"
class_name Bomber

# Propiedades exportadas
@export var gravity = 100
@export var axe_damage = 5

# Sonidos del hacha (se alternan secuencialmente)
@export var axe_attack_sound_1: AudioStream = preload("res://Assets/SFX/hacha/Hacha_ataque_1.ogg")
@export var axe_attack_sound_2: AudioStream = preload("res://Assets/SFX/hacha/Hacha_ataque_2.ogg")
@export var axe_sound_volume_db: float = -8.0

var axe_sound_player: AudioStreamPlayer
var axe_attack_sound_index: int = 0

@export var parry_window = 0.4
@export var attack_cooldown_time = 0.2
@export var parry_cooldown_time = 0.1

# Propiedades de la manguera
@export var hose_range = 50  # Alcance en cuadros (tiles) - AUMENTADO
@export var tile_size = 20  # Tamaño de cada cuadro en píxeles
@export var hose_width = 40  # Ancho del chorro de agua
@export var hose_drain_rate = 4.0  # Carga consumida por segundo (reducida para mayor duración)
@export var water_pressure = 10.0  # Daño por segundo al fuego (ajustado para apagar en 0.5s)
@export var hose_origin_offset = Vector2(50, 0)  # Punto de origen del agua
@export var hose_nozzle_offset = Vector2(130, 30)  # Punta de la manguera (boquilla)
@export var water_recharge_rate = 3.0  # Cantidad de agua que se recarga por segundo
@export var water_recharge_on_box = 20.0  # Cantidad de agua al romper una caja

# Propiedades del oxígeno (sistema de barra de vida mejorado)
@export var oxygen_loss_rate = 1.0  # Pérdida de oxígeno por segundo en condiciones normales
@export var oxygen_recovery_rate = 5.0  # Recuperación de oxígeno por segundo sin enemigos/fuego
@export var oxygen_attack_damage = 10.0  # Pérdida de oxígeno por golpe
@export var oxygen_tankpickup = 25.0  # Cantidad de oxígeno que recupera un tanque
@export var oxygen_death_time = 5.0  # Segundos permitidos sin oxígeno antes de morir

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
var apuntador = null
var apuntador_offset = Vector2(130, 30)
var is_dead: bool = false
var manguera_bloqueada: bool = false  # Bloquea la manguera cuando llega a 0

# Variables de control de oxígeno
var oxygen_zero_timer = 0.0  # Contador para los 5 segundos permitidos sin oxígeno
var had_enemies_or_fire = false  # Para detectar cuándo no hay enemigos/fuego

# Sistema de pasos (footsteps)
@export var footstep_sounds: Array[AudioStream] = [
	preload("res://Assets/SFX/walk/Walk_1.ogg"),
	preload("res://Assets/SFX/walk/Walk_2.ogg"),
	preload("res://Assets/SFX/walk/Walk_3.ogg"),
	preload("res://Assets/SFX/walk/Walk_4.ogg")
]
@export var footstep_interval_slow: float = 1.2  # Intervalo cuando camina lentamente
@export var footstep_interval_fast: float = 0.4  # Intervalo cuando corre/movimiento constante
@export var footstep_volume_db: float = -15.0  # Volumen de los pasos (más bajo y natural)
@export var speed_threshold_run: float = 150.0  # Velocidad mínima para considerar como "corriendo"

var footstep_player: AudioStreamPlayer
var footstep_timer: float = 0.0
var was_moving: bool = false  # Para detectar transición entre movimiento y reposo

# Sistema de sonidos de manguera
@export var hose_water_sound: AudioStream = preload("res://Assets/SFX/agua/Agua_chorro.ogg")
@export var hose_empty_sound: AudioStream = preload("res://Assets/SFX/agua/Agua_empty.ogg")
@export var hose_sound_volume_db: float = -10.0  # Volumen de sonidos de manguera
@export var hose_empty_interval: float = 0.2  # Intervalo entre sonidos de vacío (segundos)
@export var hose_water_interval: float = 0.5  # Intervalo para repetir sonido de agua (mientras dispara)

var hose_sound_player: AudioStreamPlayer
var is_playing_water_sound: bool = false  # Para que no se repita constantemente
var hose_empty_timer: float = 0.0  # Timer para el sonido de vacío
var hose_water_timer: float = 0.0  # Timer para repetir sonido de agua

# Sistema de sonidos de fuego
@export var fire_extinguish_sound: AudioStream = preload("res://Assets/SFX/Fuego/Fuego_apago.ogg")
@export var fire_attack_sound: AudioStream = preload("res://Assets/SFX/Fuego/Fuego_ataque.ogg")
@export var fire_sound_volume_db: float = -12.0  # Volumen de sonidos de fuego

var fire_sound_player: AudioStreamPlayer

# Marcador calculado para la punta de la manguera
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

	# Configurar para que el personaje pueda detectar ESC incluso durante pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

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

	# Ocultar el cursor del sistema (Windows)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Instanciar apuntador visual
	var apuntador_scene = preload("res://Assets/Objetos/apuntador.tscn")
	apuntador = apuntador_scene.instantiate()
	apuntador.name = "Apuntador"
	add_child(apuntador)
	apuntador.z_index = 100 # Asegura que esté encima
	apuntador.visible = true
	# Offset para la punta de la manguera
	apuntador_offset = hose_nozzle_offset if hose_nozzle_offset != null else Vector2(130, 30)

	# Desactivar clamp al viewport para el jugador (una sola vez)
	clamp_to_viewport = false
	
	# Emitir valores iniciales para que el HUD se actualice
	emit_signal("hose_recharged", hose_charge)  # Emitir carga inicial de agua
	emit_signal("vida_actualizada", vida_actual)  # Emitir vida inicial para que el HUD se actualice
	
	print("✓ Vida inicial emitida:", vida_actual, "/", vida_maxima)
	
	# Configurar sistema de pasos
	_setup_footstep_system()
	
	# Configurar sistema de sonidos de manguera
	_setup_hose_sound_system()
	
	# Configurar sistema de sonidos de fuego
	_setup_fire_sound_system()
	
	# Configurar sistema de sonidos de hacha
	_setup_axe_sound_system()
	
	# Configurar sistema de sonidos de fuego
	_setup_fire_sound_system()

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
	# Si el personaje está muerto, no procesar nada
	if not vivo:
		return
	
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

	# ========== SISTEMA DE RECARGA AUTOMÁTICA DE AGUA ==========
	_update_water_recharge(delta)
	
	# ========== SISTEMA DE CONSUMO/RECUPERACIÓN DE OXÍGENO ==========
	_update_oxygen_system(delta)
	
	# ========== SISTEMA DE PASOS ==========
	_update_footsteps(delta)

	# Limitar posición dentro del campo definido (SOLO si enforce_bounds está activo)
	if enforce_bounds:
		var minx = (min_x if min_x != null else -1000.0)
		var maxx = (max_x if max_x != null else 1000.0)
		var miny = (min_y if min_y != null else -1000.0)
		var maxy = (max_y if max_y != null else 1000.0)
		
		# Aplicar clamp y actualizar posición
		var clamped_x = clamp(global_position.x, float(minx), float(maxx))
		var clamped_y = clamp(global_position.y, float(miny), float(maxy))
		global_position = Vector2(clamped_x, clamped_y)
		
		# Debug solo si está activo el clamp
		if abs(velocity.x) > 0 or abs(velocity.y) > 0:
			print_debug("Player clamped -> pos:", global_position, "vel:", velocity)

	# Este personaje ya tiene animaciones separadas de izquierda/derecha,
	# por eso no usamos flip_h para evitar invertir visualmente el lado.
	if character_sprite:
		character_sprite.flip_h = false

	# Actualizar posición y rotación de las armas según la dirección de movimiento
	_update_weapon_orientation()

	# adicionalmente asegurar que el personaje no salga del viewport
	# (no-op porque clamp_to_viewport está desactivado para el jugador)
	# keep_in_viewport()

func _unhandled_input(event):
	# Si el jugador está muerto, no procesar ningún input (el menú de muerte maneja todo)
	if not vivo:
		return

	# Detectar ESC para pausar el juego
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return

	# Detectar scroll del mouse para cambiar arma
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				switch_weapon()

func _toggle_pause_menu():
	"""Activa/desactiva el menú de pausa"""
	# Buscar el MenusLayer
	var menus_layer = get_tree().root.find_child("MenusLayer", true, false)
	if not menus_layer:
		print("⚠️ MenusLayer no encontrado")
		return

	# Buscar los menús
	var pause_menu = menus_layer.get_node_or_null("PuseMenu")
	var death_menu = menus_layer.get_node_or_null("DeathMenu")

	# No permitir pausar si hay pantalla de muerte activa
	if death_menu and death_menu.visible:
		return

	# Alternar pausa
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused

	# Mostrar/ocultar menús
	menus_layer.visible = is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	if death_menu:
		death_menu.visible = false

	# Mostrar/ocultar cursor
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _handle_input():
	# Si el personaje está muerto, no procesar input
	if not vivo:
		return
	
	# Intercambiar arma con Q
	if Input.is_action_just_pressed("ui_focus_next"):  # Q por defecto
		switch_weapon()
	
	# También puedes usar una acción personalizada si la configuras
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	# Sistema de manguera (botón mantenido) - solo si está equipada
	if current_weapon == Weapon.HOSE:
		if Input.is_action_pressed("use_hose"):
			if can_use_hose():
				# Puede usar la manguera, reproducir agua
				if not is_using_hose:
					_activate_hose()
			else:
				# NO puede usar la manguera, reproducir sonido de vacío con intervalo
				if is_using_hose:
					_deactivate_hose()
				
				# Decrementar timer de vacío
				hose_empty_timer -= get_physics_process_delta_time()
				if hose_empty_timer <= 0.0:
					_play_hose_empty_sound()  # Reproducir sonido de vacío
					hose_empty_timer = hose_empty_interval  # Reiniciar timer
		elif is_using_hose:
			_deactivate_hose()
		else:
			# Si suelta el botón, resetear el timer
			hose_empty_timer = 0.0
	else:
		# Si cambiamos de arma mientras usamos la manguera, desactivarla
		if is_using_hose:
			_deactivate_hose()
	
	# Sistema de ataque con hacha - solo si está equipada
	if current_weapon == Weapon.AXE:
		if Input.is_action_just_pressed("attack"):
			attack()  # El ataque ahora funciona como parry automático

	# Dash: usar la acción 'dash' (tecla Shift) exclusivamente
	var dash_pressed := false
	if InputMap.has_action("dash"):
		dash_pressed = Input.is_action_just_pressed("dash") and not Input.is_action_pressed("attack")
	else:
		dash_pressed = false

	if dash_pressed and can_dash:
		# Determinar dirección de dash: preferir input vector, caer a dirección mirando
		var dir = Input.get_vector("left", "right", "up", "down")
		if dir == Vector2.ZERO:
			# Si no hay input, dash hacia la última dirección usada.
			dir = last_direction.normalized() if last_direction != Vector2.ZERO else Vector2(1, 0)

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

	# Actualizar posición y rotación del apuntador visual
	if apuntador:
		apuntador.global_position = global_position + direction * 80.0 + apuntador_offset.rotated(angle)
		apuntador.rotation = angle
	
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
		_play_hose_empty_sound()  # Reproducir sonido de vacío
		return
	
	is_using_hose = true
	emit_signal("hose_activated")
	_play_hose_water_sound()  # Reproducir sonido de agua
	hose_water_timer = hose_water_interval  # Resetear timer para repetición
	
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
	is_playing_water_sound = false
	emit_signal("hose_deactivated")
	
	# Detener sonido de agua
	if hose_sound_player:
		hose_sound_player.stop()
		print("⏹️ Sonido de agua detenido")
	
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
	
	# Control de sonido de agua (repetir mientras esté activo)
	if is_using_hose:
		hose_water_timer -= delta
		if hose_water_timer <= 0.0:
			_play_hose_water_sound()
			hose_water_timer = hose_water_interval
	
	# Calcular daño de agua usando water_pressure
	var safe_water_pressure = water_pressure if water_pressure != null else 5.0
	var water_damage = safe_water_pressure * delta
	
	# Actualizar dirección de la manguera según hacia dónde mira el personaje
	_update_hose_direction()
	
	# Detectar y apagar fuego con el daño calculado
	_detect_and_extinguish_fire(water_damage)
	
	# SI LLEGA A 0: Bloqueo inmediato
	if hose_charge <= 0:
		hose_charge = 0
		manguera_bloqueada = true
		_play_hose_empty_sound()  # Reproducir sonido de vacío
		_deactivate_hose()
		print("⚠️ Manguera agotada. Esperando recarga al 20%...")

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
	# Usar el sistema de vida del padre (personaje_base) - ahora acepta float
	recibir_dano(amount)

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
		# Reproducir sonido de ataque de hacha secuencial (hachaataque1, hacha_ataque2)
		_play_axe_attack_sound()
		
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
	if last_direction.x < 0:
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
	var safe_recharge = water_recharge_on_box if water_recharge_on_box != null else 20.0
	set_hose_charge(hose_charge + safe_recharge)
	var actual_recharge = hose_charge - old_charge

	print("¡Caja rota! Agua recargada: +", actual_recharge, "% (", old_charge, "% → ", hose_charge, "%)")
	
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
	# Solo puede usar la manguera si tiene carga Y no está bloqueada
	return hose_charge > 0.0 and not manguera_bloqueada

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

# ============================================
# SISTEMA DE RECARGA AUTOMÁTICA DE AGUA
# ============================================
func _update_water_recharge(delta):
	"""Recarga automática de agua: +3 por segundo y control de bloqueo"""
	if not is_using_hose:
		# Recarga normal cuando no se usa
		set_hose_charge(hose_charge + (water_recharge_rate * delta))
		
		# SI ESTABA BLOQUEADA: Revisar si ya recuperó el 20% para desbloquear
		if manguera_bloqueada and hose_charge >= 20.0:
			manguera_bloqueada = false
			print("✅ Manguera recuperada. ¡Puedes disparar!")

# ============================================
# SISTEMA DE CONSUMO/RECUPERACIÓN DE OXÍGENO
# ============================================
func _update_oxygen_system(delta):
	"""
	Maneja el sistema de oxígeno:
	- Consume -1 por segundo normalmente
	- Recupera +5 por segundo sin enemigos/fuego
	- Contar 5 segundos si llega a 0
	"""
	# Si el personaje está muerto, no hacer nada
	if not vivo:
		return
	
	# Detectar si hay enemigos o fuego activos en la escena
	var enemies = get_tree().get_nodes_in_group("enemy")
	var minions = get_tree().get_nodes_in_group("minion")
	var fire_nodes = get_tree().get_nodes_in_group("Fire")
	
	var has_enemies_or_fire = (enemies.size() > 0 or minions.size() > 0 or fire_nodes.size() > 0)
	
	# Si oxígeno es cero, iniciar contador de muerte
	if vida_actual <= 0.0:
		if oxygen_zero_timer <= 0.0:
			oxygen_zero_timer = oxygen_death_time
			print("⚠️ ¡OXÍGENO AGOTADO! Tienes ", oxygen_death_time, " segundos para obtener oxígeno")
		
		oxygen_zero_timer -= delta
		
		# Si se acaba el tiempo sin oxígeno, morir
		if oxygen_zero_timer <= 0.0 and not is_dead:
			is_dead = true
			print("💀 ¡TIEMPO AGOTADO! Game Over sin oxígeno")
		return
	else:
		# Resetear contador si hay oxígeno
		oxygen_zero_timer = 0.0
	
	# Si hay enemigos o fuego: consumir oxígeno (-1 por segundo)
	if has_enemies_or_fire:
		recibir_dano(oxygen_loss_rate * delta)
	else:
		# Sin enemigos/fuego: recuperar oxígeno (+5 por segundo)
		if vida_actual < vida_maxima:
			curar(oxygen_recovery_rate * delta)

# ============================================
# SISTEMA DE PASOS (FOOTSTEPS)
# ============================================
func _setup_footstep_system():
	"""Inicializa el sistema de pasos"""
	footstep_player = AudioStreamPlayer.new()
	footstep_player.bus = "Master"
	footstep_player.volume_db = footstep_volume_db
	add_child(footstep_player)
	print("🚶 Sistema de pasos inicializado")

func _update_footsteps(delta):
	"""Controla la reproducción de pasos según el movimiento y velocidad"""
	var input_vector = Input.get_vector("left", "right", "up", "down")
	var is_moving = input_vector.length() > 0.0
	
	if is_moving and not is_dashing:
		# Calcular velocidad actual del personaje
		var current_speed = velocity.length()
		
		# Determinar el intervalo según la velocidad
		var dynamic_interval = footstep_interval_slow
		
		# Si se está moviendo rápido (corriendo/movimiento constante), usar intervalo más frecuente
		if current_speed >= speed_threshold_run:
			dynamic_interval = footstep_interval_fast
		else:
			# Interpolación lineal entre intervalo lento y rápido
			var speed_ratio = current_speed / speed_threshold_run
			dynamic_interval = lerp(footstep_interval_slow, footstep_interval_fast, speed_ratio)
		
		# Reproducir paso si es tiempo
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_play_random_footstep()
			footstep_timer = dynamic_interval
	else:
		# Personaje no se está moviendo, resetear timer
		if was_moving:
			footstep_timer = 0.0
	
	was_moving = is_moving

func _play_random_footstep():
	"""Reproduce un sonido de paso aleatorio de los 4 disponibles"""
	if footstep_player and footstep_sounds.size() > 0:
		var random_index = randi() % footstep_sounds.size()
		var selected_sound = footstep_sounds[random_index]
		var current_speed = velocity.length()
		
		footstep_player.stream = selected_sound
		footstep_player.volume_db = footstep_volume_db
		footstep_player.play()
		print("👣 Paso ", random_index + 1, " (Velocidad: ", int(current_speed), " px/s)")

# ============================================
# SISTEMA DE SONIDOS DE MANGUERA
# ============================================
func _setup_hose_sound_system():
	"""Inicializa el sistema de sonidos de manguera"""
	hose_sound_player = AudioStreamPlayer.new()
	hose_sound_player.bus = "Master"
	hose_sound_player.volume_db = hose_sound_volume_db
	add_child(hose_sound_player)
	print("💧 Sistema de sonidos de manguera inicializado")

func _play_hose_water_sound():
	"""Reproduce el sonido del agua cuando dispara"""
	if hose_sound_player and hose_water_sound and not is_playing_water_sound:
		hose_sound_player.stream = hose_water_sound
		hose_sound_player.volume_db = hose_sound_volume_db
		hose_sound_player.play()
		is_playing_water_sound = true
		print("💦 Sonido de agua activado")

func _play_hose_empty_sound():
	"""Reproduce el sonido de vacío cuando no hay carga"""
	if hose_sound_player and hose_empty_sound:
		hose_sound_player.stream = hose_empty_sound
		hose_sound_player.volume_db = hose_sound_volume_db
		hose_sound_player.play()
		print("🚫 ¡Manguera vacía!")

func _setup_fire_sound_system():
	"""Inicializa el sistema de sonidos de fuego"""
	fire_sound_player = AudioStreamPlayer.new()
	fire_sound_player.bus = "Master"
	fire_sound_player.volume_db = fire_sound_volume_db
	add_child(fire_sound_player)
	print("🔥 Sistema de sonidos de fuego inicializado")

func _setup_axe_sound_system():
	"""Inicializa el sistema de sonidos de hacha"""
	axe_sound_player = AudioStreamPlayer.new()
	axe_sound_player.bus = "Master"
	axe_sound_player.volume_db = axe_sound_volume_db
	add_child(axe_sound_player)
	print("🪓 Sistema de sonidos de hacha inicializado")

func _play_axe_attack_sound():
	"""Reproduce sonido de ataque de hacha en orden secuencial"""
	if not axe_sound_player:
		return

	var sound_stream = null
	if axe_attack_sound_index == 0:
		sound_stream = axe_attack_sound_1
	else:
		sound_stream = axe_attack_sound_2

	if sound_stream:
		axe_sound_player.stream = sound_stream
		axe_sound_player.volume_db = axe_sound_volume_db
		axe_sound_player.play()
		print("🪓 Sonido de ataque de hacha", axe_attack_sound_index + 1)

	axe_attack_sound_index = (axe_attack_sound_index + 1) % 2

func _play_fire_extinguish_sound():
	"""Reproduce el sonido al apagar fuego"""
	if fire_sound_player and fire_extinguish_sound:
		fire_sound_player.stream = fire_extinguish_sound
		fire_sound_player.volume_db = fire_sound_volume_db
		fire_sound_player.play()
		print("💨 ¡Fuego apagado!")

func _play_fire_attack_sound():
	"""Reproduce el sonido cuando minions/jefe lanzan bolsa de fuego"""
	if fire_sound_player and fire_attack_sound:
		fire_sound_player.stream = fire_attack_sound
		fire_sound_player.volume_db = fire_sound_volume_db
		fire_sound_player.play()
		print("🎯 ¡Ataque de fuego!")
