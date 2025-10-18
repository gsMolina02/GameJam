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
	# If we hit the player, queue_free this fireball (damage handling added later)
	if body.is_in_group("player"):
		queue_free()
