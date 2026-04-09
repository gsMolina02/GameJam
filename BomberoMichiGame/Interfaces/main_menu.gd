extends Control

@onready var btn_lang     = $BtnLang
@onready var btn_new_game = $Panel/VBoxContainer/btnNewGame
@onready var btn_options  = $Panel/VBoxContainer/btnOptions
@onready var btn_tutorial = $Panel/VBoxContainer/btnTutorial
@onready var btn_exit     = $Panel/VBoxContainer/btnExit
@onready var btn_credits  = $Panel/btnCredits

var btn_continue: TextureButton = null  # Creado programáticamente
var capa_creditos: CanvasLayer = null
var reproductor_creditos: VideoStreamPlayer = null

const LANGS = ["es", "en", "pt"]
const LANG_TEXTURES_NORMAL = [
	"res://Assets/menu/LangESPSin.png",
	"res://Assets/menu/LangENGSin.png",
	"res://Assets/menu/LangBRSin.png",
]
const LANG_TEXTURES_HOVER = [
	"res://Assets/menu/LangESPEscoger.png",
	"res://Assets/menu/LangENGEscoger.png",
	"res://Assets/menu/LangBREscoger.png",
]

# [normal, hover] per button per language
const MENU_TEXTURES = {
	"es": {
		"continue": ["res://Assets/menu/ContinuarSin.png",   "res://Assets/menu/ContinuarEscoger.png"],
		"new_game": ["res://Assets/menu/NuevoJuegoSin.png",  "res://Assets/menu/NuevoJuego.png"],
		"options":  ["res://Assets/menu/OpcionesSin.png",    "res://Assets/menu/OpcionesEscoger.png"],
		"tutorial": ["res://Assets/menu/TutorialSin.png",    "res://Assets/menu/TutorialEscoger.png"],
		"exit":     ["res://Assets/menu/salirSin.png",       "res://Assets/menu/salirEscoger.png"],
	},
	"en": {
		"continue": ["res://Assets/menu/ContinueSin.png",    "res://Assets/menu/ContinueEscoger.png"],
		"new_game": ["res://Assets/menu/NewGameSin.png",     "res://Assets/menu/NewGameEscoger.png"],
		"options":  ["res://Assets/menu/OptionsSin.png",     "res://Assets/menu/OptionsEscoger.png"],
		"tutorial": ["res://Assets/menu/TutorialSin.png",    "res://Assets/menu/TutorialEscoger.png"],
		"exit":     ["res://Assets/menu/ExitSin.png",        "res://Assets/menu/ExitEscoger.png"],
	},
	"pt": {
		"continue": ["res://Assets/menu/ContinuarPTSin.png", "res://Assets/menu/ContinuarPTEscoger.png"],
		"new_game": ["res://Assets/menu/NovoJogoSin.png",    "res://Assets/menu/NovoJogoEscoger.png"],
		"options":  ["res://Assets/menu/OpcoesSin.png",      "res://Assets/menu/OpcoesEscoger.png"],
		"tutorial": ["res://Assets/menu/TutorialSin.png",    "res://Assets/menu/TutorialEscoger.png"],
		"exit":     ["res://Assets/menu/SairSin.png",        "res://Assets/menu/SairEscoger.png"],
	},
}

var lang_index: int = 0

func _t(key: String) -> String:
	if has_node("/root/Localization"):
		return get_node("/root/Localization").translate(key)
	return key

func update_texts() -> void:
	var lang = LANGS[lang_index]
	var t = MENU_TEXTURES[lang]
	if btn_new_game:
		btn_new_game.texture_normal = load(t["new_game"][0])
		btn_new_game.texture_hover  = load(t["new_game"][1])
	if btn_options:
		btn_options.texture_normal  = load(t["options"][0])
		btn_options.texture_hover   = load(t["options"][1])
	if btn_tutorial:
		btn_tutorial.texture_normal = load(t["tutorial"][0])
		btn_tutorial.texture_hover  = load(t["tutorial"][1])
	if btn_exit:
		btn_exit.texture_normal     = load(t["exit"][0])
		btn_exit.texture_hover      = load(t["exit"][1])
	if btn_continue:
		btn_continue.texture_normal = load(t["continue"][0])
		btn_continue.texture_hover  = load(t["continue"][1])

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	add_to_group("localizable")
	# Sync to current language from singleton
	if has_node("/root/Localization"):
		var loc = get_node("/root/Localization")
		lang_index = LANGS.find(loc.language)
		if lang_index < 0: lang_index = 0
	btn_lang.texture_normal = load(LANG_TEXTURES_NORMAL[lang_index])
	btn_lang.texture_hover  = load(LANG_TEXTURES_HOVER[lang_index])
	
	# Crear el botón "Continuar" encima de "Nuevo Juego" si hay partida guardada
	_setup_continue_button()
	
	update_texts()
	btn_credits.pressed.connect(_on_btnCreditos_pressed)

