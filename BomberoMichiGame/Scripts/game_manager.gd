extends Node

# Estado del jugador entre escenas
var vida_jugador: int = 3
var agua_jugador: float = 100.0
var vida_maxima_jugador: float = 100.0  # Para restaurar poderes del gato
var hose_drain_rate_jugador: float = 4.0  # Para restaurar poder de manguera
var puerta_origen: String = ""  # Nombre de la puerta por la que entramos
var offset_spawn: Vector2 = Vector2(50, 0)

# ─── Estado del mundo guardado ───
var nodos_destruidos: Array = []
var posicion_guardada: Vector2 = Vector2.INF

func registrar_nodo_destruido(nodo_path: String) -> void:
	if not nodo_path in nodos_destruidos:
		nodos_destruidos.append(nodo_path)

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
	
	# Guardar vida máxima (puede haber aumentado por los gatos)
	if "vida_maxima" in jugador:
		vida_maxima_jugador = jugador.vida_maxima
		print("  Vida máxima guardada:", vida_maxima_jugador)
	
	# Guardar agua
	if "hose_charge" in jugador:
		agua_jugador = jugador.hose_charge
		print("  Agua guardada:", agua_jugador, "%")
	
	# Guardar drain rate (puede haber mejorado por el gato)
	if "hose_drain_rate" in jugador:
		hose_drain_rate_jugador = jugador.hose_drain_rate
		print("  Hose drain rate guardado:", hose_drain_rate_jugador)

func restaurar_estado_jugador(jugador: Node) -> void:
	print("📥 Restaurando estado del jugador...")
	print("  Vida a restaurar:", vida_jugador, "/ máx:", vida_maxima_jugador)
	print("  Agua a restaurar:", agua_jugador, "%")
	
	# Restaurar vida máxima primero (para que la vida actual no la supere)
	if "vida_maxima" in jugador:
		jugador.vida_maxima = vida_maxima_jugador
	
	# Restaurar vida
	if "vida_actual" in jugador:
		jugador.vida_actual = vida_jugador
		# Emitir señal para que el HUD se actualice
		if jugador.has_signal("vida_actualizada"):
			jugador.emit_signal("vida_actualizada", vida_jugador)
	
	# Restaurar hose drain rate (poder del gato)
	if "hose_drain_rate" in jugador:
		jugador.hose_drain_rate = hose_drain_rate_jugador
	
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
	vida_maxima_jugador = 100.0
	hose_drain_rate_jugador = 4.0
	puerta_origen = ""
	nodos_destruidos.clear()
	posicion_guardada = Vector2.INF
	print("🔄 Estado del jugador y mundo reiniciado")
