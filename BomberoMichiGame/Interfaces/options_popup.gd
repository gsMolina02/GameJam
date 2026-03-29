extends Panel

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var btn_es = $MarginContainer/VBoxContainer/LanguageContainer/BtnSpanish
@onready var btn_en = $MarginContainer/VBoxContainer/LanguageContainer/BtnEnglish
@onready var btn_pt = $MarginContainer/VBoxContainer/LanguageContainer/BtnPortuguese

func _ready() -> void:
	add_to_group("localizable")
	update_texts()
	
	# Conectar botones
	btn_es.pressed.connect(_on_spanish_pressed)
	btn_en.pressed.connect(_on_english_pressed)
	btn_pt.pressed.connect(_on_portuguese_pressed)

func update_texts() -> void:
	if has_node("/root/Localization"):
		var loc = get_node("/root/Localization")
		title_label.text = loc.translate("options.title")
		btn_es.text = loc.translate("lang.spanish")
		btn_en.text = loc.translate("lang.english")
		btn_pt.text = loc.translate("lang.portuguese")

func _on_spanish_pressed() -> void:
	print("🇪🇸 Botón Español presionado")
	if has_node("/root/Localization"):
		print("✅ Localization encontrado")
		get_node("/root/Localization").set_language("es")
	else:
		print("❌ Localization NO encontrado!")
	await get_tree().process_frame
	hide()

func _on_english_pressed() -> void:
	print("🇬🇧 Botón English presionado")
	if has_node("/root/Localization"):
		print("✅ Localization encontrado")
		get_node("/root/Localization").set_language("en")
	else:
		print("❌ Localization NO encontrado!")
	await get_tree().process_frame
	hide()

func _on_portuguese_pressed() -> void:
	print("🇧🇷 Botón Português presionado")
	if has_node("/root/Localization"):
		print("✅ Localization encontrado")
		get_node("/root/Localization").set_language("pt")
	else:
		print("❌ Localization NO encontrado!")
	await get_tree().process_frame
	hide()
