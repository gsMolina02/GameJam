extends "res://personajes/personaje_base.gd"
class_name Bomber

# Propiedades exportadas
@export var gravity = 100
@export var axe_damage = 5

# Sonidos del hacha (se alternan secuencialmente)
@export var axe_attack_sound_1: AudioStream = preload("res://Assets/SFX/hacha/Hacha_ataque_1.ogg")
@export var axe_attack_sound_2: AudioStream = preload("res://Assets/SFX/hacha/Hacha_ataque_2.ogg")
@export var axe_sound_volume_db: float = -8.0

# Sonido de roll/dash
@export var dash_sound: AudioStream = preload("res://Assets/SFX/roll/roll.ogg")
@export var dash_sound_volume_db: float = -10.0

var axe_sound_player: AudioStreamPlayer
var axe_attack_sound_index: int = 0
var dash_sound_player: AudioStreamPlayer
var last_mouse_button_time: float = 0.0

@export var parry_window = 0.4
@export var attack_cooldown_time = 0.2
@export var parry_cooldown_time = 0.1

# Propiedades de la manguera
@export var hose_range = 15  # Alcance en cuadros (tiles) - Reducido para que coincida con alcance real de partículas (~300px)
@export var tile_size = 20  # Tamaño de cada cuadro en píxeles
@export var hose_width = 30  # Ancho del chorro de agua - Reducido para mejor precisión
@export var hose_drain_rate = 4.0  # Carga consumida por segundo (reducida para mayor duración)
@export var water_pressure = 10.0  # Daño por segundo al fuego (ajustado para apagar en 0.5s)
@export var hose_origin_offset = Vector2(50, 0)  # Punto de origen del agua
@export var hose_nozzle_offset = Vector2(130, 30)  # Punta de la manguera (boquilla)
@export var water_recharge_rate = 3.0  # Cantidad de agua que se recarga por segundo
@export var water_recharge_on_box = 20.0  # Cantidad de agua al romper una caja
@export var aim_deadzone_px: float = 8.0  # Deadzone menor para evitar sensacion pegajosa al apuntar
@export var aim_smoothing_speed: float = 24.0  # Mas responsivo para seguir mejor el mouse

# Propiedades del oxígeno (sistema de barra de vida mejorado)
@export var oxygen_loss_rate = 0.5  # Pérdida de oxígeno por segundo en condiciones normales
@export var oxygen_recovery_rate = 5.0  # Recuperación de oxígeno por segundo sin enemigos/fuego
@export var oxygen_attack_damage = 10.0  # Pérdida de oxígeno por golpe
@export var oxygen_tankpickup = 25.0  # Cantidad de oxígeno que recupera un tanque
@export var oxygen_death_time = 5.0  # Segundos permitidos sin oxígeno antes de morir
@export var oxygen_scan_interval: float = 0.25  # Intervalo de escaneo de enemigos/fuego para evitar tirones

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
var hacha_desbloqueada: bool = true  # Siempre disponible desde el inicio
var apuntador = null
var apuntador_offset = Vector2(130, 30)
var current_aim_direction: Vector2 = Vector2.RIGHT
var last_movement_direction: Vector2 = Vector2.RIGHT  # Dirección del último movimiento para rotar armas dinámicamente
var is_dead: bool = false
var manguera_bloqueada: bool = false  # Bloquea la manguera cuando llega a 0
# is_performing_special_attack está heredado de personaje_base.gd

# Variables de control de oxígeno
var oxygen_zero_timer = 0.0  # Contador para los 5 segundos permitidos sin oxígeno
var had_enemies_or_fire = false  # Para detectar cuándo no hay enemigos/fuego
var oxygen_scan_timer = 0.0

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
@export var footstep_debug_logs: bool = false

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
@onready var axe_pivot = get_node_or_null("AxePivot")
@onready var hose_pivot = get_node_or_null("HosePivot")
@onready var attack_cooldown_timer = get_node_or_null("AttackCooldownTimer")
@onready var animation_player = get_node_or_null("AnimationPlayer")  # Para animaciones
@onready var character_sprite = get_node_or_null("AnimatedSprite")  # Sprite del bombero para detectar dirección

