extends Area2D

@export var radius := 12.0
@export var color := Color(1.0, 0.45, 0.0)

@export var speed := 800
@export var lifetime := 10.0
var velocity := Vector2.ZERO
var damage := 1.0  # Daño base, se ajustará según el shooter

var shooter: Node = null
@export var grace_time := 0.3  # Aumentado para dar más tiempo antes de colisionar
var _age := 0.0

func _ready():
	# IMPORTANTE: Configurar capas de colisión
	collision_layer = 2  # Capa 2 para ser detectado por el Hitbox del jugador (mask=2)
	collision_mask = 1   # Detectar capa 1 (jugador)
	
	# DEBUG: Imprimir configuración
	print("🔥 FIREBALL READY:")
	print("   - collision_layer:", collision_layer)
	print("   - collision_mask:", collision_mask)
	print("   - position:", global_position)
	
	if has_node("CollisionShape2D"):
		pass
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	# Agregar al grupo "Fire" para que la manguera pueda detectarla
	add_to_group("Fire")
	add_to_group("enemy")
	# Los grupos de ataque se asignarán después cuando se conozca el shooter

func _enter_tree():
	# Cuando se agrega al árbol, verificar y asignar grupos de ataque
	_assign_attack_groups()

func _assign_attack_groups():
	"""Asignar grupos de ataque según el tipo de shooter"""
	# Estos grupos serán detectados por el Hitbox del jugador
	if shooter:
		if shooter.is_in_group("minion"):
			add_to_group("ataque_minion")
			print_debug("Fireball asignada al grupo: ataque_minion")
		elif shooter.is_in_group("boss"):
			add_to_group("ataque_jefe")
			print_debug("Fireball asignada al grupo: ataque_jefe")
		else:
			add_to_group("ataque_enemigo")
			print_debug("Fireball asignada al grupo: ataque_enemigo")
	else:
		# Si no hay shooter definido, asumir ataque genérico
		add_to_group("ataque_enemigo")
		print_debug("Fireball sin shooter, asignada al grupo: ataque_enemigo")

func _physics_process(delta):
	position += velocity * delta
	_age += delta
	if _age >= lifetime:
		queue_free()

func _draw():
	draw_circle(Vector2.ZERO, radius, color)

func set_direction(dir):
	velocity = dir.normalized() * speed

func set_shooter(s):
	shooter = s
	# Cuando se establece el shooter, asignar grupos y daño
	_assign_attack_groups()
	_assign_damage()

func _assign_damage():
	"""Asignar el daño según el tipo de shooter"""
	if shooter:
		if shooter.is_in_group("minion"):
			damage = 0.5  # Minions hacen 0.5 de daño
			print_debug("Fireball de minion: daño = 0.5")
		elif shooter.is_in_group("boss"):
			damage = 1.0  # Jefe hace 1 de daño
			print_debug("Fireball de jefe: daño = 1.0")
		else:
			damage = 1.0  # Daño por defecto
	else:
		damage = 1.0  # Daño por defecto si no hay shooter

func _on_body_entered(body):
	# SIEMPRE ignorar al shooter (el que lanzó la bola)
	if body == shooter:
		return
	
	# Durante el grace_time, ignorar TODAS las colisiones para evitar destrucción prematura
	if _age < grace_time:
		return
	
	# Ignorar colisiones con otros enemigos (minions, jefe, etc.)
	if body.is_in_group("enemy") or body.is_in_group("boss") or body.is_in_group("minion"):
		return
	
	# If we hit the player
	if body.is_in_group("player") or body.is_in_group("player_main"):
		# Verificar si el jugador está atacando (parry)
		if body.has_method("is_attacking") and body.is_attacking():
			print_debug("Fireball PARRIED! Player was attacking!")
			queue_free()
			return
		
		# Aplicar daño según el tipo de bola (minion = 0.5, jefe = 1.0)
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print_debug("🔥 Fireball hit player, dealing ", damage, " damage")
		elif body.has_method("recibir_dano"):
			# Ahora recibir_dano acepta float, no necesitamos redondear
			body.recibir_dano(damage)
			print_debug("🔥 Fireball hit player, dealing ", damage, " damage")
		queue_free()
	# Destroy fireball on collision with walls/obstacles (not enemies)
	else:
		queue_free()


func _on_area_entered(area):
	"""Detectar colisiones con áreas (como el hacha del bombero)"""
	# Durante el grace_time, ignorar TODAS las colisiones de área
	if _age < grace_time:
		return
	
	# Ignorar si el área pertenece al shooter
	if area.get_parent() == shooter:
		return
	
	# Ignorar áreas de enemigos
	if area.is_in_group("enemy") or area.is_in_group("boss") or area.is_in_group("minion"):
		return
	
	# Si el área es el arma del jugador (hacha), es un parry exitoso
	if area.is_in_group("player_weapon"):
		print_debug("Fireball parried by axe! Destroyed!")
		queue_free()
		return
	
	# Si el área pertenece al jugador y está atacando, es un parry
	if area.get_parent() and area.get_parent().is_in_group("player"):
		print_debug("Fireball parried by player weapon!")
		queue_free()
		return
	
	# También verificar si el área misma está en el grupo del jugador
	# Si colisiona con el área del jugador (Hitbox u otra Area2D), aplicar daño al CharacterBody2D padre
	if area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player_main")):
		print_debug("Fireball hit player area! Applying damage via area collision")
		# Intentar aplicar daño directamente al padre del área (CharacterBody2D)
		var target = null
		if area.get_parent() and area.get_parent().has_method("recibir_dano"):
			target = area.get_parent()
		elif area.has_method("get_parent") and area.get_parent() and area.get_parent().has_method("recibir_dano"):
			target = area.get_parent()
		# Fallback: si el area mismo tiene un parent que es CharacterBody2D con take_damage
		if not target and area.get_parent() and area.get_parent().has_method("take_damage"):
			target = area.get_parent()
		# Aplicar daño
		if target:
			if target.has_method("recibir_dano"):
				target.recibir_dano(damage)
				print_debug("🔥 Fireball applied damage to player via area parent:", damage)
			elif target.has_method("take_damage"):
				target.take_damage(damage)
				print_debug("🔥 Fireball applied damage (take_damage) to player via area parent:", damage)
			else:
				print_debug("Fireball couldn't apply damage: no target method")
		else:
			# Si no encontramos target, al menos destruir la fireball
			print_debug("Fireball hit player area but no target found. Destroying fireball.")
		queue_free()
		return


# Métodos para ser destruida por la manguera del bombero
func apply_water(_amount: float) -> void:
	"""Destruir la bola de fuego cuando recibe agua"""
	print_debug("Fireball extinguished by water!")
	queue_free()


func extinguish() -> void:
	"""Método alternativo para extinguir"""
	queue_free()


func take_damage(_amount: float) -> void:
	"""Recibir daño (de hacha u otros ataques)"""
	queue_free()
