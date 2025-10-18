extends "res://personajes/personaje_base.gd"

var direccion := Vector2.ZERO
var tiempo_cambio := 0.5
var tiempo_actual := 0.0
var tiempo_disparo := 0.0
var tiempo_desde_disparo := 0.0
var FireballScene: PackedScene = null

func _ready():
	# no se usan disparos en minions ahora
	pass

func mover_personaje(delta):
	tiempo_actual += delta
	if tiempo_actual > tiempo_cambio:
		direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tiempo_actual = 0.0
	velocity = direccion * speed
	move_and_slide()

func _physics_process(delta):
	mover_personaje(delta)

	# Mantener dentro del viewport
	keep_in_viewport()


	