# Nodos para la manguera (guardadas con get_node_or_null para evitar errores en escenas de prueba)
@onready var hose_area = get_node_or_null("HoseArea")  # Area2D para detectar fuego
@onready var hose_raycast = get_node_or_null("HoseRaycast")  # RayCast2D para dirección
@onready var water_particles = get_node_or_null("WaterParticles")  # Partículas de agua (opcional)
@onready var water_jet_sprite = get_node_or_null("WaterJetSprite")  # Sprite animado del chorro de agua
var axe_base_scale: Vector2 = Vector2.ONE
var hose_base_scale: Vector2 = Vector2.ONE
var axe_pivot_base_position: Vector2 = Vector2.ZERO
var hose_pivot_base_position: Vector2 = Vector2.ZERO
@export var axe_pivot_extra_offset: Vector2 = Vector2.ZERO
@export var hose_pivot_extra_offset: Vector2 = Vector2.ZERO

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
	_configure_mouse_combat_bindings()
	_ensure_weapon_pivots()

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

	# Guardar escalas base de armas para mantener tamaño al voltear
	if axe_sprite:
		axe_base_scale = axe_sprite.scale
	if hose_sprite:
		hose_base_scale = hose_sprite.scale

	# Guardar posición base de los pivotes para respetar ajuste manual en editor
	if axe_pivot:
		axe_pivot_base_position = axe_pivot.position
	if hose_pivot:
		hose_pivot_base_position = hose_pivot.position
	
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
	
	# Configurar sistemas de sonido
	_setup_hose_sound_system()
	_setup_fire_sound_system()
	_setup_axe_sound_system()
	_setup_dash_sound_system()
	
	# Garantizar que el menú de pausa exista en este nivel
	# (si el nivel no lo tiene en su .tscn, se crea dinámicamente)
	_ensure_pause_menu()
	
	# Restaurar posición si hay una guardada válida
	if "posicion_guardada" in GameManager and GameManager.posicion_guardada != Vector2.INF:
		global_position = GameManager.posicion_guardada
		print("📍 Jugador restaurado en guardado:", global_position)
		GameManager.posicion_guardada = Vector2.INF  # Limpiar
	elif "posicionar_jugador_en_puerta" in GameManager:
		GameManager.posicionar_jugador_en_puerta(self, get_tree().current_scene)

func _ensure_pause_menu() -> void:
	"""Crea el menú de pausa dinámicamente si el nivel no lo tiene.
	Como el jugador está en todos los niveles, esto garantiza que ESC
	siempre funcione sin necesidad de editar cada escena."""
	# Esperar un frame para que los nodos del nivel estén listos
	await get_tree().process_frame
	
	# Si ya hay un PuseMenu en el árbol (instanciado en el .tscn del nivel), no hacer nada
	if get_tree().get_nodes_in_group("pause_menu_ui").size() > 0:
		print("✅ Menú de pausa encontrado en la escena")
		return
	
	# No existe → crear el MenusLayer con PuseMenu y DeathMenu dinámicamente
	var canvas := CanvasLayer.new()
	canvas.name = "MenusLayer"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.layer = 30
	canvas.visible = false
	get_tree().current_scene.add_child(canvas)
	
	var pause_scene := preload("res://Interfaces/puse_menu.tscn")
	var pause_menu := pause_scene.instantiate()
	pause_menu.name = "PuseMenu"
	canvas.add_child(pause_menu)
	
	var death_scene := preload("res://Scenes/UI/deathEscene.tscn")
	var death_menu := death_scene.instantiate()
	death_menu.name = "DeathMenu"
	canvas.add_child(death_menu)
	
	print("✅ Menú de pausa creado dinámicamente para '", get_tree().current_scene.name, "'")

