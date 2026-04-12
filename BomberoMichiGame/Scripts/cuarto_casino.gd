extends Node2D

func _ready():
	print("🏠 Casino Boss Level cargado")
	
	# Esperar un frame para que todo esté listo
	await get_tree().process_frame
	
	# Buscar al jugador
	var jugador = get_tree().get_first_node_in_group("player_main")
	if jugador:
		print("  Jugador encontrado")
		# Restaurar estado (vida y agua)
		GameManager.restaurar_estado_jugador(jugador)
		# Posicionar en la puerta correcta
		GameManager.posicionar_jugador_en_puerta(jugador, self)
	else:
		push_warning("⚠️ No se encontró jugador en Casino Boss Level")
