# tanque_oxigeno.gd
extends Area2D

@onready var polygon = get_node_or_null("Polygon2D")
@onready var sprite = get_node_or_null("Sprite2D")

var player_nearby: bool = false
var player_ref = null

func _ready():
	# Identificar este objeto como "pickup_vida"
	add_to_group("pickup_vida")
	
	# Configurar colisiones
	collision_layer = 2  # Capa 2 para ser detectado por el jugador
	collision_mask = 1   # Detectar capa 1 (jugador)
	
	# Conectar señales para detectar cuando el jugador está cerca
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	print("Tanque de oxígeno inicializado")

func _on_area_entered(area):
	# Detectar si es el Hitbox del jugador
	if area.get_parent() and area.get_parent().is_in_group("player_main"):
		player_nearby = true
		player_ref = area.get_parent()

func _on_area_exited(area):
	# El jugador se alejó
	if area.get_parent() and area.get_parent().is_in_group("player_main"):
		player_nearby = false
		player_ref = null

func _process(_delta):
	# Feedback visual si el jugador está cerca pero no puede recogerlo
	if player_nearby and player_ref:
		var visual_node = sprite if sprite else polygon
		if visual_node:
			# Si el jugador tiene vida máxima, hacer que el tanque parpadee
			if player_ref.vida_actual >= player_ref.vida_maxima:
				# Parpadeo sutil
				var time = Time.get_ticks_msec() / 1000.0
				visual_node.modulate.a = 0.5 + sin(time * 5.0) * 0.3
			else:
				# Normal si puede recogerlo
				visual_node.modulate.a = 1.0
	else:
		# Restaurar opacidad normal cuando el jugador no está cerca
		var visual_node = sprite if sprite else polygon
		if visual_node:
			visual_node.modulate.a = 1.0
