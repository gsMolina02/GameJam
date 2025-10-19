extends Node2D

# Cuarto 1 - Script generado a partir de cuarto_2.gd
# Ajusta posiciones, puertas o lógica de restauración si lo necesitas.

func _ready():
	print("🏠 Cuarto 1 cargado")
	
	# Esperar un frame para que todo esté listo
	await get_tree().process_frame
	
	# Buscar al jugador
	var jugador = get_tree().get_first_node_in_group("player_main")
	if jugador:
		print("  Jugador encontrado")
		# Restaurar estado (vida y agua)
		GameManager.restaurar_estado_jugador(jugador)
		# Posicionar en la puerta correcta (puedes implementar lógica por nombre de cuarto)
		GameManager.posicionar_jugador_en_puerta(jugador, self)
	else:
		push_warning("⚠️ No se encontró jugador en Cuarto1")
