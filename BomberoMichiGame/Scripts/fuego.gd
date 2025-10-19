extends Area2D

# Sistema de vida del fuego
@export var max_fire_health: float = 5.0  # Vida máxima del fuego (ajustado para 0.5 segundos)
@export var extinguish_time: float = 0.5  # Tiempo necesario para apagar (segundos)

var current_health: float = 5.0
var is_being_extinguished: bool = false

# Efectos visuales opcionales
@onready var sprite = get_node_or_null("Sprite2D")
@onready var polygon = get_node_or_null("Polygon2D")
@onready var animation_player = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	# Añadir al grupo de fuego para ser detectado por la manguera
	add_to_group("Fire")
	add_to_group("fuego")
	
	# Configurar collision layers si no están configuradas en la escena
	collision_layer = 2  # Capa 2 para ser detectado por la manguera
	collision_mask = 1   # Detectar capa 1 (jugador) para hacer daño por contacto
	
	# Inicializar vida
	current_health = max_fire_health
	
	# Configurar animación si existe
	if animation_player and animation_player.has_animation("burning"):
		animation_player.play("burning")
	
	print("Fuego estático inicializado - Vida: ", current_health, " - Grupos: ", get_groups())

func _process(_delta: float) -> void:
	# Actualizar efectos visuales según la vida del fuego
	var visual_node = sprite if sprite else polygon
	
	if visual_node:
		# Hacer el fuego más transparente a medida que se apaga
		var alpha = current_health / max_fire_health
		visual_node.modulate.a = clamp(alpha, 0.3, 1.0)
		
		# Hacer el fuego más pequeño a medida que se apaga
		var scale_factor = 0.5 + (current_health / max_fire_health) * 0.5
		visual_node.scale = Vector2(scale_factor, scale_factor)

func apply_water(water_amount: float) -> void:
	"""Aplica agua al fuego, reduciéndolo gradualmente"""
	is_being_extinguished = true
	
	# Calcular cuánto daño hace el agua
	# water_amount es la cantidad por frame, lo convertimos a "daño"
	current_health -= water_amount
	
	# Feedback visual o sonoro cuando se está apagando
	_play_extinguish_effect()
	
	# Comprobar si el fuego se ha apagado completamente
	if current_health <= 0:
		extinguish()
	
	# Debug
	print("Fuego recibiendo agua. Vida restante: ", current_health, "/", max_fire_health)

func take_damage(amount: float) -> void:
	"""Alternativa a apply_water para compatibilidad"""
	apply_water(amount)

func extinguish() -> void:
	"""Apaga el fuego completamente"""
	print("¡Fuego extinguido!")
	
	# Efectos visuales/sonoros de extinción
	_play_extinguished_effect()
	
	# Emitir señal si existe
	if has_signal("fire_extinguished"):
		emit_signal("fire_extinguished")
	
	# Eliminar el fuego de la escena
	queue_free()

func _play_extinguish_effect() -> void:
	"""Efectos mientras se está apagando el fuego"""
	# Aquí puedes añadir partículas de vapor, sonidos, etc.
	if animation_player and animation_player.has_animation("extinguishing"):
		if animation_player.current_animation != "extinguishing":
			animation_player.play("extinguishing")

func _play_extinguished_effect() -> void:
	"""Efectos cuando el fuego se apaga completamente"""
	# Aquí puedes instanciar partículas de humo, sonido de "pshhh", etc.
	pass

func get_extinguish_progress() -> float:
	"""Retorna el progreso de extinción (0.0 = lleno, 1.0 = apagado)"""
	return 1.0 - (current_health / max_fire_health)

# Señal para notificar cuando el fuego se apaga
signal fire_extinguished
