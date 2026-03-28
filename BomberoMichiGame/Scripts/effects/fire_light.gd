extends Node2D

@export var min_energy: float = 0.75
@export var max_energy: float = 1.4
@export var flicker_speed: float = 6.0
@export var color_variation: float = 0.15

@onready var light: Light2D = $Light2D
@onready var glow: Sprite2D = $Glow

func _ready():
	# Initialize to mid value
	if light:
		light.energy = (min_energy + max_energy) * 0.5

func _process(delta: float) -> void:
	if not light:
		return
	# Smooth random flicker using lerp towards random target
	var target = lerp(min_energy, max_energy, randf())
	light.energy = lerp(light.energy, target, clamp(delta * flicker_speed, 0, 1))

	# Slight color variation to mimic heat
	var t = randf() * color_variation
	light.color = Color(1.0, 0.6 + t, 0.2)
	if glow:
		glow.modulate = Color(1.0, 0.6 + t * 0.8, 0.2, 0.8)
