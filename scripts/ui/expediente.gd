class_name Expediente
extends Control
## "Expediente" (Block 9): the catalog of cards and enemies of the career.
## Two tabs (Cartas, Enemigos) list everything that appears in campaign.tres,
## in the order the player meets it, so a card or enemy added to a level in
## the Inspector appears here without touching scripts.
## What the player has not met yet is a black silhouette called "???".
## A tap on an entry shows its file on the right: picture, name, description
## and its stats in words ("Muy rápido", "Aguanta mucho").
## Back (button or Android) returns to Inicio.

const ENTRY_SIZE := Vector2(130, 150)
const SILHOUETTE := Color(0, 0, 0, 0.85)

@onready var back_button: Button = %BackButton
@onready var counter_label: Label = %Counter
@onready var cards_grid: GridContainer = %CardsGrid
@onready var enemies_grid: GridContainer = %EnemiesGrid
@onready var detail_image: TextureRect = %DetailImage
@onready var detail_name: Label = %DetailName
@onready var detail_stats: Label = %DetailStats
@onready var detail_description: Label = %DetailDescription


func _ready() -> void:
	AudioManager.play_music(AudioManager.MENU_MUSIC)  # it keeps playing if it already was
	back_button.pressed.connect(_go_back)
	var cards := all_cards(GameSession.campaign)
	var enemies := all_enemies(GameSession.campaign)
	var known_count := 0
	for card in cards:
		known_count += _add_entry(cards_grid, card, "cards")
	for enemy in enemies:
		known_count += _add_entry(enemies_grid, enemy, "enemies")
	counter_label.text = "Conocidos: %d de %d" % [known_count, cards.size() + enemies.size()]


# --- Catalog (static, so other scripts and the tests can use it) ---

## Every card of the campaign without repeats: the cards of each level, in
## order, and the cards won as a reward.
static func all_cards(campaign: CampaignData) -> Array[DefenderType]:
	var cards: Array[DefenderType] = []
	for world in campaign.worlds:
		for level in world.levels:
			for card in level.defenders + [level.reward_card]:
				if card and not card in cards:
					cards.append(card)
	return cards


## Every enemy of the campaign without repeats, in the order they appear in
## the waves, with the enemies that a boss calls (in both phases) or that appear
## when one splits.
static func all_enemies(campaign: CampaignData) -> Array[EnemyType]:
	var enemies: Array[EnemyType] = []
	for world in campaign.worlds:
		for level in world.levels:
			for wave in level.waves:
				for event in wave.events:
					_add_enemy(enemies, event.enemy_type)
	return enemies


static func _add_enemy(enemies: Array[EnemyType], enemy: EnemyType) -> void:
	if enemy == null or enemy in enemies:
		return
	enemies.append(enemy)
	_add_enemy(enemies, enemy.summon_type)
	_add_enemy(enemies, enemy.split_into)
	_add_enemy(enemies, enemy.phase2_summon_type)


# --- Stats in words ---

## "Cuesta 75 de energía · Aguanta muchísimo · Tarda en recargarse"
static func card_summary(card: DefenderType) -> String:
	var lines := ["Cuesta %d de energía" % card.cost, _card_action(card)]
	if card.health < 500:
		lines.append("Aguanta poco")
	elif card.health < 1000:
		lines.append("Aguanta bastante")
	else:
		lines.append("Aguanta muchísimo")
	if card.cooldown <= 8.0:
		lines.append("Se recarga rápido")
	elif card.cooldown <= 15.0:
		lines.append("Se recarga a ritmo normal")
	else:
		lines.append("Tarda en recargarse")
	return "\n".join(lines)


## What the card does, read from its behavior scene (generator, shooter,
## blocker or instant) and its numbers.
static func _card_action(card: DefenderType) -> String:
	if card.behavior_scene == null:
		return ""
	var behavior := card.behavior_scene.instantiate()  # only to know its type; never added to the game
	var action := "Frena a los enemigos"
	if behavior is GeneratorDefender:
		action = "Da %d de energía cada %d s" % [card.energy_per_orb, card.orb_interval]
	elif behavior is ShooterDefender:
		action = "Dispara cada %s s" % str(card.fire_interval)
		if card.slow_factor < 1.0 and card.slow_time > 0.0:
			action += "\nFrena al enemigo (%d %%) durante %s s" % [roundi((1.0 - card.slow_factor) * 100.0), _number(card.slow_time)]
	elif behavior is InstantDefender:
		var side := roundi(card.area_radius) * 2 + 1
		action = "Borra a los enemigos de un área de %d × %d y desaparece" % [side, side]
	behavior.free()
	return action


## "3" for 3.0, "0.75" for 0.75.
static func _number(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value, roundf(value)) else str(value)


## "Muy rápido · Aguanta poco · Muerde normal"
static func enemy_summary(enemy: EnemyType) -> String:
	var lines: Array[String] = []
	if enemy.is_boss:
		lines.append("Jefe del semestre")
	if enemy.speed < 0.2:
		lines.append("Muy lento")
	elif enemy.speed < 0.4:
		lines.append("Camina a paso normal")
	elif enemy.speed < 0.5:
		lines.append("Rápido")
	else:
		lines.append("Muy rápido")
	if enemy.health < 150.0:
		lines.append("Aguanta poco")
	elif enemy.health < 400.0:
		lines.append("Aguanta lo normal")
	elif enemy.health < 1000.0:
		lines.append("Aguanta mucho")
	else:
		lines.append("Aguanta muchísimo")
	lines.append("Muerde muy fuerte" if enemy.damage_per_second >= 50.0 else "Muerde normal")
	if enemy.armor_health > 0.0:
		lines.append("Trae armadura")
	if enemy.split_into and enemy.split_count > 0:
		lines.append("Al caer se divide en %d" % enemy.split_count)
	if enemy.jumps_first_defender:
		lines.append("Salta a tu primer defensor")
	if enemy.summon_type:
		lines.append("Llama a: %s" % enemy.summon_type.display_name)
	if enemy.phase2_summon_type and enemy.phase2_summon_type != enemy.summon_type:
		lines.append("Furioso llama a: %s" % enemy.phase2_summon_type.display_name)
	return " · ".join(lines)


# --- Entries and file ---

## One button of the grid. Returns 1 if the player knows it (for the counter), else 0.
func _add_entry(grid: GridContainer, type: Resource, kind: String) -> int:
	var known := ProgressRepository.is_known(kind, type)
	var button := Button.new()
	button.custom_minimum_size = ENTRY_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.icon = type.texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override("font_size", 16)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text = type.display_name if known else "???"
	if not known:
		for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			button.add_theme_color_override(state, SILHOUETTE)  # black silhouette
	button.pressed.connect(_show_file.bind(type, kind, known))
	grid.add_child(button)
	return 1 if known else 0


## The file of the right side.
func _show_file(type: Resource, kind: String, known: bool) -> void:
	detail_image.texture = type.texture
	detail_image.modulate = Color.WHITE if known else SILHOUETTE
	if not known:
		detail_name.text = "???"
		detail_stats.text = ""
		detail_description.text = "Aún no lo conoces. Sigue jugando para descubrirlo."
		return
	detail_name.text = type.display_name
	detail_stats.text = card_summary(type as DefenderType) if kind == "cards" else enemy_summary(type as EnemyType).replace(" · ", "\n")
	detail_description.text = type.description


func _go_back() -> void:
	SceneTransition.change_scene(GameSession.MAIN_MENU_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		_go_back()