func _ensure_weapon_pivots() -> void:
	"""Crea pivotes si faltan y reubica las armas para rotarlas de forma estable."""
	var axe_pivot_was_nested := false
	var hose_pivot_was_nested := false

	# Buscar pivotes existentes en cualquier nivel (por si quedaron como hijos de Axe/hose).
	if not axe_pivot:
		axe_pivot = find_child("AxePivot", true, false) as Marker2D
	if not hose_pivot:
		hose_pivot = find_child("HosePivot", true, false) as Marker2D

	if not axe_pivot:
		axe_pivot = Marker2D.new()
		axe_pivot.name = "AxePivot"
		add_child(axe_pivot)

	if not hose_pivot:
		hose_pivot = Marker2D.new()
		hose_pivot.name = "HosePivot"
		add_child(hose_pivot)

	# Si el pivote está dentro del sprite (configuración invertida), sácalo al root.
	if axe_sprite and axe_pivot and axe_sprite.is_ancestor_of(axe_pivot):
		axe_pivot_was_nested = true
		axe_pivot.reparent(self, true)
	if hose_sprite and hose_pivot and hose_sprite.is_ancestor_of(hose_pivot):
		hose_pivot_was_nested = true
		hose_pivot.reparent(self, true)

	if axe_pivot:
		axe_pivot.scale = Vector2.ONE
		axe_pivot.skew = 0.0
	if hose_pivot:
		hose_pivot.scale = Vector2.ONE
		hose_pivot.skew = 0.0

	# Si venian con transformaciones corruptas por estar anidados, normalizar posiciones base.
	if axe_pivot and (axe_pivot_was_nested or axe_pivot.position.length() > 300.0):
		axe_pivot.position = Vector2(20.0, -4.0)
	if hose_pivot and (hose_pivot_was_nested or hose_pivot.position.length() > 300.0):
		hose_pivot.position = Vector2(18.0, -2.0)

	if axe_sprite and axe_sprite.get_parent() != axe_pivot:
		axe_sprite.reparent(axe_pivot, true)
		axe_sprite.position = Vector2.ZERO
		axe_sprite.rotation = 0.0
		axe_sprite.z_index = 0

	if axe_sprite:
		# El pivote controla la profundidad; el sprite no debe sumar z_index local.
		axe_sprite.z_index = 0

	if hose_sprite and hose_sprite.get_parent() != hose_pivot:
		hose_sprite.reparent(hose_pivot, true)
		hose_sprite.position = Vector2.ZERO
		hose_sprite.rotation = 0.0
		hose_sprite.z_index = 0

	if hose_sprite:
		# El pivote controla la profundidad; el sprite no debe sumar z_index local.
		hose_sprite.z_index = 0

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

	# Siempre forzar máscara correcta, incluso si HoseArea ya existía.
	# Capa 1: cuerpos que quedaron en default. Capa 2: enemigos/fuego configurados.
	hose_area.collision_mask = 0
	hose_area.set_collision_mask_value(1, true)
	hose_area.set_collision_mask_value(2, true)
	
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
		water_particles.amount = 120  # Más partículas para mejor densidad
		water_particles.lifetime = 1.2  # Más tiempo de vida para mejor animación
		water_particles.speed_scale = 1.0
		
		# Dirección y velocidad
		water_particles.direction = Vector2(1, 0)
		water_particles.spread = 20.0  # Mayor dispersión para efecto más disperso
		water_particles.initial_velocity_min = 300.0
		water_particles.initial_velocity_max = 550.0
		
		# Gravedad y física
		water_particles.gravity = Vector2(0, 150)  # Mayor gravedad para caída más rápida
		water_particles.damping_min = 8.0
		water_particles.damping_max = 15.0
		
		# Apariencia - Color azul más saturado como el sprite
		water_particles.scale_amount_min = 4.0
		water_particles.scale_amount_max = 8.0
		water_particles.color = Color(0.2, 0.6, 1.0, 0.9)  # Azul más saturado y brillante
		
		# Variación de color para más vitalidad
		water_particles.color_initial_ramp = Gradient.new()
		
		# Emisión en rectángulo
		water_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		# Pequeño rectángulo en la boquilla
		water_particles.emission_rect_extents = Vector2(3, 6)
		
		# Posición inicial en la boquilla de la manguera
		water_particles.position = safe_hose_nozzle_offset
		water_particles.visible = true  # Visible al inicio (manguera equipada)
		
		# Sincronizar sprite del agua
		if water_jet_sprite:
			water_jet_sprite.position = safe_hose_nozzle_offset
			water_jet_sprite.rotation = 0.0
		
		print("Partículas de agua creadas automáticamente")
	else:
		# Actualizar configuración para mayor alcance
		water_particles.emitting = false
		water_particles.visible = true  # Visible al inicio
		water_particles.lifetime = 1.2
		water_particles.initial_velocity_min = 300.0
		water_particles.initial_velocity_max = 550.0
		water_particles.gravity = Vector2(0, 150)
		water_particles.damping_min = 8.0
		water_particles.damping_max = 15.0
		water_particles.spread = 20.0
		water_particles.amount = 120
		water_particles.scale_amount_min = 4.0
		water_particles.scale_amount_max = 8.0
		water_particles.color = Color(0.2, 0.6, 1.0, 0.9)
		water_particles.emission_rect_extents = Vector2(3, 6)
		water_particles.position = safe_hose_nozzle_offset
		
		# Sincronizar sprite del agua
		if water_jet_sprite:
			water_jet_sprite.position = safe_hose_nozzle_offset
			water_jet_sprite.rotation = 0.0

