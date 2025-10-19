extends Node2D

func _ready():
	print("🏠 Cuarto 1 cargado")
	
	# Esperar un frame para que todo esté listo
	await get_tree().process_frame
	
	# IMPORTANTE: Verificar y forzar la inicialización del RoomManager
	_inicializar_room_manager()
	
	# Buscar al jugador
	var jugador = get_tree().get_first_node_in_group("player_main")
	if jugador:
		print("  Jugador encontrado")
		# Restaurar estado (vida y agua)
		GameManager.restaurar_estado_jugador(jugador)
		# Posicionar en la puerta correcta
		GameManager.posicionar_jugador_en_puerta(jugador, self)
	else:
		push_warning("⚠️ No se encontró jugador en Cuarto1")

func _inicializar_room_manager():
	"""Inicializa y verifica el RoomManager"""
	print("🔍 Buscando RoomManager en Cuarto1...")
	
	# Buscar el nodo RoomManager (puede llamarse "Node" o "RoomManager")
	var room_manager_node = null
	
	# Primero buscar en el grupo
	var room_managers = get_tree().get_nodes_in_group("room_manager")
	if room_managers.size() > 0:
		room_manager_node = room_managers[0]
		print("  ✅ RoomManager encontrado en grupo")
	else:
		# Buscar manualmente por el script
		print("  ⚠️ RoomManager no está en el grupo, buscando por script...")
		for child in get_children():
			if child.get_script() and child.get_script().resource_path.ends_with("room_manager.gd"):
				room_manager_node = child
				# Agregar al grupo
				child.add_to_group("room_manager")
				print("  ✅ RoomManager encontrado y agregado al grupo:", child.name)
				break
	
	if room_manager_node == null:
		push_error("❌ NO SE ENCONTRÓ RoomManager en Cuarto1!")
		return
	
	# Verificar propiedades del RoomManager
	print("  📊 Configuración del RoomManager:")
	print("    - Vida sala:", room_manager_node.vida_habitacion, "/", room_manager_node.vida_maxima_habitacion)
	print("    - Perdiendo vida:", room_manager_node.perdiendo_vida)
	print("    - Velocidad pérdida:", room_manager_node.velocidad_perdida)
	print("    - Enemigos requeridos:", room_manager_node.enemigos_requeridos)
	print("    - Fuegos requeridos:", room_manager_node.fuegos_requeridos)
	
	# Verificar que esté en _process
	if not room_manager_node.perdiendo_vida:
		push_warning("⚠️ RoomManager NO está perdiendo vida! Activando...")
		room_manager_node.perdiendo_vida = true
	
	# Contar enemigos y fuegos actuales
	var minions_count = get_tree().get_nodes_in_group("minion").size()
	var fuegos_count = get_tree().get_nodes_in_group("fuego").size()
	print("  🔢 Conteo actual:")
	print("    - Minions en escena:", minions_count)
	print("    - Fuegos en escena:", fuegos_count)
