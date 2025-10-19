extends Area2D

@export var radius := 12.0
@export var color := Color(1.0, 0.45, 0.0)

@export var speed := 800
@export var lifetime := 3.0
var velocity := Vector2.ZERO

var shooter: Node = null
var grace_time := 0.08
var _age := 0.0

func _ready():
	if has_node("CollisionShape2D"):
		pass
	connect("body_entered", Callable(self, "_on_body_entered"))
	# Agregar al grupo "Fire" para que la manguera pueda detectarla
	add_to_group("Fire")
	add_to_group("enemy")

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

func _on_body_entered(body):
	# Ignore initial collisions with shooter for grace_time
	if body == shooter:
		return
	if _age < grace_time and shooter != null:
		return
	# If we hit the player, cause damage and destroy the fireball
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(15.0)  # Las bolas de fuego del jefe causan 15 de daño
			print_debug("Fireball hit player, dealing 15 damage")
		elif body.has_method("die"):
			body.die()
		queue_free()
	# Destroy fireball on collision with other things (except enemies)
	elif not body.is_in_group("enemy"):
		queue_free()


# Métodos para ser destruida por la manguera del bombero
func apply_water(amount: float) -> void:
	"""Destruir la bola de fuego cuando recibe agua"""
	print_debug("Fireball extinguished by water!")
	queue_free()


func extinguish() -> void:
	"""Método alternativo para extinguir"""
	queue_free()


func take_damage(amount: float) -> void:
	"""Recibir daño (de hacha u otros ataques)"""
	queue_free()
