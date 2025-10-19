extends Node

# Configuración de la habitación
@export var vida_maxima_habitacion: float = 60.0  # Segundos totales
@export var velocidad_perdida: float = 0.5  # Vida por segundo
@export var enemigos_requeridos: int = 0  # Auto-detectado si es 0
@export var fuegos_requeridos: int = 0  # Auto-detectado si es 0
@export var activar_dialogo_gato_al_completar: bool = true  # Si debe mostrar diálogo del gato al completar

# Estado actual
var vida_habitacion: float = 60.0
var enemigos_eliminados: int = 0
var fuegos_apagados: int = 0
var habitacion_completada: bool = false
var perdiendo_vida: bool = true
var gato_en_escena: Node2D = null  # Referencia al gato que ya está en la escena

# Señales
signal vida_habitacion_actualizada(vida_actual: float, vida_maxima: float)
signal habitacion_completada_signal
signal game_over
signal gato_activado(gato: Node2D)

func _ready():
	vida_habitacion = vida_maxima_habitacion
	
	# Agregar al grupo para que el HUD lo encuentre
	add_to_group("room_manager")
	
	# Auto-detectar enemigos y fuegos si no se especificó
	if enemigos_requeridos == 0:
		enemigos_requeridos = contar_enemigos()
	if fuegos_requeridos == 0:
		fuegos_requeridos = contar_fuegos()
	
	# Buscar el gato en la escena
	_buscar_gato_en_escena()
	
	print("🏠 RoomManager inicializado")
	print("  Vida habitación:", vida_habitacion)
	print("  Enemigos a eliminar:", enemigos_requeridos)
	print("  Fuegos a apagar:", fuegos_requeridos)
	print("  Gato encontrado:", gato_en_escena != null)
	
	# Conectar señales de muerte de enemigos y fuego
	conectar_enemigos()
	conectar_fuegos()
	
	# Emitir valor inicial
	emit_signal("vida_habitacion_actualizada", vida_habitacion, vida_maxima_habitacion)

func _process(delta: float) -> void:
	if not perdiendo_vida or habitacion_completada:
		return
	
	# Reducir vida de la habitación
	vida_habitacion -= velocidad_perdida * delta
	vida_habitacion = max(0.0, vida_habitacion)
	
	# Emitir señal para actualizar HUD
	emit_signal("vida_habitacion_actualizada", vida_habitacion, vida_maxima_habitacion)
	
	# Game Over si llega a 0
	if vida_habitacion <= 0.0:
		game_over_habitacion()

func contar_enemigos() -> int:
	var count = 0
	count += get_tree().get_nodes_in_group("minion").size()
	count += get_tree().get_nodes_in_group("boss").size()
	return count

func contar_fuegos() -> int:
	return get_tree().get_nodes_in_group("fuego").size()

func conectar_enemigos() -> void:
	# Conectar todos los minions
	var minions = get_tree().get_nodes_in_group("minion")
	for minion in minions:
		if minion.has_signal("tree_exiting"):
			minion.tree_exiting.connect(_on_enemigo_eliminado.bind(minion))
	
	# Conectar todos los jefes
	var bosses = get_tree().get_nodes_in_group("boss")
	for boss in bosses:
		if boss.has_signal("tree_exiting"):
			boss.tree_exiting.connect(_on_enemigo_eliminado.bind(boss))

func conectar_fuegos() -> void:
	var fuegos = get_tree().get_nodes_in_group("fuego")
	for fuego in fuegos:
		if fuego.has_signal("tree_exiting"):
			fuego.tree_exiting.connect(_on_fuego_apagado.bind(fuego))

func _on_enemigo_eliminado(_enemigo: Node) -> void:
	# Verificar que el tree aún existe antes de usar await
	if not is_inside_tree():
		return
	
	# Esperar un frame para asegurar que el nodo se eliminó
	await get_tree().process_frame
	enemigos_eliminados += 1
	print("💀 Enemigo eliminado:", enemigos_eliminados, "/", enemigos_requeridos)
	verificar_completado()