func _physics_process(delta):
	# No procesar física durante la pausa. El jugador tiene process_mode=ALWAYS 
	# porque necesita recibir input para el menú de pausa, pero NO debe mover 
	# ni animar el personaje mientras el juego está pausado.
	if get_tree().paused:
		return
	# Si el personaje está muerto, no procesar nada
	if not vivo:
		return
	
	# Capturar dirección del movimiento actual para rotar armas dinámicamente
	var input_vector = Input.get_vector("left", "right", "up", "down")
	if input_vector != Vector2.ZERO:
		last_movement_direction = input_vector.normalized()
	
	# Movimiento estándar (mover_personaje en la base maneja dash internamente)
	mover_personaje(delta)

	# Actualizar apuntado antes de procesar la manguera para usar una direccion consistente.
	_update_weapon_orientation(delta)
	
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

	# adicionalmente asegurar que el personaje no salga del viewport
	# (no-op porque clamp_to_viewport está desactivado para el jugador)
	# keep_in_viewport()

func _unhandled_input(event):
	# Si el jugador está muerto, no procesar ningún input (el menú de muerte maneja todo)
	if not vivo:
		return

	# Detectar ESC para pausar el juego
	# Usamos detección directa por keycode como método robusto,
	# sin depender únicamente del mapeo de ui_cancel en el proyecto.
	var is_esc_key: bool = (event is InputEventKey
		and (event as InputEventKey).pressed
		and not (event as InputEventKey).echo
		and ((event as InputEventKey).physical_keycode == KEY_ESCAPE
			or (event as InputEventKey).keycode == KEY_ESCAPE))
	var is_ui_cancel: bool = (InputMap.has_action("ui_cancel") and event.is_action_pressed("ui_cancel"))
	if is_esc_key or is_ui_cancel:
		print("🔵 ESC detectado! is_esc_key=", is_esc_key, " is_ui_cancel=", is_ui_cancel)
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return

	# Detectar tecla V para ataque especial de la manguera (sin cambiar de arma)
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_V:
			_perform_hose_special_attack()
			get_viewport().set_input_as_handled()
			return

	# Detectar cambio de arma por mouse - click derecho
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			last_mouse_button_time = Time.get_ticks_msec()
			switch_weapon()
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				switch_weapon()

func _configure_mouse_combat_bindings():
	"""Asegurar que click derecho esté asignado a switch_weapon."""
	if not InputMap.has_action("switch_weapon"):
		InputMap.add_action("switch_weapon")

	var has_right_click: bool = false
	for existing_event in InputMap.action_get_events("switch_weapon"):
		if existing_event is InputEventMouseButton and existing_event.button_index == MOUSE_BUTTON_RIGHT:
			has_right_click = true
			break

	if not has_right_click:
		var right_click := InputEventMouseButton.new()
		right_click.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("switch_weapon", right_click)

func _toggle_pause_menu():
	"""Activa/desactiva el menú de pausa"""
	# Buscar el PuseMenu por grupo (más robusto que buscar por nombre del nodo padre)
	var pause_menus = get_tree().get_nodes_in_group("pause_menu_ui")
	var pause_menu: Node = null
	
	# Si hay varios (level1 tiene dos instancias), preferir el que esté en un nodo llamado MenusLayer
	for pm in pause_menus:
		if pm.get_parent() and pm.get_parent().name == "MenusLayer":
			pause_menu = pm
			break
	# Fallback: usar el primero que se encuentre
	if not pause_menu and pause_menus.size() > 0:
		pause_menu = pause_menus[0]
	
	if not pause_menu:
		push_warning("⚠️ PuseMenu no encontrado en ningún nivel (falta instanciarlo en la escena)")
		return
	
	# Obtener el DeathMenu del mismo padre para no pausar durante el game over
	var menu_container = pause_menu.get_parent()
	var death_menu = menu_container.get_node_or_null("DeathMenu") if menu_container else null
	if not death_menu:
		death_menu = get_tree().root.find_child("DeathMenu", true, false)
	
	# No permitir pausar si hay pantalla de muerte activa
	if death_menu and death_menu.visible:
		return
	
	# Alternar pausa
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	# Mostrar/ocultar el contenedor (CanvasLayer / MenusLayer)
	if menu_container:
		menu_container.visible = is_paused
	
	# Mostrar/ocultar el menú
	pause_menu.visible = is_paused
	
	# Ocultar el DeathMenu por si acaso
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
	
	# No procesar inputs si está en ataque especial
	if is_performing_special_attack:
		return
	
	# Intercambiar arma con Q
	if Input.is_action_just_pressed("ui_focus_next"):
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
		# Reproducir sonido de roll
		_play_dash_sound()
