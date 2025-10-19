extends CanvasLayer


# Referencias a las texturas de armas
@onready var weapon_texture_rect: TextureRect = $Control/waepon
var weapon_hose_texture: Texture2D
var weapon_transition_texture: Texture2D
var weapon_axe_texture: Texture2D

# Control de animación
var is_transitioning: bool = false
var transition_progress: float = 0.0
var transition_speed: float = 3.0  # Velocidad del fade (más alto = más rápido)
var current_transition_state: int = 0  # 0 = fade out, 1 = cambio intermedio, 2 = fade in final

# Arma objetivo
var target_weapon_texture: Texture2D

enum WeaponType {
	HOSE = 1,
	AXE = 0
}

func _ready():
	# Precargar las texturas
	weapon_hose_texture = preload("res://Resources/hub/CascoBombero_0006.png")
	weapon_transition_texture = preload("res://Resources/hub/CascoBombero_0004.png")
	weapon_axe_texture = preload("res://Resources/hub/CascoBombero_0000.png")
	
	# Establecer la textura inicial (manguera)
	if weapon_texture_rect:
		weapon_texture_rect.texture = weapon_hose_texture
		weapon_texture_rect.modulate.a = 1.0
	
	# Buscar al jugador y conectar su señal
	call_deferred("_connect_to_player")

func _connect_to_player():
	# Buscar al jugador en el grupo "player_main"
	var players = get_tree().get_nodes_in_group("player_main")
	if players.size() > 0:
		var player = players[0]
		if player.has_signal("weapon_switched"):
			player.weapon_switched.connect(_on_weapon_switched)
			print("✓ HUD conectado al sistema de cambio de armas")
		else:
			print("⚠ El jugador no tiene la señal weapon_switched")
	else:
		print("⚠ No se encontró jugador en el grupo 'player_main'")

func _on_weapon_switched(new_weapon):
	"""Callback cuando el jugador cambia de arma"""
	if is_transitioning:
		return  # Evitar múltiples transiciones simultáneas
	
	# Determinar la textura objetivo
	if new_weapon == WeaponType.HOSE:
		target_weapon_texture = weapon_hose_texture
		print("🔄 HUD: Cambiando icono a MANGUERA")
	elif new_weapon == WeaponType.AXE:
		target_weapon_texture = weapon_axe_texture
		print("🔄 HUD: Cambiando icono a HACHA")
	else:
		return
	
	# Iniciar la transición
	is_transitioning = true
	current_transition_state = 0
	transition_progress = 0.0

func _process(delta):
	if not is_transitioning or not weapon_texture_rect:
		return
	
	# Avanzar el progreso de la transición
	transition_progress += delta * transition_speed
	
	match current_transition_state:
		0:  # Fade out de la imagen actual
			weapon_texture_rect.modulate.a = 1.0 - transition_progress
			if transition_progress >= 1.0:
				# Cambiar a la imagen intermedia
				weapon_texture_rect.texture = weapon_transition_texture
				current_transition_state = 1
				transition_progress = 0.0
		
		1:  # Fade in de la imagen intermedia
			weapon_texture_rect.modulate.a = transition_progress
			if transition_progress >= 1.0:
				# Esperar un momento y luego fade out
				current_transition_state = 2
				transition_progress = 0.0
		
		2:  # Fade out de la imagen intermedia
			weapon_texture_rect.modulate.a = 1.0 - transition_progress
			if transition_progress >= 1.0:
				# Cambiar a la imagen final
				weapon_texture_rect.texture = target_weapon_texture
				current_transition_state = 3
				transition_progress = 0.0
		
		3:  # Fade in de la imagen final
			weapon_texture_rect.modulate.a = transition_progress
			if transition_progress >= 1.0:
				# Finalizar transición
				weapon_texture_rect.modulate.a = 1.0
				is_transitioning = false
				current_transition_state = 0
				print("✓ Transición de arma completada")
