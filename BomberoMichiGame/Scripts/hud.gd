extends CanvasLayer

# 1. REFERENCIAS A LAS BARRAS
@onready var oxigeno_bar = $RootControl/OxigenoBar
@onready var agua_bar = $RootControl/AguaBar

# 2. REFERENCIAS AL HUD DE ARMAS (para el efecto de parpadeo)
@onready var hud_vida_personaje = $RootControl/HudVidaPersonaje
@onready var hud_vida_personaje_hacha = $RootControl/HudVidaPersonajeHacha

# Cambiamos 'AsphyxiaEffect' por 'Node' para evitar el Parse Error
var asphyxia_effect: Node = null

const MAX_FIND_TRIES := 12
var _find_tries := 0

func _ready():
	# Buscar el efecto de asfixia de forma genérica
	asphyxia_effect = get_tree().root.find_child("MundoGrisLayer", true, false)
	if asphyxia_effect:
		print("HUD: MundoGrisLayer encontrado ✅")
	
	find_and_register_player()

# 2. BUSCADOR AUTOMÁTICO DEL JUGADOR
func find_and_register_player() -> void:
	var players = get_tree().get_nodes_in_group("player_main")
	if players.size() > 0:
		_register_player(players[0])
		return
	
	_find_tries += 1
	if _find_tries <= MAX_FIND_TRIES:
		await get_tree().create_timer(0.1).timeout
		find_and_register_player()

# 3. CONEXIÓN DE SEÑALES
func _register_player(player: Node) -> void:
	if player == null: return
	if player.has_signal("vida_actualizada"):
		player.vida_actualizada.connect(_on_player_vida_actualizada)
	if player.has_signal("hose_recharged"):
		player.hose_recharged.connect(_on_player_hose_recharged)
	if player.has_signal("weapon_switched"):
		player.weapon_switched.connect(_on_player_weapon_switched)
	
	if "vida_actual" in player:
		_on_player_vida_actualizada(player.vida_actual)
	if "hose_charge" in player:
		_on_player_hose_recharged(player.hose_charge)

# 4. ACTUALIZAR BARRA DE OXÍGENO (VERDE -> ROJO)
func _on_player_vida_actualizada(nueva_vida: float) -> void:
	if is_instance_valid(oxigeno_bar):
		oxigeno_bar.value = nueva_vida
		var color_o2 = Color.GREEN
		if nueva_vida > 50:
			color_o2 = Color.YELLOW.lerp(Color.GREEN, (nueva_vida - 50.0) / 50.0)
		else:
			color_o2 = Color.RED.lerp(Color.YELLOW, nueva_vida / 50.0)
		oxigeno_bar.tint_progress = color_o2

	# Llamamos al efecto usando 'call' para que no falle si el script no cargó
	if is_instance_valid(asphyxia_effect):
		asphyxia_effect.call("update_oxygen", nueva_vida)

# 5. ACTUALIZAR BARRA DE AGUA (CELESTE)
func _on_player_hose_recharged(nuevo_porcentaje: float) -> void:
	if is_instance_valid(agua_bar):
		agua_bar.value = nuevo_porcentaje
		
		# Si el porcentaje es muy bajo o está en 0, poner roja para indicar bloqueo
		if nuevo_porcentaje <= 0.1:
			agua_bar.tint_progress = Color.RED
		elif nuevo_porcentaje < 20.0:
			# Color naranja mientras recarga pero sigue bloqueada
			agua_bar.tint_progress = Color.ORANGE
		else:
			# Color celeste normal cuando ya se puede usar
			agua_bar.tint_progress = Color.CYAN

# 6. CAMBIO DE ARMA CON EFECTO DE PARPADEO
func _on_player_weapon_switched(new_weapon: int) -> void:
	# new_weapon: 0 = AXE, 1 = HOSE
	var es_hacha = (new_weapon == 0)
	cambiar_hud_arma(es_hacha)

func cambiar_hud_arma(es_hacha: bool) -> void:
	"""Cambia el HUD de arma con efecto de parpadeo"""
	# Primero ocultamos ambos para resetear el estado
	hud_vida_personaje.visible = false
	hud_vida_personaje_hacha.visible = false
	
	# Elegimos cuál va a titilar
	var hud_objetivo = hud_vida_personaje_hacha if es_hacha else hud_vida_personaje
	hud_objetivo.visible = true
	
	# Resetear la opacidad al inicio
	hud_objetivo.modulate.a = 1.0
	
	# Crear el efecto de titileo (Parpadeo) con Tween
	var tween = create_tween()
	
	# Hacemos que parpadee 3 veces cambiando la opacidad
	for i in range(3):
		tween.tween_property(hud_objetivo, "modulate:a", 0.0, 0.1) # Desaparece en 0.1s
		tween.tween_property(hud_objetivo, "modulate:a", 1.0, 0.1) # Aparece en 0.1s
	
	# Al terminar el loop, nos aseguramos de que sea totalmente visible
	tween.tween_property(hud_objetivo, "modulate:a", 1.0, 0.0)
	
	# Debug: mostrar qué arma se cambió
	print("HUD: Cambio de arma - ", "HACHA" if es_hacha else "MANGUERA", " con efecto de parpadeo ✨")
