extends CanvasLayer

@onready var player_life_label = $RootControl/PlayerLifeLabel
@onready var water_percent_label = $RootControl/WaterPercentLabel
@onready var room_label = $RootControl/RoomBar/RoomLabel
@onready var room_bar = $RootControl/RoomBar/ColorRect

const MAX_FIND_TRIES := 12
var _find_tries := 0

func _ready():
	find_and_register_player()
	find_and_register_room_manager()

# Busca el player por grupo; si no está, reintenta un pequeño número de veces.
func find_and_register_player() -> void:
	var players = get_tree().get_nodes_in_group("player_main")
	if players.size() > 0:
		_register_player(players[0])
		return
	_find_tries += 1
	if _find_tries <= MAX_FIND_TRIES:
		# espera un frame corto y vuelve a intentar
		await get_tree().create_timer(0.05).timeout
		find_and_register_player()
	else:
		push_warning("HUD: no se encontró player_main tras múltiples intentos.")

func _register_player(player: Node) -> void:
	if player == null:
		return
	# Desconectar/Conectar señal correctamente (Godot 4)
	if player.is_connected("vida_actualizada", Callable(self, "_on_player_vida_actualizada")):
		player.disconnect("vida_actualizada", Callable(self, "_on_player_vida_actualizada"))
	player.connect("vida_actualizada", Callable(self, "_on_player_vida_actualizada"))
	
	# Conectar señal de agua/manguera
	if player.has_signal("hose_recharged"):
		if player.is_connected("hose_recharged", Callable(self, "_on_player_hose_recharged")):
			player.disconnect("hose_recharged", Callable(self, "_on_player_hose_recharged"))
		player.connect("hose_recharged", Callable(self, "_on_player_hose_recharged"))
	
	# Pedir la vida inicial (usar vida_actual como prioridad)
	if "vida_actual" in player:
		_on_player_vida_actualizada(player.vida_actual)
		print("HUD: Vida inicial del player:", player.vida_actual, "/", player.vida_maxima if "vida_maxima" in player else "?")
	elif player.has_method("get_vida_actual"):
		_on_player_vida_actualizada(player.get_vida_actual())
	elif "tanques_oxigeno" in player:
		_on_player_vida_actualizada(player.tanques_oxigeno)
	
	# Pedir el agua inicial
	if "hose_charge" in player:
		_on_player_hose_recharged(player.hose_charge)
	elif player.has_method("get_hose_charge"):
		_on_player_hose_recharged(player.get_hose_charge())

func _on_player_vida_actualizada(nueva_vida: float) -> void:
	if is_instance_valid(player_life_label):
		# Mostrar con 1 decimal si es necesario, si no, mostrar como entero
		if fmod(nueva_vida, 1.0) == 0.0:
			player_life_label.text = "x%d" % int(nueva_vida)
		else:
			player_life_label.text = "x%.1f" % nueva_vida

func _on_player_hose_recharged(nuevo_porcentaje: float) -> void:
	"""Actualiza el porcentaje de agua cuando cambia la carga de la manguera"""
	if is_instance_valid(water_percent_label):
		water_percent_label.text = "%d%%" % int(nuevo_porcentaje)

func actualizar_agua(nuevo_porcentaje: int) -> void:
	if is_instance_valid(water_percent_label):
		water_percent_label.text = "%d%%" % int(nuevo_porcentaje)

# ============================================
# ROOM MANAGER
# ============================================
func find_and_register_room_manager() -> void:
	"""Busca y conecta al RoomManager"""
	var room_managers = get_tree().get_nodes_in_group("room_manager")
	if room_managers.size() > 0:
		_register_room_manager(room_managers[0])
	else:
		# Buscar en la escena actual
		var current_scene = get_tree().current_scene
		if current_scene:
			for child in current_scene.get_children():
				if child is Node and child.name == "RoomManager":
					_register_room_manager(child)
					return

func _register_room_manager(room_manager: Node) -> void:
	if room_manager == null:
		return
	
	print("HUD: RoomManager encontrado y conectado")
	
	# Conectar señal de vida de habitación
	if room_manager.has_signal("vida_habitacion_actualizada"):
		if room_manager.is_connected("vida_habitacion_actualizada", Callable(self, "_on_vida_habitacion_actualizada")):
			room_manager.disconnect("vida_habitacion_actualizada", Callable(self, "_on_vida_habitacion_actualizada"))
		room_manager.connect("vida_habitacion_actualizada", Callable(self, "_on_vida_habitacion_actualizada"))
	
	# Pedir valor inicial
	if "vida_habitacion" in room_manager and "vida_maxima_habitacion" in room_manager:
		_on_vida_habitacion_actualizada(room_manager.vida_habitacion, room_manager.vida_maxima_habitacion)

func _on_vida_habitacion_actualizada(vida_actual: float, vida_maxima: float) -> void:
	"""Actualiza el label y barra de vida de la habitación"""
	if is_instance_valid(room_label):
		room_label.text = "%.1f" % vida_actual
	
	# Actualizar barra visual
	if is_instance_valid(room_bar):
		var porcentaje = max(0.0, vida_actual / vida_maxima)
		# Ajustar el tamaño de la barra (160 es el ancho máximo)
		var ancho_maximo = 160.0
		var nuevo_ancho = ancho_maximo * porcentaje
		room_bar.custom_minimum_size.x = max(0.0, nuevo_ancho)
		
		# Cambiar color según la vida restante
		if porcentaje > 0.5:
			room_bar.color = Color(0.435, 0.027, 0.027)  # Rojo oscuro
		elif porcentaje > 0.25:
			room_bar.color = Color(0.8, 0.4, 0.0)  # Naranja
		elif porcentaje > 0.1:
			room_bar.color = Color(0.9, 0.0, 0.0)  # Rojo brillante
		else:
			room_bar.color = Color(1.0, 0.0, 0.0)  # Rojo puro (crítico)