func _setup_continue_button() -> void:
	"""Crea el botón Continuar solo si existe un archivo de guardado."""
	if not SaveManager.has_save():
		return
    
	btn_continue = TextureButton.new()
	btn_continue.name = "btnContinue"

	# Insertar ANTES de "Nuevo Juego" (posición 0 en el VBoxContainer)
	var vbox = $Panel/VBoxContainer
	vbox.add_child(btn_continue)
	vbox.move_child(btn_continue, 0)

	btn_continue.pressed.connect(_on_btnContinue_pressed)
	print("▶️ Botón Continuar creado (partida guardada encontrada)")


func _process(_delta: float) -> void:
	pass

func _on_btnLang_pressed() -> void:
	lang_index = (lang_index + 1) % 3
	btn_lang.texture_normal = load(LANG_TEXTURES_NORMAL[lang_index])
	btn_lang.texture_hover  = load(LANG_TEXTURES_HOVER[lang_index])
	if has_node("/root/Localization"):
		get_node("/root/Localization").set_language(LANGS[lang_index])

func _on_btnContinue_pressed() -> void:
	"""Carga la partida guardada y lleva al jugador al nivel guardado."""
	var save_data = SaveManager.load_game()
	if save_data.is_empty():
		push_warning("⚠️ No se encontraron datos de guardado")
		return
	
	# Volcar datos del guardado en GameManager para que el nivel los restaure
	GameManager.vida_jugador          = save_data.get("vida_actual",     100.0)
	GameManager.vida_maxima_jugador   = save_data.get("vida_maxima",     100.0)
	GameManager.agua_jugador          = save_data.get("hose_charge",     100.0)
	GameManager.hose_drain_rate_jugador = save_data.get("hose_drain_rate", 4.0)
	GameManager.puerta_origen         = ""  # Ya no depende de puertas, cargará en posición exacta
	
	# Restaurar estado del mundo
	GameManager.nodos_destruidos = save_data.get("nodos_destruidos", [])
	if save_data.has("pos_x") and save_data.has("pos_y"):
		GameManager.posicion_guardada = Vector2(save_data.get("pos_x"), save_data.get("pos_y"))
	else:
		GameManager.posicion_guardada = Vector2.INF
	
	var scene_path: String = save_data.get("scene_path", "")
	if scene_path == "":
		push_error("❌ El guardado no tiene scene_path válida")
		return
	
	print("▶️ Cargando partida → escena:", scene_path)
	get_tree().change_scene_to_file(scene_path)

func _on_btnNewGame_pressed() -> void:
	# Borrar guardado anterior al iniciar nueva partida
	if SaveManager.has_save():
		SaveManager.delete_save()
		print("🗑️ Guardado previo eliminado al iniciar Nuevo Juego")
	
	# Resetear estado del GameManager
	GameManager.reset_estado()
	
	get_tree().change_scene_to_file("res://Interfaces/story_intro.tscn")

func _on_btnOptions_pressed() -> void:
	print("settings pressed")

func _on_btnExit_pressed() -> void:
	get_tree().quit()

func _on_btnTutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/tutorial.tscn")

func _on_btnCreditos_pressed() -> void:
	if capa_creditos != null:
		return
    
	print("Mostrando video de Créditos...")

	# 1. Crear la capa y el fondo negro
	capa_creditos = CanvasLayer.new()
	capa_creditos.layer = 128
	add_child(capa_creditos)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_creditos.add_child(bg)

	# 2. Cargar el video
	var video_stream = load("res://Assets/creditos/creditosFInal.ogv")
	if video_stream == null:
		print("❌ ERROR: No se encontró el video.")
		_cerrar_creditos() # Cerramos todo para no quedar en pantalla negra
		return

	# 3. Configurar el reproductor
	reproductor_creditos = VideoStreamPlayer.new()
	reproductor_creditos.stream = video_stream
	reproductor_creditos.expand = true
	reproductor_creditos.set_anchors_preset(Control.PRESET_FULL_RECT)
	reproductor_creditos.volume_db = 0.0 

	capa_creditos.add_child(reproductor_creditos)
	reproductor_creditos.play()
	reproductor_creditos.finished.connect(_cerrar_creditos)

	# --- AQUÍ PAUSAMOS TU MÚSICA ---
	if has_node("AudioStreamPlayer2D"): 
		$AudioStreamPlayer2D.stream_paused = true

func _cerrar_creditos() -> void:
	if capa_creditos:
		capa_creditos.queue_free()
		capa_creditos = null
		reproductor_creditos = null
        
		# --- AQUÍ REANUDAMOS TU MÚSICA ---
		if has_node("AudioStreamPlayer2D"):
			$AudioStreamPlayer2D.stream_paused = false


func _input(event: InputEvent) -> void:
	# 1. Si la capa no existe (no hay video), no hacemos nada y salimos rápido
	if capa_creditos == null:
		return
    
	# 2. Comprobamos que sea una tecla, que se haya presionado (no soltado) 
	# y que no sea un "echo" (mantenerla presionada)
	if event is InputEventKey and event.pressed and not event.echo:
		# 3. Detectamos la 'P' o la tecla 'Escape'
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			# Consumimos el input para que el menú de atrás no lo reciba por error
			get_viewport().set_input_as_handled() 
			# Cerramos el video
			_cerrar_creditos()