# SISTEMA DE ORIENTACIÓN DE ARMAS
# ============================================

func _update_weapon_orientation(delta: float):
	"""Actualiza la posición y rotación de las armas hacia la posición del mouse"""
	# No actualizar orientación si está en ataque especial
	if is_performing_special_attack:
		return
	
	# Obtener direccion objetivo hacia el mouse
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	var target_direction = current_aim_direction
	
	# En zona cercana mantenemos la ultima direccion para evitar "temblores".
	# Si está dentro del deadzone Y hay movimiento, usar la dirección del movimiento  
	if to_mouse.length() >= aim_deadzone_px:
		target_direction = to_mouse.normalized()
	elif last_movement_direction != Vector2.ZERO:
		# Si el mouse está quieto pero hay movimiento, girar hacia la dirección del movimiento
		target_direction = last_movement_direction

	# Suavizado exponencial estable por frame rate.
	var blend = 1.0 - exp(-aim_smoothing_speed * delta)
	current_aim_direction = current_aim_direction.lerp(target_direction, blend).normalized()
	if current_aim_direction == Vector2.ZERO:
		current_aim_direction = target_direction

	var direction = current_aim_direction
	
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
	"""Orienta el hacha según la dirección del mouse con volteo visual"""
	var base_offset = 50.0  # Distancia desde el centro del personaje
	
	# Calcular posición del hacha alrededor del personaje
	var axe_position = axe_pivot_base_position + direction * base_offset + Vector2(0, 10.0) + axe_pivot_extra_offset

	if axe_pivot:
		axe_pivot.position = axe_position
	
	# Voltear el hacha por lado, pero corrigiendo el offset angular
	# para que la punta siempre apunte al objetivo.
	var facing_right := direction.x > 0.0
	axe_sprite.scale.x = abs(axe_base_scale.x)
	axe_sprite.scale.y = abs(axe_base_scale.y) * (1.0 if facing_right else -1.0)
	
	# El offset cambia según el espejo para mantener la punta alineada.
	var angle_offset := PI / 2 if facing_right else -PI / 2
	if axe_pivot:
		axe_pivot.rotation = angle + angle_offset
		axe_sprite.rotation = 0.0
	else:
		axe_sprite.rotation = angle + angle_offset
	
	# Mantener arma siempre delante del personaje para evitar cambios molestos de profundidad.
	if axe_pivot:
		axe_pivot.z_index = 0
		axe_pivot.show_behind_parent = false
	else:
		axe_sprite.z_index = 0
		axe_sprite.show_behind_parent = false

func _orient_hose(direction: Vector2, angle: float):
	"""Orienta la manguera según la dirección del mouse con volteo visual"""
	# Mantener pivote fijo cerca de la mano para que no "orbite" alrededor del cuerpo.
	var hose_position = hose_pivot_base_position + hose_pivot_extra_offset

	if hose_pivot:
		hose_pivot.position = hose_position
	
	# Aplicar volteo visual según la dirección horizontal
	hose_sprite.scale.x = abs(hose_base_scale.x)
	hose_sprite.scale.y = abs(hose_base_scale.y) * (1.0 if direction.x > 0 else -1.0)
	
	# Rotar la manguera para que apunte en la dirección de movimiento
	if hose_pivot:
		hose_pivot.rotation = angle
		hose_sprite.rotation = 0.0
	else:
		hose_sprite.rotation = angle
	
	# Mantener arma siempre delante del personaje para evitar cambios molestos de profundidad.
	if hose_pivot:
		hose_pivot.z_index = 0
		hose_pivot.show_behind_parent = false
	else:
		hose_sprite.z_index = 0
		hose_sprite.show_behind_parent = false
	
	# Actualizar también la dirección de las partículas de agua si están activas
	if water_particles:
		# Posicionar las partículas en la punta real de la manguera segun rotacion actual.
		var nozzle_offset = hose_nozzle_offset.rotated(angle)
		water_particles.position = nozzle_offset
		water_particles.direction = direction
		
		# Sincronizar sprite del agua para que siga la misma posición y rotación
		if water_jet_sprite:
			water_jet_sprite.position = nozzle_offset
			# Sumar PI/2 para compensar la orientación natural del sprite (dibujado verticalmente)
			water_jet_sprite.rotation = angle + PI/2
			
			# Usar flip_h para volteo horizontal según dirección del personaje
			water_jet_sprite.flip_h = direction.x < 0

