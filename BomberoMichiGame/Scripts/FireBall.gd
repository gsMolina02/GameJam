extends Area2D

@export var debug_min_visible_time := 0.5
var speed = 600
var direction = Vector2.ZERO
var _age := 0.0
@export var debug_radius := 14.0

func _ready():
	# This timer will delete the fireball if it exists for too long.
	var timer = Timer.new()
	timer.wait_time = 10  # Aumentado a 10 segundos para más recorrido
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	print_debug("FireBall ready at global:", global_position, "parent:", get_parent())
	_age = 0.0

func _physics_process(delta):
	position += direction.normalized() * speed * delta
	_age += delta
	if _age < debug_min_visible_time:
		print_debug("FireBall moving frame age:", _age, "pos:", global_position, "dir:", direction)
	# ensure we print debug info in early frames

func set_direction(dir):
	direction = dir

func _on_body_entered(body):
	# Assuming the player character is in the "player" group
	if body.is_in_group("player"):
		# Here you can add logic to damage the player
		pass
	# The fireball should be destroyed on impact with anything other than another enemy
	if not body.is_in_group("enemy"):
		# Respect minimum visible time during debug so projectiles don't vanish immediately
		if _age < debug_min_visible_time:
			return
		queue_free()
