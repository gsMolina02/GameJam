extends CanvasLayer

# Referencia al nodo unificado
@onready var overlay = $OverlaySupervivencia

@export var oxygen_threshold_start = 30.0

# Audio parameters
@export var cough_sound: AudioStream = preload("res://Assets/SFX/tos/Tos.ogg")
@export var cough_recover_sound: AudioStream = preload("res://Assets/SFX/tos/Tos_recover.ogg")
@export var cough_interval: float = 3.0  # Intervalo entre sonidos de tos (segundos)
@export var recovery_delay: float = 1.0  # Delay antes de reproducir sonido de recuperación (segundos)
@export var sfx_volume_db: float = 0.0  # Volumen de efectos de sonido (en decibeles)

var audio_player: AudioStreamPlayer
var is_asphyxia_active: bool = false
var cough_timer: float = 0.0
var recovery_timer: float = 0.0  # Timer para delay de recuperación
var is_playing_recovery: bool = false  # Bandera para evitar solapamientos

func _ready():
	# Asegurarnos de que el efecto empiece en 0
	_aplicar_visuales(0.0)
	
	# Crear AudioStreamPlayer para los efectos de sonido
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.volume_db = sfx_volume_db
	add_child(audio_player)
	
	print("AsfixiaEffect: Sistema Unificado Listo.")

func _process(delta: float) -> void:
	# Controlar el timer de tos
	if is_asphyxia_active:
		cough_timer -= delta
		if cough_timer <= 0.0:
			_play_cough_sound()
			cough_timer = cough_interval
	
	# Controlar el delay de recuperación
	if is_playing_recovery:
		recovery_timer -= delta
		if recovery_timer <= 0.0:
			_play_cough_recover_sound()
			is_playing_recovery = false

func update_oxygen(nueva_vida: float):
	var intensidad = 0.0
	var was_asphyxia_active = is_asphyxia_active
	
	# Si la vida baja de 30, calculamos intensidad
	# (a 30% -> 0 intensidad | a 0% -> 1 intensidad)
	if nueva_vida <= oxygen_threshold_start:
		intensidad = (oxygen_threshold_start - nueva_vida) / oxygen_threshold_start
		is_asphyxia_active = true
	else:
		intensidad = 0.0 # Vida sana = pantalla limpia
		is_asphyxia_active = false
	
	# ✅ ARREGLADO: Reproducir sonido de recuperación al salir de asfixia (con delay de 1 segundo)
	if was_asphyxia_active and not is_asphyxia_active:
		is_playing_recovery = true
		recovery_timer = recovery_delay
	
	# Al entrar en asfixia, reiniciar el timer para que suene inmediatamente
	if not was_asphyxia_active and is_asphyxia_active:
		cough_timer = 0.0
		is_playing_recovery = false
	
	_aplicar_visuales(intensidad)

func _aplicar_visuales(i: float):
	if overlay and overlay.material:
		# Esto moverá la barrita de intensidad del shader fusionado
		overlay.material.set_shader_parameter("intensidad", i)
		# Hacemos visible el nodo solo si hay intensidad
		overlay.visible = (i > 0.01)

func _play_cough_sound() -> void:
	if audio_player and cough_sound:
		audio_player.stream = cough_sound
		audio_player.volume_db = sfx_volume_db
		audio_player.play()
		print("🔊 Sonido de tos reproducido (Volumen: ", sfx_volume_db, " dB)")

func _play_cough_recover_sound() -> void:
	if audio_player and cough_recover_sound:
		audio_player.stream = cough_recover_sound
		audio_player.volume_db = sfx_volume_db
		audio_player.play()
		print("🔊 Sonido de recuperación reproducido (Volumen: ", sfx_volume_db, " dB)")
