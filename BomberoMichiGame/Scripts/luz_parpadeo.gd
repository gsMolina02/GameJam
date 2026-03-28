extends PointLight2D

# Variables para controlar el parpadeo
var energia_base: float = 3.0  # La energía normal de la luz
var variacion_energia: float = 0.8  # Cuánto puede subir o bajar
var tiempo_parpadeo: float = 0.08  # Qué tan rápido parpadea

func _ready():
	# Establecemos la energía inicial
	energy = energia_base

	# Crear el Timer si no existe como hijo
	if not has_node("TimerParpadeo"):
		var timer = Timer.new()
		timer.name = "TimerParpadeo"
		timer.wait_time = tiempo_parpadeo
		timer.timeout.connect(_on_timer_parpadeo_timeout)
		add_child(timer)
		timer.start()
	else:
		# Si ya existe, conectar la señal
		$TimerParpadeo.timeout.connect(_on_timer_parpadeo_timeout)
		$TimerParpadeo.wait_time = tiempo_parpadeo
		$TimerParpadeo.start()

func _on_timer_parpadeo_timeout():
	# Cambiamos la energía a un valor aleatorio cercano a la base
	energy = randf_range(energia_base - variacion_energia, energia_base + variacion_energia)
