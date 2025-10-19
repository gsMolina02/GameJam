
extends Node2D

func break_with_effect():
	# Aquí puedes agregar efectos visuales, partículas, sonido, etc.
	queue_free()

func take_damage(_amount):
	break_with_effect()

func apply_water(_amount):
	break_with_effect()
