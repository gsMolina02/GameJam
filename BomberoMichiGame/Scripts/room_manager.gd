extends Node

# Configuración de la habitación
@export var vida_maxima_habitacion: float = 60.0  # Segundos totales
@export var velocidad_perdida: float = 0.5  # Vida por segundo
@export var enemigos_requeridos: int = 0  # Auto-detectado si es 0
@export var fuegos_requeridos: int = 0  # Auto-detectado si es 0

# Estado actual
var vida_habitacion: float = 60.0
var enemigos_eliminados: int = 0
var fuegos_apagados: int = 0
var habitacion_completada: bool = false
var perdiendo_vida: bool = true

# Señales
signal vida_habitacion_actualizada(vida_actual: float, vida_maxima: float)
signal habitacion_completada_signal
signal game_over

func _ready():
	vida_habitacion = vida_maxima_habitacion
	
	# Agregar al grupo para que el HUD lo encuentre
	add_to_group("room_manager")
	
	# Auto-detectar enemigos y fuegos si no se especificó
	if enemigos_requeridos == 0:
		enemigos_requeridos = contar_enemigos()
	if fuegos_requeridos == 0:
		fuegos_requeridos = contar_fuegos()
	
	print("🏠 RoomManager inicializado")
	print("  Vida habitación:", vida_habitacion)
	print("  Enemigos a eliminar:", enemigos_requeridos)
	print("  Fuegos a apagar:", fuegos_requeridos)
	
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
	
	# Notificar a los gatos que el rescate está completo
	notificar_gatos_rescatados()
	
	# Desbloquear puertas
	desbloquear_puertas()

func desbloquear_puertas() -> void:
	var puertas = get_tree().get_nodes_in_group("puertas")
	for puerta in puertas:
		if puerta.has_method("desbloquear"):
			puerta.desbloquear()

func notificar_gatos_rescatados() -> void:
	"""Notifica a todos los gatos que el rescate está completo"""
	var gatos = get_tree().get_nodes_in_group("gatos_salvados")
	for gato in gatos:
		if gato.has_method("marcar_fuego_apagado"):
			gato.marcar_fuego_apagado()
		if gato.has_method("marcar_enemigos_derrotados"):
			gato.marcar_enemigos_derrotados()
	print("🐱 Notificados", gatos.size(), "gatos sobre el rescate completado")

func game_over_habitacion() -> void:
	if habitacion_completada:
		return  # Evitar muerte si ya completó la habitación
		
	perdiendo_vida = false
	habitacion_completada = true  # Evitar llamadas múltiples
	print("💀 GAME OVER - Se acabó el tiempo de la habitación")
	emit_signal("game_over")
	
	# Buscar al personaje principal y matarlo usando el sistema correcto
	var players = get_tree().get_nodes_in_group("player_main")
	if players.size() > 0:
		var player = players[0]
		# Usar el sistema de daño para matar al jugador
		if player.has_method("recibir_dano") and "vida_actual" in player:
			var dano_total = player.vida_actual + 1.0  # Asegurar que muera
			player.recibir_dano(dano_total)
			print("💀 Personaje muerto por tiempo agotado - Vida reducida a:", player.vida_actual)
