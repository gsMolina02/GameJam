extends Control

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

@export var story_pages: Array[Dictionary] = [
	{"image": "res://Assets/sinopsis/1.png", "key": "story.page_1"},
	{"image": "res://Assets/sinopsis/2.png", "key": "story.page_2"},
	{"image": "res://Assets/sinopsis/3.png", "key": "story.page_3"},
	{"video": "res://Assets/sinopsis/caidaHijasAiden.ogv", "key": "story.page_4"},
	{"image": "res://Assets/sinopsis/5.png", "key": "story.page_5"},
	{"video": "res://Assets/sinopsis/caidaAiden.ogv", "key": "story.page_6"},
	{"key": "story.page_7"}
]

@export var synopsis_music_path: String = "res://Assets/musica/Sinopsis.ogg"
@export var synopsis_music_volume: float = -12.0
@export var next_scene: String = "res://Scenes/Levels/levelOsiris/OsirisLevel.tscn"
@export var typing_speed: float = 40.0
@export var wait_after_text: float = 1.0
@export var final_page_wait_time: float = 3.0  # Segundos que durará el mensaje final

var audio_player: AudioStreamPlayer
var current_page: int = 0
var current_char: int = 0
var is_typing: bool = false
var can_advance: bool = false
var full_text: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$Timer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Engine.time_scale = 1.0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Iniciar carga en segundo plano
	var osiris_scene_path = "res://Scenes/Levels/levelOsiris/OsirisLevel.tscn"
	
	print("🕵️‍♂️ [CARGA SECRETA] Iniciando precarga CORRECTA de: ", osiris_scene_path)
	ResourceLoader.load_threaded_request(osiris_scene_path)
	
	setup_synopsis_music()
	update_texts()
	add_to_group("localizable")
	call_deferred("show_page", 0)

func show_page(page_index: int):
	if page_index >= story_pages.size():
		finish_story()
		return
	
	current_page = page_index
	can_advance = false
	is_typing = false
	
	if has_node("BottomPanel/StoryText"):
		$BottomPanel/StoryText.text = ""
		
	full_text = _t("story.page_" + str(page_index + 1))
	
	if current_page > 0:
		$AnimationPlayer.play("fade_out")
		await get_tree().create_timer(0.5).timeout 
	
	var page_data = story_pages[current_page]
	_setup_visuals(page_data)
	
	$AnimationPlayer.play("fade_in")
	await get_tree().create_timer(0.85).timeout 
	
	start_typing()

func _setup_visuals(data):
	$VideoPlayer.visible = data.has("video")
	$StoryImage.visible = data.has("image")
	$BottomPanel.visible = data.has("image") or data.has("video")
	$StoryFrame.visible = $BottomPanel.visible
	$BlackPanel.visible = not $BottomPanel.visible

	if data.has("image"):
		$StoryImage.texture = load(data["image"])
	elif data.has("video"):
		$VideoPlayer.stream = load(data["video"])
		if $VideoPlayer.stream: $VideoPlayer.play()

func start_typing():
	is_typing = true
	current_char = 0
	while current_char < full_text.length() and is_typing:
		$BottomPanel/StoryText.text = full_text.substr(0, current_char + 1)
		current_char += 1
		await get_tree().create_timer(1.0 / typing_speed).timeout
	
	if is_typing:
		is_typing = false
		if current_page == 6: 
			$Timer.wait_time = final_page_wait_time
			print("⏳ [FINAL] Texto terminado. Esperando %s segundos antes de iniciar juego..." % final_page_wait_time)
		else:
			$Timer.wait_time = wait_after_text
		$Timer.start()

func _on_timer_timeout():
	if current_page == 6: # Si es la última página (story.page_7)
		print("⏰ [TIMER] Tiempo final agotado. Transición automática...")
		finish_story()
	else:
		can_advance = true
		print("⏰ [TIMER] Espera terminada. Enter para seguir.")

func _input(event):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_P:
			go_to_next_scene()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			handle_input()
	elif event is InputEventMouseButton and event.is_pressed():
		handle_input()

func handle_input():
	if is_typing:
		is_typing = false
		$BottomPanel/StoryText.text = full_text
		$Timer.wait_time = wait_after_text
		$Timer.start()
	elif can_advance or current_page == 6:
		if current_page == 6:
			finish_story()
		else:
			show_page(current_page + 1)

func finish_story():
	if audio_player: audio_player.stop()
	$AnimationPlayer.play("fade_out")
	await get_tree().create_timer(0.5).timeout
	go_to_next_scene()



func update_texts():
	if has_node("BottomPanel/ContinueHint"):
		$BottomPanel/ContinueHint.text = _t("story.continue_hint")
		
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


func go_to_next_scene():
	# Forzar siempre el cambio a OsirisLevel.tscn con tu estructura obligatoria
	var tree = get_tree()
	if tree == null:
		push_error("SceneTree is null! Cannot change scene.")
		return

	# Declaración obligatoria según tu requerimiento
	var osiris_scene_path = "res://Scenes/Levels/levelOsiris/OsirisLevel.tscn"
	
	print("🚀 [VIAJE] Solicitando cambio de escena hacia: ", osiris_scene_path)

	# ⚡ INTENTO DE CARGA OPTIMIZADA (Si el hilo terminó en segundo plano)
	var status = ResourceLoader.load_threaded_get_status(osiris_scene_path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		print("⚡ [CARGA INSTANTÁNEA] Nivel recuperado de la RAM.")
		var packed_scene = ResourceLoader.load_threaded_get(osiris_scene_path)
		tree.change_scene_to_packed(packed_scene)
	else:
		# 🛡️ TU BLOQUE DE RESPALDO (Aparecerá "Carga Clásica" en logs si el hilo no terminó)
		print("⚠️ [CARGA CLÁSICA] Usando método normal (Fallback).")
		var error = tree.change_scene_to_file(osiris_scene_path)
		if error != OK:
			push_error("Failed to load scene: " + osiris_scene_path + " Error code: " + str(error))