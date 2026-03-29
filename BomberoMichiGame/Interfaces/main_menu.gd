extends Control

@onready var btn_lang     = $BtnLang
@onready var btn_new_game = $Panel/VBoxContainer/btnNewGame
@onready var btn_options  = $Panel/VBoxContainer/btnOptions
@onready var btn_tutorial = $Panel/VBoxContainer/btnTutorial
@onready var btn_exit     = $Panel/VBoxContainer/btnExit

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
		"new_game": ["res://Assets/menu/NuevoJuegoSin.png",  "res://Assets/menu/NuevoJuego.png"],
		"options":  ["res://Assets/menu/OpcionesSin.png",    "res://Assets/menu/OpcionesEscoger.png"],
		"tutorial": ["res://Assets/menu/TutorialSin.png",    "res://Assets/menu/TutorialEscoger.png"],
		"exit":     ["res://Assets/menu/salirSin.png",       "res://Assets/menu/salirEscoger.png"],
	},
	"en": {
		"new_game": ["res://Assets/menu/NewGameSin.png",     "res://Assets/menu/NewGameEscoger.png"],
		"options":  ["res://Assets/menu/OptionsSin.png",     "res://Assets/menu/OptionsEscoger.png"],
		"tutorial": ["res://Assets/menu/TutorialSin.png",    "res://Assets/menu/TutorialEscoger.png"],
		"exit":     ["res://Assets/menu/ExitSin.png",        "res://Assets/menu/ExitEscoger.png"],
	},
	"pt": {
		"new_game": ["res://Assets/menu/NovoJogoSin.png",    "res://Assets/menu/NovoJogoEscoger.png"],
		"options":  ["res://Assets/menu/OpcoesSin.png",      "res://Assets/menu/OpcoesEscoger.png"],
		"tutorial": ["res://Assets/menu/TutorialSin.png",    "res://Assets/menu/TutorialEscoger.png"],
		"exit":     ["res://Assets/menu/SairSin.png",        "res://Assets/menu/SairEscoger.png"],
	},
}

var lang_index: int = 0

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
	update_texts()

func _process(_delta: float) -> void:
	pass

func _on_btnLang_pressed() -> void:
	lang_index = (lang_index + 1) % 3
	btn_lang.texture_normal = load(LANG_TEXTURES_NORMAL[lang_index])
	btn_lang.texture_hover  = load(LANG_TEXTURES_HOVER[lang_index])
	if has_node("/root/Localization"):
		get_node("/root/Localization").set_language(LANGS[lang_index])

func _on_btnNewGame_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/story_intro.tscn")

func _on_btnOptions_pressed() -> void:
	print("settings pressed")

func _on_btnExit_pressed() -> void:
	get_tree().quit()

func _on_btnTutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/tutorial.tscn")
