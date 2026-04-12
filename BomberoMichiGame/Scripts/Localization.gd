extends Node

var language: String = "es"

var translations = {
	"es": {
		"menu.new_game": "NUEVO JUEGO",
		"menu.continue": "CONTINUAR",
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
		"story.page_1": "Aiden fue durante años uno de los mejores bomberos de su ciudad, salvando a cientos de personas de incendios devastadores.",
		"story.page_2": "Sin embargo, muchos de esos siniestros tenían un origen sobrenatural provocado por Lucifer, quien buscaba extender su fuego hacia el mundo humano.",
		"story.page_3": "Al ver sus planes frustrados constantemente por Aiden, Lucifer decide eliminarlo provocando un incendio imposible de controlar en su propia casa.",
		"story.page_4": "En medio del caos, el demonio secuestra a las dos hijas de Aiden y las arrastra al inframundo.",
		"story.page_5": "Aiden, junto a su gato Osiris, es arrastrado también hacia el infierno.",
		"story.page_6": "Aquí, en las profundidades del infierno, deberá enfrentar sus propios traumas para rescatar a su familia de las garras de Lucifer.",
		"story.page_7": "Apaga el fuego y derrota a los enemigos para poder pasar de nivel y no morir sofocado",
		
		# Pausa
		"pause.title": "PAUSA",
		"pause.continue": "CONTINUAR",
		"pause.save_exit": "GUARDAR Y SALIR",
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
		"cat.rescue_message": "¡Miauu! ¡Lo lograste! Apagaste el fuego y derrotaste a todos los enemigos... ¡gracias a ti estoy a salvo, héroe!",
			"cat.gift_message_resistencia_pulmonar": "¡Gracias a ti pude respirar de nuevo, héroe! Como muestra de gratitud, ¡te transfiero parte de mi fuerza! Tu resistencia pulmonar aumentó un 5%.",
		"cat.gift_message_capacidad_manguera": "¡Purr... toma mi energía, bombero! La presión de tu manguera mejoró: ahora consumirá un 10% menos de agua.",
		"cat.ability_message": "¡Habilidades Adquiridas:\n• Agua Recargable\n• Mejor Capacidad Pulmonar!",
		
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
		"menu.continue": "CONTINUE",
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
		"story.page_1": "Aiden was for years one of the best firefighters in his city, saving hundreds of people from devastating fires.",
		"story.page_2": "However, many of these disasters had a supernatural origin caused by Lucifer, who sought to extend his fire to the human world.",
		"story.page_3": "Seeing his plans constantly frustrated by Aiden, Lucifer decides to eliminate him by causing an uncontrollable fire in his own house.",
		"story.page_4": "In the midst of chaos, the demon kidnaps Aiden's two daughters and drags them to the underworld.",
		"story.page_5": "Aiden, together with his cat Osiris, is also dragged to hell.",
		"story.page_6": "Here, in the depths of hell, he must face his own traumas to rescue his family from Lucifer's claws.",
		"story.page_7": "Put out the fire and defeat the enemies to move on and not die suffocated",
		
		# Pausa
		"pause.title": "PAUSE",
		"pause.continue": "CONTINUE",
		"pause.save_exit": "SAVE & EXIT",
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
		"cat.rescue_message": "Meow! You did it! You put out the fire and defeated all the enemies... thanks to you I'm safe, hero!",
			"cat.gift_message_resistencia_pulmonar": "Thanks to you I could breathe again, hero! As a token of gratitude, I transfer part of my strength to you! Your lung resistance increased by 5%.",
			"cat.gift_message_capacidad_manguera": "Purr... take my energy, firefighter! Your hose pressure improved: it will now consume 10% less water.",
		"cat.ability_message": "Abilities Acquired:\n• Rechargeable Water\n• Better Lung Capacity!",
		
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
		"menu.continue": "CONTINUAR",
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
		"story.page_1": "Aiden foi por anos um dos melhores bombeiros de sua cidade, salvando centenas de pessoas de incêndios devastadores.",
		"story.page_2": "No entanto, muitos desses desastres tinham origem sobrenatural causada por Lúcifer, que buscava estender seu fogo para o mundo humano.",
		"story.page_3": "Vendo seus planos constantemente frustrados por Aiden, Lúcifer decide eliminá-lo provocando um incêndio incontrolável em sua própria casa.",
		"story.page_4": "Em meio ao caos, o demônio sequestra as duas filhas de Aiden e as arrasta para o submundo.",
		"story.page_5": "Aiden, junto com seu gato Osiris, também é arrastado para o inferno.",
		"story.page_6": "Aqui, nas profundezas do inferno, ele deve enfrentar seus próprios traumas para resgatar sua família das garras de Lúcifer.",
		"story.page_7": "Apague o fogo e derrote os inimigos para passar de nível e não morrer sufocado",
		
		# Pausa
		"pause.title": "PAUSA",
		"pause.continue": "CONTINUAR",
		"pause.save_exit": "SALVAR E SAIR",
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
		"cat.rescue_message": "Miau! Você conseguiu! Apagou o fogo e derrotou todos os inimigos... graças a você estou a salvo, herói!",
			"cat.gift_message_resistencia_pulmonar": "Graças a você pude respirar de novo, herói! Como prova de gratidão, transfiro parte da minha força para você! Sua resistência pulmonar aumentou 5%.",
			"cat.gift_message_capacidad_manguera": "Purr... pegue minha energia, bombeiro! A pressão da sua mangueira melhorou: consumirá 10% menos de água.",
		"cat.ability_message": "Habilidades Adquiridas:\n• Água Recarregável\n• Melhor Capacidade Pulmonar!",
		
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
