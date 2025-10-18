extends CharacterBody2D

# Características del personaje
var water_level: float = 100.0  # Nivel de agua actual (100%)
const MAX_WATER: float = 100.0
const WATER_USAGE: float = 5.0   # Cantidad de agua que se gasta por uso
const WATER_REFILL: float = 25.0 # Cantidad de agua que se recupera con extintores

# Configuración de ataques
const WATER_RANGE: int = 3       # Alcance del agua en cuadros
const ATTACK_DAMAGE: int = 10    # Daño base del hacha

# Configuración del dash
const DASH_SPEED: float = 500.0
const DASH_DURATION: float = 0.2
var is_dashing: bool = false
var dash_timer: float = 0.0

# Estado del personaje
var can_attack: bool = true
var is_parrying: bool = false
var current_weapon: String = "axe"  # "axe" o "hose"

func _ready():
	# Inicialización del personaje
	pass

func _physics_process(delta):
	if !is_dashing:
		# Movimiento normal
		handle_movement()
	else:
		# Procesar dash
		process_dash(delta)
	
	# Manejar inputs de armas y habilidades
	handle_weapon_input()
	handle_dash_input()

func handle_movement():
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = direction.normalized()
	
	velocity = direction * 300.0
	move_and_slide()

func handle_weapon_input():
	# Cambiar entre armas
	if Input.is_action_just_pressed("switch_weapon"):
		current_weapon = "hose" if current_weapon == "axe" else "axe"
	
	# Atacar
	if Input.is_action_just_pressed("attack"):
		if current_weapon == "axe":
			axe_attack()
		elif current_weapon == "hose" and water_level > 0:
			water_attack()

func water_attack():
	if water_level >= WATER_USAGE:
		water_level -= WATER_USAGE
		# Implementar la lógica para disparar agua
		# Crear un raycast o área que detecte objetos en WATER_RANGE
		print("Usando agua. Nivel actual: ", water_level)

func axe_attack():
	if can_attack:
		print("¡Ataque con hacha!")
		# Implementar la lógica del ataque con hacha
		# Crear un área de detección frontal para el ataque

func handle_dash_input():
	if Input.is_action_just_pressed("dash") and !is_dashing:
		start_dash()

func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	# Añadir efecto visual de dash aquí

func process_dash(delta):
	if dash_timer > 0:
		dash_timer -= delta
		velocity = velocity.normalized() * DASH_SPEED
		move_and_slide()
	else:
		is_dashing = false

func parry():
	is_parrying = true
	# Implementar la lógica del parry
	# Añadir un timer para la duración del parry
	await get_tree().create_timer(0.5).timeout
	is_parrying = false

func refill_water():
	water_level = min(water_level + WATER_REFILL, MAX_WATER)
	print("¡Agua recargada! Nivel actual: ", water_level)

func _on_hit_box_area_entered(area):
	if area.is_in_group("extinguisher_box"):
		refill_water()
	elif area.is_in_group("enemy") and is_parrying:
		# Lógica de parry exitoso
		print("¡Parry exitoso!")

# Función para el emote (puede ser llamada desde un input o evento)
func play_emote():
	# Implementar la lógica del emote
	print("¡Emote activado!")