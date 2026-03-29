extends Node

var language: String = "es"

var translations = {
	"es": {
		"menu.new_game": "NUEVO JUEGO",
		"menu.options": "OPCIONES",
		"menu.tutorial": "TUTORIAL",
		"menu.exit": "SALIR",
		"options.title": "Selecciona Idioma",
		"lang.spanish": "Español",
		"lang.english": "English",
		"lang.portuguese": "Português",
		
		# Intro
		"intro.skip_hint": "Presiona cualquier tecla para saltar",
		"intro.title": "SOFOCADOS",
		"intro.text": "En un mundo consumido por las llamas...\n\nUn héroe felino debe levantarse para salvar a su ciudad.\n\nEquipado con su manguera y valentía,\ndeberás enfrentarte a las amenazas ardientes.",
		
		# Story intro
		"story.continue_hint": "Presiona cualquier P para saltar y enter para continuar...",
		"story.page": "Página",
		"story.page_1": "Kala, un pueblo acunado por el fuego cerca del Ecuador, producto de ser el destino preferido para los pirómanos, tenía en las llamas su himno eterno.",
		"story.page_2": "Sus noches, teñidas de humo y reflejos amaranjados, habían visto arder templos, mercados y sueños. En esa tierra devorada por el calor, solo los bomberos podían hacer la diferencia.",
		"story.page_3": "Y en esa tierra de fuego, surge un héroe. Un gato bombero, valiente y decidido, listo para enfrentarse a las llamas y salvar a quien sea necesario.",
		
		# Pausa
		"pause.title": "PAUSA",
		"pause.continue": "CONTINUAR",
		"pause.exit_menu": "SALIR AL MENÚ",
		
		# Game Over
		"death.game_over": "GAME OVER",
		"death.continue_question": "Quieres continuar?",
		"death.yes": "Si",
		"death.no": "No",
		
		# Puertas
		"door.enter": "[F] Entrar",
		"door.locked": "🔒 BLOQUEADA",
		
		# NPCs
		"npc.talk": "[F] Hablar",
		"npc.thanks": "¡Gracias por salvarme!",
		
		# HUD
		"hud.life": "Vida",
		"hud.water": "Agua",

		# Tutorial
		"tutorial.title": "CONTROLES",
		"tutorial.hint": "¡Muevete libremente!",
		"tutorial.back": "VOLVER AL MENÚ",
		"tutorial.space_key": "ESPACIO",
		"tutorial.lclick_key": "CLIC IZQ",
		"tutorial.rclick_key": "CLIC DER",
		"tutorial.up": "ARRIBA",
		"tutorial.down": "ABAJO",
		"tutorial.left": "IZQUIERDA",
		"tutorial.right": "DERECHA",
		"tutorial.dash": "DASH / RODAR",
		"tutorial.attack": "ATACAR (hacha/manguera)",
		"tutorial.switch_weapon": "CAMBIAR ARMA",
		"tutorial.interact": "Abrir puertas / siguiente nivel"
	},
	"en": {
		"menu.new_game": "NEW GAME",
		"menu.options": "OPTIONS",
		"menu.tutorial": "TUTORIAL",
		"menu.exit": "EXIT",
		"options.title": "Select Language",
		"lang.spanish": "Spanish",
		"lang.english": "English",
		"lang.portuguese": "Portuguese",
		
		# Intro
		"intro.skip_hint": "Press any key to skip",
		"intro.title": "SUFFOCATED",
		"intro.text": "In a world consumed by flames...\n\nA feline hero must rise to save his city.\n\nEquipped with his hose and courage,\nyou must face the burning threats.",
		
		# Story intro
		"story.continue_hint": "Press P to skip and Enter to continue...",
		"story.page": "Page",
		"story.page_1": "Kala, a town cradled by fire near the Equator, was the preferred destination for arsonists. The flames were its eternal anthem.",
		"story.page_2": "Its nights, tinged with smoke and orange reflections, had witnessed temples, markets and dreams burn. In that land devoured by heat, only firefighters could make a difference.",
		"story.page_3": "And in that land of fire, a hero emerges. A firefighter cat, brave and determined, ready to face the flames and save whoever is necessary.",
		
		# Pausa
		"pause.title": "PAUSE",
		"pause.continue": "CONTINUE",
		"pause.exit_menu": "EXIT TO MENU",
		
		# Game Over
		"death.game_over": "GAME OVER",
		"death.continue_question": "Do you want to continue?",
		"death.yes": "Yes",
		"death.no": "No",
		
		# Puertas
		"door.enter": "[F] Enter",
		"door.locked": "🔒 LOCKED",
		
		# NPCs
		"npc.talk": "[F] Talk",
		"npc.thanks": "Thanks for saving me!",
		
		# HUD
		"hud.life": "Life",
		"hud.water": "Water",

		# Tutorial
		"tutorial.title": "CONTROLS",
		"tutorial.hint": "Move freely!",
		"tutorial.back": "BACK TO MENU",
		"tutorial.space_key": "SPACE",
		"tutorial.lclick_key": "LEFT CLICK",
		"tutorial.rclick_key": "RIGHT CLICK",
		"tutorial.up": "UP",
		"tutorial.down": "DOWN",
		"tutorial.left": "LEFT",
		"tutorial.right": "RIGHT",
		"tutorial.dash": "DASH / ROLL",
		"tutorial.attack": "ATTACK (axe/hose)",
		"tutorial.switch_weapon": "SWITCH WEAPON",
		"tutorial.interact": "Open doors / next level"
	},
	"pt": {
		"menu.new_game": "NOVO JOGO",
		"menu.options": "OPÇÕES",
		"menu.tutorial": "TUTORIAL",
		"menu.exit": "SAIR",
		"options.title": "Selecione Idioma",
		"lang.spanish": "Espanhol",
		"lang.english": "Inglês",
		"lang.portuguese": "Português",
		
		# Intro
		"intro.skip_hint": "Pressione qualquer tecla para pular",
		"intro.title": "SUFOCADOS",
		"intro.text": "Em um mundo consumido por chamas...\n\nUm herói felino deve se levantar para salvar sua cidade.\n\nEquipado com sua mangueira e coragem,\nvocê deve enfrentar as ameaças ardentes.",
		
		# Story intro
		"story.continue_hint": "Pressione P para pular e Enter para continuar...",
		"story.page": "Página",
		"story.page_1": "Kala, uma cidade acunada pelo fogo perto do Equador, era o destino preferido dos piromaníacos. As chamas eram seu hino eterno.",
		"story.page_2": "Suas noites, tingidas de fumaça e reflexos laranja, haviam testemunhado templos, mercados e sonhos queimarem. Naquela terra devorada pelo calor, apenas os bombeiros poderiam fazer diferença.",
		"story.page_3": "E naquela terra de fogo, emerge um herói. Um gato bombeiro, valente e determinado, pronto para enfrentar as chamas e salvar quem for necessário.",
		
		# Pausa
		"pause.title": "PAUSA",
		"pause.continue": "CONTINUAR",
		"pause.exit_menu": "SAIR PARA O MENU",
		
		# Game Over
		"death.game_over": "GAME OVER",
		"death.continue_question": "Você quer continuar?",
		"death.yes": "Sim",
		"death.no": "Não",
		
		# Puertas
		"door.enter": "[F] Entrar",
		"door.locked": "🔒 BLOQUEADO",
		
		# NPCs
		"npc.talk": "[F] Falar",
		"npc.thanks": "Obrigado por me salvar!",
		
		# HUD
		"hud.life": "Vida",
		"hud.water": "Água",

		# Tutorial
		"tutorial.title": "CONTROLES",
		"tutorial.hint": "Mova-se livremente!",
		"tutorial.back": "VOLTAR AO MENU",
		"tutorial.space_key": "ESPAÇO",
		"tutorial.lclick_key": "CLIC ESQ",
		"tutorial.rclick_key": "CLIC DIR",
		"tutorial.up": "ACIMA",
		"tutorial.down": "ABAIXO",
		"tutorial.left": "ESQUERDA",
		"tutorial.right": "DIREITA",
		"tutorial.dash": "DASH / ROLAR",
		"tutorial.attack": "ATACAR (machado/mangueira)",
		"tutorial.switch_weapon": "TROCAR ARMA",
		"tutorial.interact": "Abrir portas / próximo nível"
	}
}

func _ready() -> void:
	pass

func set_language(lang: String) -> void:
	if translations.has(lang):
		language = lang
		print("🌍 Idioma cambiado a: ", lang)
		print("📢 Llamando update_texts() al grupo 'localizable'")
		get_tree().call_group("localizable", "update_texts")
		print("✅ Grupo 'localizable' actualizado")

func translate(key: String) -> String:
	if translations.has(language) and translations[language].has(key):
		return translations[language][key]
	if translations["es"].has(key):
		return translations["es"][key]
	return key
