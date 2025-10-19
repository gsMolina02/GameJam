extends "res://personajes/personaje_base.gd"

func _physics_process(delta):
	mover_personaje(delta)

func _ready():
	# Llama a la inicialización del padre (conexión Hitbox, init vida, etc.)
	super._ready()
	# Añadir al grupo para que HUD/etc. nos encuentre
	add_to_group("player_main")
	# (No necesitas emitir la señal aquí porque la base ya la emite al inicializar vida)
