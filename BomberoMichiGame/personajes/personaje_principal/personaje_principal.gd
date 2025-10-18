extends "res://personajes/personaje_base.gd"

@export var min_x := -1000.0
@export var max_x := 1000.0
@export var min_y := -1000.0
@export var max_y := 1000.0
@export var enforce_bounds := false # set true to enable min/max clamping

func _ready():
	# Desactivar clamp al viewport para el jugador (una sola vez)
	clamp_to_viewport = false


func _physics_process(delta):
	mover_personaje(delta)

	# Limitar posición dentro del campo definido (se puede desactivar con enforce_bounds)
	var x = global_position.x
	var y = global_position.y
	if enforce_bounds:
		var minx = (min_x if min_x != null else -1000.0)
		var maxx = (max_x if max_x != null else 1000.0)
		var miny = (min_y if min_y != null else -1000.0)
		var maxy = (max_y if max_y != null else 1000.0)
		x = clamp(global_position.x, float(minx), float(maxx))
		y = clamp(global_position.y, float(miny), float(maxy))

	# Debug: imprimir cuando el jugador intenta moverse horizontalmente
	if abs(velocity.x) > 0:
		if enforce_bounds:
			print_debug("Player attempt move -> pos:", global_position, "vel.x:", velocity.x, "clamped_x:", x, "bounds_enabled")
		else:
			print_debug("Player attempt move -> pos:", global_position, "vel.x:", velocity.x, "clamped_x:", x, "(bounds disabled)")

	global_position = Vector2(x, y)

	# adicionalmente asegurar que el personaje no salga del viewport
	# (no-op porque clamp_to_viewport está desactivado para el jugador)
	# keep_in_viewport()


func keep_in_viewport(_margin := 0):
	# No-op para el jugador: permitimos moverse por todo el campo de batalla
	pass
