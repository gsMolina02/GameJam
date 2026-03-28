extends AudioStreamPlayer2D

# Configuración de loop personalizado
var loop_start: float = 62.0   # Inicio del loop (segundos)
var loop_end: float = 228.0    # Fin del loop (segundos)
var total_duration: float = 0.0  # Duración total de la canción
var is_looping: bool = true     # Indica si estamos en la sección de loop
var can_exit_loop: bool = false # Permite salir del loop cuando sea necesario

func _ready():
	# Obtener la duración total del audio
	if stream:
		total_duration = stream.get_length()
		print("🎵 Música cargada - Duración: %.2f segundos" % total_duration)
		print("📍 Loop config: Intro (0-%.1f) → Loop (%.1f-%.1f) → Outro (%.1f-%.2f)" % [loop_start, loop_start, loop_end, loop_end, total_duration])
		
		# Desactivar el loop automático de Godot
		if stream is AudioStreamOggVorbis:
			stream.loop = false
	
	play()

func _process(_delta):
	if not playing or not stream:
		return
	
	var current_pos = get_playback_position()
	
	# Si estamos en la sección loopeable (62-228)
	if is_looping and current_pos >= loop_end:
		# Si podemos salir del loop, permitir que continúe al outro
		if can_exit_loop:
			print("🔄 Saliendo del loop, continuando al outro...")
			is_looping = false
		else:
			# Si no, volver al inicio del loop
			seek(loop_start)
			print("🔃 Volviendo al inicio del loop (%.1f)" % loop_start)
	
	# Si llegamos al final de la canción, detener
	if current_pos >= total_duration - 0.1:
		print("⏹️ Canción terminada")
		stop()

# Función para salir del loop en el próximo ciclo
func exit_loop_next_cycle() -> void:
	can_exit_loop = true
	print("⚠️ Se saldrá del loop en el próximo ciclo")

# Función para cambiar manualmente los puntos de loop
func set_loop_points(start: float, end: float) -> void:
	loop_start = start
	loop_end = end
	print("🎵 Puntos de loop actualizados: %.1f - %.1f" % [loop_start, loop_end])
