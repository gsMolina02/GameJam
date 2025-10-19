# LootManager.gd
extends Node

# Tarea 6.2: Precargamos la escena del tanque de oxígeno.
# ¡Revisa que esta ruta sea correcta!
var tanque_oxigeno_scene = preload("res://Scenes/Entities/tanque_oxigeno.tscn")

# Probabilidad de que suelte vida (0.3 = 30%)
@export var probabilidad_drop_vida: float = 0.3

# Generador de números aleatorios
var rng = RandomNumberGenerator.new()

# --- FUNCIÓN PARA CRISTIAN (Minions) ---
# Tu compañero Cristian llamará a esta función desde el script de su minion
# cuando el minion muera.
#
# En su script de Minion, él pondrá:
# func _morir():
#     LootManager.al_morir_minion(self.global_position)
#     queue_free()
#
func al_morir_minion(posicion_muerte: Vector2):
	rng.randomize() # Prepara el dado

	# Lanza el dado (un número float entre 0.0 y 1.0)
	if rng.randf() < probabilidad_drop_vida:

		# ¡Suerte! Creamos el pickup
		var pickup = tanque_oxigeno_scene.instantiate()

		# Lo añadimos a la escena principal
		var escena_actual = get_tree().current_scene
		escena_actual.add_child(pickup)

		# Lo movemos a la posición donde murió el minion
		pickup.global_position = posicion_muerte
