extends Node

# Estado del jugador entre escenas
var vida_jugador: int = 3
var agua_jugador: float = 100.0
var puerta_origen: String = ""  # Nombre de la puerta por la que entramos
var offset_spawn: Vector2 = Vector2(50, 0)

# Gatos rescatados
var gatos_rescatados: Array[String] = []

func _ready():
	print("✅ GameManager inicializado")

func guardar_estado_jugador(jugador: Node) -> void:
	print("💾 Guardando estado del jugador...")
	
	# Guardar vida
	if "vida_actual" in jugador:
		vida_jugador = jugador.vida_actual
		print("  Vida guardada:", vida_jugador)
	elif jugador.has_method("get_vida_actual"):
		vida_jugador = jugador.get_vida_actual()
		print("  Vida guardada:", vida_jugador)
	
	# Guardar agua
	if "hose_charge" in jugador:
		agua_jugador = jugador.hose_charge
		print("  Agua guardada:", agua_jugador, "%")

func restaurar_estado_jugador(jugador: Node) -> void:
	print("📥 Restaurando estado del jugador...")
	print("  Vida a restaurar:", vida_jugador)
	print("  Agua a restaurar:", agua_jugador, "%")
	
	# Restaurar vida
	if "vida_actual" in jugador:
		jugador.vida_actual = vida_jugador
		# Emitir señal para que el HUD se actualice
		if jugador.has_signal("vida_actualizada"):
			jugador.emit_signal("vida_actualizada", vida_jugador)
	
	# Restaurar agua
	if "hose_charge" in jugador:
		jugador.hose_charge = agua_jugador
		# Emitir señal para que el HUD se actualice
		if jugador.has_signal("hose_recharged"):
			jugador.emit_signal("hose_recharged", agua_jugador)

func posicionar_jugador_en_puerta(jugador: Node2D, escena: Node) -> void:
	if puerta_origen == "":
		print("ℹ️ Primera vez en esta escena, usar posición por defecto")
		return  # Primera vez, usar posición por defecto
	
	print("📍 Buscando puerta:", puerta_origen)
	
	# Buscar la puerta con el nombre correcto
	var puertas = escena.get_tree().get_nodes_in_group("puertas")
	print("  Puertas encontradas:", puertas.size())
	
	for puerta in puertas:
		print("  Revisando puerta:", puerta.name)
		if puerta.name == puerta_origen:
			# Posicionar al jugador cerca de esa puerta
			jugador.global_position = puerta.global_position + offset_spawn
			print("✅ Jugador posicionado en puerta:", puerta_origen)
			print("  Posición:", jugador.global_position)
			# Limpiar para próxima vez
			puerta_origen = ""
			return
	
	push_warning("⚠️ No se encontró puerta con nombre:", puerta_origen)
	puerta_origen = ""  # Limpiar de todas formas

func reset_estado() -> void:
	"""Reinicia el estado del jugador (útil para game over o nuevo juego)"""
	vida_jugador = 3
	agua_jugador = 100.0
	puerta_origen = ""
	gatos_rescatados.clear()
	print("🔄 Estado del jugador reiniciado")

# ============================================
# GESTIÓN DE GATOS RESCATADOS
# ============================================

func fue_gato_rescatado(nombre_gato: String) -> bool:
	"""Verifica si un gato específico fue rescatado"""
	return gatos_rescatados.has(nombre_gato)

func rescatar_gato(nombre_gato: String) -> void:
	"""Marca un gato como rescatado"""
	if not gatos_rescatados.has(nombre_gato):
		gatos_rescatados.append(nombre_gato)
		print("✅ Gato rescatado:", nombre_gato)
		print("   Gatos totales rescatados:", gatos_rescatados.size())
	else:
		print("ℹ️ El gato", nombre_gato, "ya fue rescatado")

# Alias para compatibilidad con scripts existentes
func marcar_gato_rescatado(nombre_gato: String) -> void:
	"""Alias de rescatar_gato para compatibilidad"""
	rescatar_gato(nombre_gato)
