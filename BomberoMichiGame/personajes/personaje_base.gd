extends CharacterBody2D

@export var speed = 400

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

signal vida_actualizada(nueva_vida)
signal personaje_muerto

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
		# decrement timer
		knockback_remaining -= delta
		velocity = knockback_velocity
		# opcional: reducir gradualmente el knockback
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_strength * delta)
		move_and_slide()
		return

	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
	move_and_slide()

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
	if not vivo:
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
	# Depuración (opcional)
	#print("[Hitbox] ", self.name, "area:", area.name, "groups:", area.get_groups())

	# SOLO procesar fuego/pickups si este personaje es el personaje principal
	if not is_in_group("player_main"):
		return

	# Daño por fuego (grupo 'fuego')
	if area.is_in_group("fuego"):
		# aplicar daño
		recibir_dano(1)
		# calcular dirección desde el centro del fuego hacia el jugador (empujar fuera)
		var dir = (global_position - area.global_position).normalized()
		# si la distancia es 0, empujar hacia arriba por defecto
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		# empuje inmediato para evitar quedar solapado
		global_position += dir * penetration_push
		# establecer knockback
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
		curar(1)
		area.queue_free()
		return
