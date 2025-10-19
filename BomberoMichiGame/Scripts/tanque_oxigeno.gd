# tanque_oxigeno.gd
extends Area2D

func _ready():
	# Tarea 6.2: Identificar este objeto como "pickup_vida".
	# El script 'player.gd' buscará este grupo.
	add_to_group("pickup_vida")
