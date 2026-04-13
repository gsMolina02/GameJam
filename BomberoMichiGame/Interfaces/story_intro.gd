extends Control

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

# Configuración de las 7 páginas de la historia
# Cada página tiene una imagen/video y una clave de traducción
@export var story_pages: Array[Dictionary] = [
	{
		"image": "res://Assets/sinopsis/1.png",
		"key": "story.page_1"
	},
	{
		"image": "res://Assets/sinopsis/2.png",
		"key": "story.page_2"
	},
	{
		"image": "res://Assets/sinopsis/3.png",
		"key": "story.page_3"
	},
	{
		"video": "res://Assets/sinopsis/caidaHijasAiden.ogv",
		"key": "story.page_4"
	},
	{
		"image": "res://Assets/sinopsis/5.png",
		"key": "story.page_5"
	},
	{
		"video": "res://Assets/sinopsis/caidaAiden.ogv",
		"key": "story.page_6"
	},
	{
		"key": "story.page_7"
	}
]

# Música de la sinopsis
@export var synopsis_music_path: String = "res://Assets/musica/Sinopsis.ogg"
@export var synopsis_music_volume: float = -12.0  # en dB (más bajo para no aturdir)

var audio_player: AudioStreamPlayer

# Escena a la que ir después de la intro (tu nivel o escena de juego)
@export var next_scene: String = "res://Scenes/Levels/levelOsiris/OsirisLevel.tscn"

# Velocidad del efecto de escritura
@export var typing_speed: float = 40.0

# Tiempo de espera después de terminar el texto antes de permitir avanzar
@export var wait_after_text: float = 1.0

var current_page: int = 0
var current_char: int = 0
var is_typing: bool = false
var can_advance: bool = false
var full_text: String = ""


func _ready():
	# 1. BLINDADO CONTRA PAUSAS
	process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$Timer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	
	# 2. 🌟 LA CURA DEFINITIVA: Resetear el tiempo del motor
	Engine.time_scale = 1.0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if story_pages.is_empty():
		push_error("No hay páginas de historia configuradas!")
		go_to_next_scene()
		return
	
	setup_synopsis_music()
	update_texts()
	add_to_group("localizable")
	
	# 3. Esperar a que la escena esté 100% cargada en la RAM antes de animar
	call_deferred("show_page", 0)

func update_texts() -> void:
	"""Actualiza todos los textos traducibles cuando cambia el idioma"""
	if has_node("BottomPanel/ContinueHint"):
		$BottomPanel/ContinueHint.text = _t("story.continue_hint")
	if has_node("BlackPanel/FinalMessage"):
		$BlackPanel/FinalMessage.text = _t("story.page_7")

func setup_synopsis_music() -> void:
	"""Configura y reproduce la música de sinopsis con volumen ajustado"""
	# Crear AudioStreamPlayer si no existe
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Cargar la música de sinopsis
	var music_stream = load(synopsis_music_path)
	if music_stream:
		audio_player.stream = music_stream
		audio_player.bus = &"Master"  # Usar bus Master o el que prefieras
		audio_player.volume_db = synopsis_music_volume
		audio_player.play()
		print("🎵 Música de sinopsis reproduciendo a %.1f dB" % synopsis_music_volume)
	else:
		push_warning("No se pudo cargar la música: " + synopsis_music_path)

func show_page(page_index: int):
	if page_index >= story_pages.size():
		finish_story()
		return
	
	print("📖 [PAGINA] Iniciando carga de página: ", page_index)
	current_page = page_index
	can_advance = false
	is_typing = false
	
	if has_node("BottomPanel/StoryText"):
		$BottomPanel/StoryText.text = ""
		
	full_text = _t("story.page_" + str(page_index + 1))
	print("📝 [TEXTO] Texto obtenido: '", full_text, "'")
	
	if current_page > 0:
		print("🎬 [ANIM] Esperando fade_out...")
		$AnimationPlayer.play("fade_out")
		# Salvavidas: En lugar de esperar la señal que se buguea, esperamos el tiempo exacto
		await get_tree().create_timer(0.5).timeout 
	
	var page_data = story_pages[current_page]
	
	if page_data.has("image"):
		$VideoPlayer.visible = false
		$StoryImage.visible = true
		$BlackPanel.visible = false
		$BottomPanel.visible = true
		$StoryFrame.visible = true
		
		var texture = load(page_data["image"])
		if texture:
			$StoryImage.texture = texture
			
	elif page_data.has("video"):
		$StoryImage.visible = false
		$BlackPanel.visible = false
		$VideoPlayer.visible = true
		$BottomPanel.visible = true
		$StoryFrame.visible = true
		
		var video_path = page_data["video"]
		$VideoPlayer.stream = load(video_path)
		if $VideoPlayer.stream:
			$VideoPlayer.play()
			
	else:
		$StoryImage.visible = false
		$VideoPlayer.visible = false
		$BlackPanel.visible = true
		$BottomPanel.visible = false
		$StoryFrame.visible = false
	
	print("🎬 [ANIM] Esperando fade_in...")
	$AnimationPlayer.play("fade_in")
	# Salvavidas Maestro: Forzamos la continuación después de 0.8s (lo que dura tu fade_in)
	await get_tree().create_timer(0.85).timeout 
	
	print("✅ [ANIM] fade_in terminado (o forzado). ¡Iniciando escritura!")
	start_typing()

