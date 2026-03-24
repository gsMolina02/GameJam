extends CanvasLayer

# Referencia al nodo unificado
@onready var overlay = $OverlaySupervivencia

@export var oxygen_threshold_start = 30.0

func _ready():
	# Asegurarnos de que el efecto empiece en 0
	_aplicar_visuales(0.0)
	print("AsfixiaEffect: Sistema Unificado Listo.")

func update_oxygen(nueva_vida: float):
	var intensidad = 0.0
	
	# Si la vida baja de 30, calculamos intensidad
	# (a 30% -> 0 intensidad | a 0% -> 1 intensidad)
	if nueva_vida <= oxygen_threshold_start:
		intensidad = (oxygen_threshold_start - nueva_vida) / oxygen_threshold_start
	else:
		intensidad = 0.0 # Vida sana = pantalla limpia
	
	_aplicar_visuales(intensidad)

func _aplicar_visuales(i: float):
	if overlay and overlay.material:
		# Esto moverá la barrita de intensidad del shader fusionado
		overlay.material.set_shader_parameter("intensidad", i)
		# Hacemos visible el nodo solo si hay intensidad
		overlay.visible = (i > 0.01)
