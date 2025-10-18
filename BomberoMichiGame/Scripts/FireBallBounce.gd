extends RigidBody2D

@export var speed := 600
var direction := Vector2.ZERO

func _ready():
	# Auto-free after some time
	var t = Timer.new()
	t.wait_time = 12
	t.one_shot = true
	t.connect("timeout", Callable(self, "queue_free"))
	add_child(t)
	t.start()

func _physics_process(_delta):
	# Ensure linear velocity aligns with direction
	if direction != Vector2.ZERO:
		linear_velocity = direction.normalized() * speed

func set_direction(dir: Vector2):
	direction = dir
	linear_velocity = direction.normalized() * speed

func _on_body_entered(body):
	# If it hits the player, damage and destroy
	if body.is_in_group("player"):
		# TODO: damage the player
		queue_free()
