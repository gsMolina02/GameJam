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

func _physics_process(delta):
	position += direction.normalized() * speed * delta

func set_direction(dir):
	direction = dir

func _on_body_entered(body):
	# Assuming the player character is in the "player" group
	if body.is_in_group("player"):
		# Here you can add logic to damage the player
		pass
	# The fireball should be destroyed on impact with anything other than another enemy
	if not body.is_in_group("enemy"):
		queue_free()
