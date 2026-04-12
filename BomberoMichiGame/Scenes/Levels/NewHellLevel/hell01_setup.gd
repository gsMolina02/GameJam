extends Node

# Script helper para asegurar que los nodos de salida existan en hell01.tscn
# Este script se ejecuta al cargar la escena y crea los nodos si no existen

func _ready():
	# Esperar un frame para que la escena esté completamente cargada
	await get_tree().process_frame
	_crear_nodos_salida_si_no_existen()

func _crear_nodos_salida_si_no_existen():
	"""Crea los nodos de salida si no existen en la escena"""
	var root = get_tree().root.get_child(0)  # Nodo raíz del nivel
	
	# Verificar si ya existe la luz de salida
	var luz_salida = root.find_child("luz salida", false, false)
	if not luz_salida:
		print("🔧 Creando PointLight2D 'luz salida'...")
		_crear_luz_salida(root)
	else:
		print("✅ 'luz salida' ya existe")
	
	# Verificar si ya existe el área de salida
	var area_salida = root.find_child("area salida", false, false)
	if not area_salida:
		print("🔧 Creando Area2D 'area salida'...")
		_crear_area_salida(root)
	else:
		print("✅ 'area salida' ya existe")

func _crear_luz_salida(parent: Node):
	"""Crea el PointLight2D para la luz de salida"""
	var luz = PointLight2D.new()
	luz.name = "luz salida"
	luz.position = Vector2(1400, 100)  # Posición por defecto - el usuario puede ajustarla
	luz.energy = 20.0
	luz.enabled = false  # Inactiva hasta que se salve el gato
	parent.add_child(luz)
	print("✨ PointLight2D 'luz salida' creada en posición:", luz.position)

func _crear_area_salida(parent: Node):
	"""Crea el Area2D para la zona de salida"""
	var area = Area2D.new()
	area.name = "area salida"
	area.position = Vector2(1400, 200)  # Posición por defecto - el usuario puede ajustarla
	parent.add_child(area)
	
	# Agregar CollisionShape2D
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(200, 200)  # Tamaño por defecto - el usuario puede ajustarlo
	area.add_child(collision)
	
	# Agregar el script area_salida.gd
	var script = load("res://Scripts/area_salida.gd")
	if script:
		area.set_script(script)
		print("📝 Script 'area_salida.gd' asignado")
	else:
		print("⚠️ No se pudo encontrar 'area_salida.gd'")
	
	print("🚪 Area2D 'area salida' creada en posición:", area.position)
