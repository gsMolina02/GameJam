extends Area2D

var speed = 600
var direction = Vector2.ZERO

func _ready():
	# This timer will delete the fireball if it exists for too long.
	var timer = Timer.new()
	timer.wait_time = 10  # Aumentado a 10 segundos para más recorrido
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

	# Marcar como fuego para filtros y depuración
	add_to_group("Fire")

	# Ensure collision signal is connected
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction.normalized() * speed * delta

func set_direction(dir):
	direction = dir

func _on_body_entered(body):
	# If collides with player, kill the player and stop the game for now
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
		else:
			# Fallback: pause the tree
			get_tree().paused = true
	# The fireball should be destroyed on impact with anything other than another enemy
	if not body.is_in_group("enemy"):
		queue_free()

# Permite ser destruida por agua de la manguera
func apply_water(_amount: float) -> void:
	queue_free()

func extinguish() -> void:
	queue_free()
