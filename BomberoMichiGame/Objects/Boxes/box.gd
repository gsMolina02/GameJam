
extends Node2D

func _ready():
	# Añadir al grupo de cajas de extintor para ser detectadas por el hacha
	add_to_group("ExtinguisherBox")

func break_with_effect():
	# Aquí puedes agregar efectos visuales, partículas, sonido, etc.
	print("Caja de extintor rota!")
	queue_free()

func take_damage(_amount):
	break_with_effect()

func apply_water(_amount):
	break_with_effect()