# ============================================
# SISTEMA DE INTERCAMBIO DE ARMAS
# ============================================

func aumentar_resistencia_pulmonar() -> void:
	"""Gato nivel 1: +5% de vida_maxima (más resistencia al humo)"""
	vida_maxima = vida_maxima * 1.05
	vida_actual = min(vida_actual, vida_maxima)
	emit_signal("vida_cambiada", vida_actual, vida_maxima)

func mejorar_manguera() -> void:
	"""Gato nivel 2: la manguera consume un 10% menos de agua por segundo"""
	hose_drain_rate = hose_drain_rate * 0.90
	print("💧 hose_drain_rate reducido a: ", hose_drain_rate)
	print("💨 Resistencia pulmonar aumentada! Nueva vida máxima: ", vida_maxima)

func switch_weapon():
	"""Cambio de armas deshabilitado - solo manguera disponible"""
	# El jugador siempre usa la manguera
	# El ataque V es un ataque especial de la manguera
	print("⚠️ Cambio de arma deshabilitado - Solo manguera disponible")
	
	# Emitir señal
	emit_signal("weapon_switched", current_weapon)

func _update_weapon_visuals():
	"""Actualiza los visuales según el arma equipada"""
	var is_axe_equipped = (current_weapon == Weapon.AXE)
	var is_hose_equipped = (current_weapon == Weapon.HOSE)
	
	if axe_sprite:
		axe_sprite.visible = is_axe_equipped
	if hose_sprite:
		hose_sprite.visible = is_hose_equipped
	if water_particles:
		water_particles.visible = is_hose_equipped
		if not is_hose_equipped:
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
	
	# Activar sprite del agua y su animación
	if water_jet_sprite:
		water_jet_sprite.visible = true
		water_jet_sprite.frame = 0  # Empezar desde el primer frame
		water_jet_sprite.play("agua_inf")
		print("✓ Animación de agua iniciada (se mantendrá en último frame)")
	
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
	
	# Desactivar sprite del agua
	if water_jet_sprite:
		water_jet_sprite.stop()
		water_jet_sprite.frame = 0  # Resetear al primer frame
		water_jet_sprite.visible = false

func _update_hose(delta):
	"""Actualiza el sistema de manguera mientras está activa"""
	# Consumir carga de agua
	reduce_hose_charge(hose_drain_rate * delta)
	
	# Control de sonido de agua (repetir mientras esté activo)
	if is_using_hose:
		hose_water_timer -= delta
		if hose_water_timer <= 0.0:
			_play_hose_water_sound()
			hose_water_timer = hose_water_interval
	
	# Actualizar dirección de la manguera según hacia dónde mira el personaje
	_update_hose_direction()
	
	# Detectar y apagar fuego con el daño calculado
	_detect_and_extinguish_fire(water_pressure * delta)
	
	# SI LLEGA A 0: Bloqueo inmediato
	if hose_charge <= 0:
		hose_charge = 0
		manguera_bloqueada = true
		_play_hose_empty_sound()
		_deactivate_hose()
		print("⚠️ Manguera agotada. Esperando recarga al 20%...")

func _update_hose_direction():
	"""Actualiza la dirección de la manguera hacia la posición del mouse"""
	var direction = current_aim_direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	var angle = direction.angle()
	var range_distance = hose_range * tile_size / 2.0
	
	# Actualizar posición y rotación del área de colisión
	if hose_area and hose_area.get_child_count() > 0:
		var collision = hose_area.get_child(0)
		collision.position = direction * range_distance
		collision.rotation = angle
	
	# Actualizar dirección del raycast
	if hose_raycast:
		hose_raycast.target_position = direction * hose_range * tile_size

func _detect_and_extinguish_fire(water_amount: float):
	"""Detecta y apaga el fuego en el área de la manguera"""
	# Obtener todas las áreas que están siendo alcanzadas por el agua
	if hose_area:
		var overlapping_areas = hose_area.get_overlapping_areas()
		var overlapping_bodies = hose_area.get_overlapping_bodies()
		
		# Procesar áreas (fuego como Area2D)
		for area in overlapping_areas:
			_try_extinguish_fire(area, water_amount)
		
		# Procesar cuerpos (fuego como cuerpo físico)
		for body in overlapping_bodies:
			_try_extinguish_fire(body, water_amount)
	
	# MÉTODO ADICIONAL: Búsqueda por distancia para el jefe
	# Esto asegura que el agua detecte al jefe incluso si las colisiones no funcionan
	var jefe = get_tree().current_scene.find_child("jefe", true, false)
	if jefe and jefe != self:
		var distancia = global_position.distance_to(jefe.global_position)
		var rango_seguro = hose_range * tile_size if hose_range and tile_size else 300
		
		if distancia <= rango_seguro:
			# Verificar que está en la dirección del apunte
			var dir_al_jefe = (jefe.global_position - global_position).normalized()
			var productos_punto = dir_al_jefe.dot(current_aim_direction.normalized())
			
			if productos_punto > 0.3:  # Dentro de ~70 grados del apunte
				_try_extinguish_fire(jefe, water_amount)