func _on_fuego_apagado(_fuego: Node) -> void:
	# Verificar que el tree aún existe antes de usar await
	if not is_inside_tree():
		return
	
	await get_tree().process_frame
	fuegos_apagados += 1
	print("🧯 Fuego apagado:", fuegos_apagados, "/", fuegos_requeridos)
	verificar_completado()

func verificar_completado() -> void:
	if enemigos_eliminados >= enemigos_requeridos and fuegos_apagados >= fuegos_requeridos:
		completar_habitacion()

func completar_habitacion() -> void:
	if habitacion_completada:
		return
	
	habitacion_completada = true
	perdiendo_vida = false
	print("✅ ¡Habitación completada!")
	print("  Vida restante:", vida_habitacion)
	emit_signal("habitacion_completada_signal")
	
	# Desbloquear puertas
	desbloquear_puertas()
	
	# DEBUG: Información del sistema
	print("🔍 DEBUG - Estado del sistema de gatos:")
	print("  activar_dialogo_gato_al_completar:", activar_dialogo_gato_al_completar)
	print("  gato_en_escena:", gato_en_escena)
	if gato_en_escena:
		print("  Nombre del gato:", gato_en_escena.name)
		print("  Tiene método _mostrar_dialogo:", gato_en_escena.has_method("_mostrar_dialogo"))
	
	# Activar diálogo del gato si está habilitado y hay un gato en la escena
	if activar_dialogo_gato_al_completar and gato_en_escena:
		print("✅ Intentando activar diálogo del gato...")
		_activar_dialogo_gato()
	elif not activar_dialogo_gato_al_completar:
		print("⚠️ activar_dialogo_gato_al_completar está en false")
	elif not gato_en_escena:
		print("⚠️ gato_en_escena es null - buscando de nuevo...")
		_buscar_gato_en_escena()
		if gato_en_escena:
			_activar_dialogo_gato()

func desbloquear_puertas() -> void:
	var puertas = get_tree().get_nodes_in_group("puertas")
	for puerta in puertas:
		if puerta.has_method("desbloquear"):
			puerta.desbloquear()

func game_over_habitacion() -> void:
	perdiendo_vida = false
	print("💀 GAME OVER - Se acabó el tiempo de la habitación")
	emit_signal("game_over")
	
	# Pausar el juego
	get_tree().paused = true

func _buscar_gato_en_escena() -> void:
	"""Busca el gato que ya está en la escena"""
	# Primero buscar por grupo
	var gatos = get_tree().get_nodes_in_group("gatos_salvados")
	if gatos.size() > 0:
		gato_en_escena = gatos[0]
		print("🐱 Gato encontrado por grupo:", gato_en_escena.name)
	else:
		# Si no hay en el grupo, buscar por nombre que contenga "Gato"
		var escena = get_tree().current_scene
		for child in escena.get_children():
			if "Gato" in child.name and child.has_method("_mostrar_dialogo"):
				gato_en_escena = child
				print("🐱 Gato encontrado por nombre:", gato_en_escena.name)
				break
	
	if gato_en_escena:
		# Desactivar el diálogo automático si el gato lo tiene
		if "mostrar_dialogo_automatico" in gato_en_escena:
			gato_en_escena.mostrar_dialogo_automatico = false
			print("  Diálogo automático desactivado - se mostrará al completar")
	else:
		print("⚠️ No se encontró ningún gato en la escena")

func _activar_dialogo_gato() -> void:
	"""Activa el diálogo del gato cuando se completa la habitación"""
	if not gato_en_escena:
		print("❌ ERROR: gato_en_escena es null en _activar_dialogo_gato")
		return
	
	print("💬 Activando diálogo del gato...")
	print("  Gato:", gato_en_escena.name)
	
	# Si el gato tiene un método para mostrar diálogo, llamarlo
	if gato_en_escena.has_method("_mostrar_dialogo"):
		print("✅ Llamando _mostrar_dialogo() en el gato...")
		gato_en_escena._mostrar_dialogo()
		emit_signal("gato_activado", gato_en_escena)
		print("✅ Señal gato_activado emitida")
	else:
		push_warning("⚠️ El gato no tiene el método _mostrar_dialogo()")
		print("  Métodos disponibles en el gato:", gato_en_escena.get_method_list())
