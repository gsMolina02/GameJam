extends CanvasLayer

@onready var player_life_label = $RootControl/PlayerLifeLabel
@onready var water_percent_label = $RootControl/WaterPercentLabel

const MAX_FIND_TRIES := 12
var _find_tries := 0

func _ready():
	find_and_register_player()

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
	
	# Pedir la vida inicial (respeta diferentes nombres)
	if "tanques_oxigeno" in player:
		_on_player_vida_actualizada(player.tanques_oxigeno)
	elif player.has_method("get_vida_actual"):
		_on_player_vida_actualizada(player.get_vida_actual())
	elif "vida_actual" in player:
		_on_player_vida_actualizada(player.vida_actual)
	
	# Pedir el agua inicial
	if "hose_charge" in player:
		_on_player_hose_recharged(player.hose_charge)
	elif player.has_method("get_hose_charge"):
		_on_player_hose_recharged(player.get_hose_charge())

func _on_player_vida_actualizada(nueva_vida: int) -> void:
	if is_instance_valid(player_life_label):
		player_life_label.text = "Oxi: x%d" % int(nueva_vida)

func _on_player_hose_recharged(nuevo_porcentaje: float) -> void:
	"""Actualiza el porcentaje de agua cuando cambia la carga de la manguera"""
	if is_instance_valid(water_percent_label):
		water_percent_label.text = "Agua: %d%%" % int(nuevo_porcentaje)

func actualizar_agua(nuevo_porcentaje: int) -> void:
	if is_instance_valid(water_percent_label):
		water_percent_label.text = "Agua: %d%%" % int(nuevo_porcentaje)
