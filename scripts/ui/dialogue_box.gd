class_name DialogueBox
extends CanvasLayer
## The Director's dialogue box (Block 9). It shows the lines of a DialogueData
## one by one: the portrait of the speaker on the left, the name, and the text
## written letter by letter (a Tween on visible_ratio).
##   - One tap on the screen completes the line; the next tap shows the next line.
##   - "Saltar" ends the conversation at once.
##   - A line with show_card / show_enemy also shows that card or enemy in the
##     middle of the screen ("¡Nueva carta!" / "Nuevo en tu expediente").
## While it talks, the game is paused (get_tree().paused). This node keeps
## working because its process mode is "Always". It emits finished at the end.
##
## Usage from any screen that has one:
##     await dialogue_box.play_once(level.intro_dialogue)

## The conversation ended (last line, or "Saltar").
signal finished

## Picture of each expression: art/director/<expression>.png (DialogueLine.expression).
const PORTRAIT_PATH := "res://art/director/%s.png"
## Seconds per letter of the typewriter effect.
const LETTER_TIME := 0.03
## The portrait slides in from the left in this time.
const SLIDE_TIME := 0.35
## X of the portrait when it is in its place (its offset_left in the scene).
const PORTRAIT_X := 10.0
## The portrait "breathes": its scale goes 1.00 -> 1.02 -> 1.00 every 2 x BREATH_TIME seconds.
const BREATH_SCALE := 1.02
const BREATH_TIME := 1.2

## Conversation being shown and the position of its current line.
var dialogue: DialogueData
var line_index := 0
## The game was already paused when the conversation started (for example,
## after a victory), so it must stay paused when it ends.
var _was_paused := false
var _typing_tween: Tween
var _breath_tween: Tween

@onready var dim: ColorRect = $Dim
@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var continue_label: Label = %ContinueLabel
@onready var skip_button: Button = %SkipButton
@onready var presentation: Control = %Presentation
@onready var presentation_card: PanelContainer = %PresentationCard
@onready var presentation_title: Label = %PresentationTitle
@onready var presentation_image: TextureRect = %PresentationImage
@onready var presentation_name: Label = %PresentationName
@onready var presentation_info: Label = %PresentationInfo
@onready var presentation_description: Label = %PresentationDescription


func _ready() -> void:
	hide()
	dim.gui_input.connect(_on_dim_gui_input)
	skip_button.pressed.connect(finish)


## True while a conversation is on screen. The screen that owns the box asks
## it before handling the Android back button (back = "Saltar").
func is_open() -> bool:
	return visible


## Shows a conversation only if the player has not seen it before, waits until
## it ends and remembers it (ProgressRepository), so replaying a level does not
## repeat it. Nothing happens with null, with no lines or if it was already seen.
func play_once(conversation: DialogueData) -> void:
	if conversation == null or conversation.lines.is_empty():
		return
	if conversation.id != "" and ProgressRepository.has_seen_dialogue(conversation.id):
		return
	play(conversation)
	await finished
	if conversation.id != "":  # a conversation without id is shown every time
		ProgressRepository.mark_dialogue_seen(conversation.id)


## Shows a conversation from its first line (seen or not).
func play(conversation: DialogueData) -> void:
	dialogue = conversation
	line_index = 0
	_was_paused = get_tree().paused
	get_tree().paused = true  # the game waits while the Director talks
	show()
	_slide_portrait_in()
	_show_line()


## One tap: completes the line being written, or goes to the next line.
func advance() -> void:
	if is_typing():
		_typing_tween.kill()
		_finish_typing()
		return
	line_index += 1
	if line_index < dialogue.lines.size():
		_show_line()
	else:
		finish()


## True while the current line is still being written.
func is_typing() -> bool:
	return text_label.visible_ratio < 1.0


## Ends the conversation ("Saltar", the last tap or the Android back button).
func finish() -> void:
	if not visible:
		return
	if _typing_tween:
		_typing_tween.kill()
	if _breath_tween:
		_breath_tween.kill()
	hide()
	get_tree().paused = _was_paused
	finished.emit()


func _show_line() -> void:
	var line := dialogue.lines[line_index]
	name_label.text = line.speaker
	portrait.texture = load(PORTRAIT_PATH % line.expression)
	text_label.text = line.text
	text_label.visible_ratio = 0.0
	continue_label.hide()
	_typing_tween = create_tween()  # it belongs to this node, so it runs while the game is paused
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, maxf(line.text.length() * LETTER_TIME, 0.1))
	_typing_tween.finished.connect(_finish_typing)
	_show_presentation(line)


func _finish_typing() -> void:
	text_label.visible_ratio = 1.0
	continue_label.show()


## "¡Nueva carta!" or "Nuevo en tu expediente" in the middle of the screen,
## only for lines that bring a card or an enemy. Once presented, it appears
## in the Expediente.
func _show_presentation(line: DialogueLine) -> void:
	if line.show_card:
		var card := line.show_card
		presentation_title.text = "¡Nueva carta!"
		presentation_image.texture = card.icon if card.icon else card.texture
		presentation_name.text = card.display_name
		presentation_info.text = "Cuesta %d de energía" % card.cost
		presentation_description.text = card.description
		ProgressRepository.mark_known("cards", [card])
	elif line.show_enemy:
		var enemy := line.show_enemy
		presentation_title.text = "Nuevo en tu expediente"
		presentation_image.texture = enemy.texture
		presentation_name.text = enemy.display_name
		presentation_info.text = Expediente.enemy_summary(enemy)
		presentation_description.text = enemy.description
		ProgressRepository.mark_known("enemies", [enemy])
	else:
		presentation.hide()
		return
	presentation.show()
	# The card pops in: it grows from 60 % with a small bounce.
	presentation_card.pivot_offset = presentation_card.size / 2.0
	presentation_card.scale = Vector2.ONE * 0.6
	create_tween().tween_property(presentation_card, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The portrait enters from the left edge and then starts breathing.
func _slide_portrait_in() -> void:
	portrait.pivot_offset = Vector2(portrait.size.x / 2.0, portrait.size.y)  # breathes from its base
	portrait.scale = Vector2.ONE
	create_tween().tween_property(portrait, "position:x", PORTRAIT_X, SLIDE_TIME) \
			.from(PORTRAIT_X - portrait.size.x).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _breath_tween:
		_breath_tween.kill()
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(portrait, "scale", Vector2.ONE * BREATH_SCALE, BREATH_TIME).set_trans(Tween.TRANS_SINE)
	_breath_tween.tween_property(portrait, "scale", Vector2.ONE, BREATH_TIME).set_trans(Tween.TRANS_SINE)


## Any tap on the screen (except "Saltar", which is a Button on top) advances.
func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
