extends PointLight2D

# Parámetros para el efecto de destellos de luz entrando desde la salida
@export var energia_base: float = 25.0  # Energía normal de la luz - SUPER BRILLANTE
@export var variacion_energia: float = 5.0  # Puede ir de 20 a 30 para efecto dramático
@export var tiempo_parpadeo: float = 0.12  # Qué tan rápido parpadea
@export var intensidad_destellos: bool = true  # Habilita/deshabilita el efecto

var timer: Timer

func _ready():
	# La energía inicial la definirá el script de la puerta, si existe
	
	# Crear el Timer para los destellos
	timer = Timer.new()
	timer.name = "TimerDestellos"
	timer.wait_time = tiempo_parpadeo
	timer.timeout.connect(_on_timer_destellos)
	add_child(timer)
	timer.start()

func _on_timer_destellos():
	if intensidad_destellos:
		# Cambiar la energía a un valor aleatorio para crear destellos
		energy = randf_range(energia_base - variacion_energia, energia_base + variacion_energia)

func set_parpadeo_speed(speed: float) -> void:
	"""Ajusta la velocidad del parpadeo (valores más bajos = más rápido)"""
	tiempo_parpadeo = speed
	if timer:
		timer.wait_time = speed

func set_energias(base: float, variacion: float) -> void:
	"""Ajusta la energía base y la variación"""
	energia_base = base
	variacion_energia = variacion
	energy = energia_base
