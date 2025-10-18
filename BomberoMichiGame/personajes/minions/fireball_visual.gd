extends Node2D

@export var radius := 12.0
@export var color := Color(1.0, 0.45, 0.0)

@export var speed := 800
@export var lifetime := 3.0

var velocity := Vector2.ZERO
var _life := 0.0

func _physics_process(delta):
    position += velocity * delta
    _life += delta
    if _life >= lifetime:
        queue_free()

func _draw():
    draw_circle(Vector2.ZERO, radius, color)
