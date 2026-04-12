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
	# Mostrar el cursor del sistema en la intro de historia
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Validar que tengamos páginas configuradas
	if story_pages.is_empty():
		push_error("No hay páginas de historia configuradas!")
		go_to_next_scene()
		return
	
	# Configurar y reproducir la música de sinopsis
	setup_synopsis_music()
	
	# Actualizar textos traducidos
	update_texts()
	
	# Mostrar la primera página
	show_page(0)
	
	# Agregar a grupo de actualización de textos
	add_to_group("localizable")

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
		# Ya no hay más páginas, ir a la siguiente escena
		finish_story()
		return
	
	current_page = page_index
	can_advance = false
	
	# Actualizar indicador de página (comentado - no existe en la escena)
	# $PageIndicator.text = str(current_page + 1) + "/" + str(story_pages.size())
	
	# Fade out de la imagen actual
	if current_page > 0:
		$AnimationPlayer.play("fade_out")
		await $AnimationPlayer.animation_finished
	
	# Cargar nueva página (imagen o video)
	var page_data = story_pages[current_page]
	
	# Si es una imagen
	if page_data.has("image"):
		# Asegurar que el VideoPlayer está oculto y mostrar imagen
		$VideoPlayer.visible = false
		$StoryImage.visible = true
		$BlackPanel.visible = false
		$BottomPanel.visible = true
		$StoryFrame.visible = true
		
		var texture = load(page_data["image"])
		if texture:
			$StoryImage.texture = texture
		else:
			push_warning("No se pudo cargar la imagen: " + page_data["image"])
	
	# Si es un video
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
			push_warning("No se pudo cargar el video: " + video_path)
	
	# Si es solo texto (página final con panel negro)
	else:
		$StoryImage.visible = false
		$VideoPlayer.visible = false
		$BlackPanel.visible = true
		$BottomPanel.visible = false
		$StoryFrame.visible = false
	
	# Fade in
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	
	# Iniciar texto
	$BottomPanel/StoryText.text = ""
	full_text = _t("story.page_" + str(page_index + 1))
	
	# Iniciar efecto de escritura
	start_typing()

func start_typing():
	is_typing = true
	current_char = 0
	
	while current_char < full_text.length() and is_typing:
		$BottomPanel/StoryText.text = full_text.substr(0, current_char + 1)
		current_char += 1
		await get_tree().create_timer(1.0 / typing_speed).timeout
	
	# Cuando termina de escribir
	if is_typing:
		is_typing = false
		$Timer.wait_time = wait_after_text
		$Timer.start()

func _on_timer_timeout():
	can_advance = true

func _input(event):
	# Verificamos si es un evento de teclado presionado
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_P:
			is_typing = false
			go_to_next_scene()
			return
		elif event.keycode == KEY_ENTER:
			handle_input()
	elif event is InputEventMouseButton and event.is_pressed():
		handle_input()

func handle_input():
	if is_typing:
		# Si está escribiendo, mostrar todo el texto inmediatamente
		is_typing = false
		$BottomPanel/StoryText.text = full_text
		$Timer.wait_time = wait_after_text
		$Timer.start()
	elif can_advance:
		# Si ya terminó, avanzar a la siguiente página
		advance_page()

func advance_page():
	show_page(current_page + 1)

func finish_story():
	# Detener la música de sinopsis
	if audio_player and audio_player.playing:
		audio_player.stop()
	
	# Fade a negro y cambiar a la escena del juego
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
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
	