func _try_extinguish_fire(target, water_amount: float):
	"""Intenta apagar un fuego"""
	if not target:
		return
	
	# IMPORTANTE: No atacar al propio jugador
	if target == self or target.is_in_group("player") or target.is_in_group("player_main"):
		return
	
	# Aplicar agua o daño a cualquier objetivo compatible (fuego, enemigos, etc.)
	if target.has_method("apply_water"):
		target.apply_water(water_amount)
		print("💧 Agua aplicada a ", target.name, ": ", water_amount)
	elif target.has_method("take_damage"):
		target.take_damage(water_amount)
		print("💧 Daño por agua a ", target.name, ": ", water_amount)
	elif target.has_method("extinguish"):
		target.extinguish()
		print("🔥 Fuego extinguido: ", target.name)
	elif target.is_in_group("Fire"):
		if target.has_method("queue_free"):
			target.queue_free()
			print("🔥 Proyectil de fuego destruido")
		else:
			print("⚠️ Objetivo en grupo Fire pero sin métodos: ", target.name)

# ============================================
# SISTEMA DE MUERTE DEL JUGADOR
# ============================================
func take_damage(amount: float) -> void:
	"""Recibe daño de enemigos - usa el sistema de vida heredado"""
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

func perder_oxigeno(cantidad: float) -> void:
	"""Pierde oxígeno sin disparar animación de daño - solo reduce vida"""
	if not vivo:
		return
	
	vida_actual = max(0.0, vida_actual - cantidad)
	emit_signal("vida_actualizada", vida_actual)
	print("💨 Oxígeno: ", vida_actual)

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

		# Mostrar y reproducir animación del ataque "AtaqueAxeDer"
		if axe_sprite:
			# Ocultar el sprite principal del personaje
			if character_sprite:
				character_sprite.visible = false
			
			axe_sprite.visible = true
			# Aplicar flip si el personaje apunta hacia la izquierda
			axe_sprite.flip_h = last_direction.x < 0
			
			if axe_sprite.sprite_frames and axe_sprite.sprite_frames.has_animation("AtaqueAxeDer"):
				axe_sprite.play("AtaqueAxeDer")
				print("✓ Animación AtaqueAxeDer iniciada")
			else:
				_animate_axe_swing()
		elif animation_player and animation_player.has_animation("axe_attack"):
			animation_player.play("axe_attack")
		else:
			_animate_axe_swing()
		
		emit_signal("attack_performed")
		
		await get_tree().create_timer(0.1).timeout
		_perform_axe_attack()
		
		await get_tree().create_timer(0.2).timeout
		if axe_hitbox:
			axe_hitbox.monitoring = false

		# Ocultar el sprite del ataque y restaurar el personaje principal
		if axe_sprite:
			axe_sprite.visible = false
			axe_sprite.flip_h = false  # Resetear flip
			axe_sprite.stop()
			
			# Restaurar el sprite principal del personaje
			if character_sprite:
				character_sprite.visible = true

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