func start_typing():
	print("✍️ [TEXTO] Empezando a escribir: '", full_text, "'")
	is_typing = true
	current_char = 0
	
	while current_char < full_text.length() and is_typing:
		$BottomPanel/StoryText.text = full_text.substr(0, current_char + 1)
		current_char += 1
		await get_tree().create_timer(1.0 / typing_speed).timeout
	
	# Cuando termina de escribir de forma natural (sin que lo salten)
	if is_typing:
		print("✅ [TEXTO] Terminó de escribir naturalmente.")
		is_typing = false
		$Timer.wait_time = wait_after_text
		$Timer.start()
		print("   -> ⏱️ Timer de espera iniciado: ", wait_after_text, "s (Input bloqueado hasta que termine)")

func _on_timer_timeout():
	can_advance = true
	print("⏰ [TIMER] Terminó el tiempo de espera. can_advance = true. (¡Ya puedes presionar Enter!)")

func _input(event):
	# Agregamos "not event.is_echo()" para evitar que se dispare 100 veces si mantienes presionada la tecla
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_P:
			print("⌨️ [INPUT] Tecla P -> Saltando escena...")
			is_typing = false
			go_to_next_scene()
			return
		# Añadí SPACE y KP_ENTER (Enter del teclado numérico) por si acaso
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_KP_ENTER:
			print("⌨️ [INPUT] Tecla Enter/Space presionada")
			handle_input()
			
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("🖱️ [INPUT] Clic izquierdo presionado")
			handle_input()

func handle_input():
	print("⚙️ [LOGICA] handle_input() | is_typing: ", is_typing, " | can_advance: ", can_advance)
	
	if is_typing:
		print("   -> ⏩ Acelerando el texto")
		is_typing = false
		$BottomPanel/StoryText.text = full_text
		$Timer.wait_time = wait_after_text
		$Timer.start()
		print("   -> ⏱️ Timer de espera iniciado: ", wait_after_text, "s (Input bloqueado hasta que termine)")
		
	elif can_advance:
		print("   -> ⏭️ Avanzando de página...")
		advance_page()
		
	else:
		print("   -> ⏳ IGNORADO. El texto ya está completo, pero el Timer de 1s aún no acaba (o la página está cargando).")
func advance_page():
	print("➡️ [PAGINA] Ejecutando advance_page() hacia la página: ", current_page + 1)
	show_page(current_page + 1)

func finish_story():
	print("🏁 [HISTORIA] Terminando historia. Apagando música y cargando el nivel...")
	
	# Detener la música de sinopsis
	if audio_player and audio_player.playing:
		audio_player.stop()
	
	# Fade a negro y cambiar a la escena del juego
	print("🎬 [ANIM] Ejecutando fade_out final...")
	$AnimationPlayer.play("fade_out")
	
	# 🌟 EL SALVAVIDAS: Esperamos medio segundo (lo que dura tu fade_out) en lugar de la señal
	await get_tree().create_timer(0.5).timeout
	
	print("🚀 [VIAJE] ¡Cambiando a la escena del nivel!")
	go_to_next_scene()

func go_to_next_scene():
	# Forzar siempre el cambio a OsirisLevel.tscn
	var tree = get_tree()
	if tree == null:
		push_error("SceneTree is null! Cannot change scene.")
		return

	var osiris_scene_path = "res://Scenes/Levels/levelOsiris/OsirisLevel.tscn"
	var error = tree.change_scene_to_file(osiris_scene_path)
	if error != OK:
		push_error("Failed to load scene: " + osiris_scene_path + " Error code: " + str(error))
	
