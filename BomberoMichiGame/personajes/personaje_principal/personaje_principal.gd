extends "res://personajes/personaje_base.gd"

@export var min_x := -1000.0
@export var max_x := 1000.0
@export var min_y := -1000.0
@export var max_y := 1000.0

func _physics_process(delta):
	mover_personaje(delta)

	# Limitar posición dentro del campo definido
	var minx = (min_x if min_x != null else -1000.0)
	var maxx = (max_x if max_x != null else 1000.0)
	var miny = (min_y if min_y != null else -1000.0)
	var maxy = (max_y if max_y != null else 1000.0)
	var x = clamp(global_position.x, float(minx), float(maxx))
	var y = clamp(global_position.y, float(miny), float(maxy))
	global_position = Vector2(x, y)

	# adicionalmente asegurar que el personaje no salga del viewport
	keep_in_viewport()