func _perform_hose_special_attack():
	"""Ataque especial de la manguera - solo animación sin cambiar de arma"""
	# Evitar ejecutar si ya está en ataque especial
	if is_performing_special_attack:
		return
	
	# Solo funciona si está usando la manguera
	if current_weapon != Weapon.HOSE:
		return
	
	# Activar flag de ataque especial para evitar rotación
	is_performing_special_attack = true
	
	# Guardar escala original del sprite PRIMERO, antes de hacer cualquier cambio
	if not character_sprite:
		is_performing_special_attack = false
		return
	
	var original_scale = character_sprite.scale
	
	# Ocultar la manguera durante el ataque
	if hose_sprite:
		hose_sprite.visible = false
	if hose_pivot:
		hose_pivot.visible = false
	
	# Aumentar escala una sola vez para compensar diferencia de tamaño de imágenes del ataque
	character_sprite.scale = original_scale * 2.5
	
	if character_sprite.sprite_frames:
		# Determinar la animación correcta según la dirección
		var attack_animation = "AtaqueAxeDer"
		if last_direction.x < 0:
			# Mirando a la izquierda - intentar usar AtaqueAxeIzq
			if character_sprite.sprite_frames.has_animation("AtaqueAxeIzq"):
				attack_animation = "AtaqueAxeIzq"
			else:
				# Si no existe, usar la derecha con flip
				character_sprite.flip_h = true
		else:
			# Mirando a la derecha - asegurar flip desactivado
			character_sprite.flip_h = false
		
		if character_sprite.sprite_frames.has_animation(attack_animation):
			# Detener primero cualquier animación anterior
			character_sprite.stop()
			# Ahora reproducir la nueva
			character_sprite.play(attack_animation)
	
	# NO consumir agua - ataque gratuito
	
	# Esperar a que termine la animación (más tiempo para verla completa)
	await get_tree().create_timer(0.7).timeout
	
	# Hacer daño a enemigos en el área
	if axe_hitbox:
		axe_hitbox.monitoring = true
		var overlapping_bodies = axe_hitbox.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body != self and not body.is_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(axe_damage if axe_damage != null else 5)
		axe_hitbox.monitoring = false
	
	# Restaurar sprite del personaje a idle
	if character_sprite:
		character_sprite.scale = original_scale  # Restaurar escala original
		character_sprite.flip_h = false  # Restaurar orientación normal
		character_sprite.play("AxelIdleFrDer")
	
	# Mostrar la manguera de nuevo
	if hose_sprite:
		hose_sprite.visible = true
	if hose_pivot:
		hose_pivot.visible = true
	
	# Desactivar flag de ataque especial
	is_performing_special_attack = false

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
	# Si el hit llegó a un Area2D/child, intentar subir al dueño real del daño.
	if target and not target.has_method("take_damage") and target.get_parent():
		var parent_target = target.get_parent()
		if parent_target:
			target = parent_target

	# Ignorar al propio jugador - no atacarse a sí mismo
	if target == self or target.is_in_group("player"):
		return
	
	# Parry de bolas de fuego - destruir proyectiles
	var is_fire_projectile: bool = target.is_in_group("Fire") and (target.has_method("apply_water") or target.has_method("extinguish"))
	if is_fire_projectile:
		if target.has_method("queue_free"):
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
		if target.is_in_group("hellhound"):
			# HellHound distingue fuente de daño para animaciones específicas.
			target.take_damage(safe_axe_damage, &"hacha")
		else:
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
		# Procesar el área directamente solo si es bola de fuego.
		if area.is_in_group("Fire"):
			_process_attack_target(area)
		elif area.get_parent():
			_process_attack_target(area.get_parent())

# Getters auxiliares
func is_parrying() -> bool:
	return current_axe_state == AxeState.PARRYING

func is_attacking() -> bool:
	return current_axe_state == AxeState.ATTACKING

func can_use_hose() -> bool:
	return hose_charge > 0.0 and not manguera_bloqueada

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
	
	# Detectar si hay enemigos o fuego activos con un intervalo (no cada frame)
	oxygen_scan_timer -= delta
	if oxygen_scan_timer <= 0.0:
		oxygen_scan_timer = oxygen_scan_interval
		had_enemies_or_fire = (
			get_tree().get_first_node_in_group("enemy") != null
			or get_tree().get_first_node_in_group("minion") != null
			or get_tree().get_first_node_in_group("Fire") != null
		)
	
	var has_enemies_or_fire = had_enemies_or_fire
	
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
	
	# Si hay enemigos o fuego: consumir oxígeno (-0.5 por segundo) SIN animación de daño
	if has_enemies_or_fire:
		perder_oxigeno(oxygen_loss_rate * delta)
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
		if footstep_debug_logs:
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

func _setup_dash_sound_system():
	"""Inicializa el sistema de sonidos de dash/roll"""
	dash_sound_player = AudioStreamPlayer.new()
	# Usar bus por defecto si "Master" no existe
	if AudioServer.get_bus_index("Master") >= 0:
		dash_sound_player.bus = "Master"
	dash_sound_player.volume_db = dash_sound_volume_db
	add_child(dash_sound_player)
	print("🎬 Sistema de sonidos de dash/roll inicializado")

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

func _play_dash_sound():
	"""Reproduce el sonido de roll cuando hace un dash"""
	if dash_sound_player and dash_sound:
		dash_sound_player.stream = dash_sound
		dash_sound_player.volume_db = dash_sound_volume_db
		dash_sound_player.play()
