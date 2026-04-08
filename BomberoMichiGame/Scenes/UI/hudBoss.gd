extends Node2D

@onready var barra = $vidaboss  # Tu TextureProgressBar

func _ready():
	# Inicializar la barra
	barra.min_value = 0
	barra.max_value = 100
	barra.value = 100

func actualizar_interfaz(vida_actual: float, vida_maxima: float):
	"""Actualiza la barra de vida del jefe con degradado de rojo"""
	if barra:
		barra.max_value = vida_maxima
		barra.value = vida_actual
		
		# Calcular porcentaje de vida
		var porcentaje = (vida_actual / vida_maxima) * 100.0
		
		# Interpolación: rojo normal → rojo chillón (más saturado y brillante)
		# Cuando tiene 100% vida: rojo oscuro/normal (0.8, 0.1, 0.1)
		# Cuando tiene 0% vida: rojo chillón/brillante (1.0, 0.0, 0.0)
		var factor = 1.0 - (porcentaje / 100.0)  # 0 en 100%, 1 en 0%
		
		var rojo_normal = Color(0.8, 0.1, 0.1, 1)     # Rojo normal
		var rojo_chillon = Color(1.0, 0.0, 0.0, 1)    # Rojo chillón
		
		var color_final = rojo_normal.lerp(rojo_chillon, factor)
		barra.tint_progress = color_final
		
		# Debug opcional
		#print("Vida: ", vida_actual, "/", vida_maxima, " - Porcentaje: ", porcentaje, "% - Color RGB: ", color_final)
