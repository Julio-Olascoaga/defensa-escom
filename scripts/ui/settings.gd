extends Control
## "Ajustes": music and effects sliders (the Music and SFX buses of AudioServer,
## through AudioManager), vibration on/off, "Borrar progreso" with a
## confirmation and the credits. Every change is saved at once in the
## [settings] section of user://progress.cfg by ProgressRepository, so it
## survives closing the app. Back (button or Android) returns to Inicio.

@onready var music_slider: HSlider = %MusicSlider
@onready var music_value: Label = %MusicValue
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_value: Label = %SfxValue
@onready var vibration_toggle: CheckButton = %VibrationToggle
@onready var erase_button: Button = %EraseButton
@onready var credits_button: Button = %CreditsButton
@onready var back_button: Button = %BackButton
@onready var confirm_panel: Control = %ConfirmPanel
@onready var confirm_yes_button: Button = %ConfirmYesButton
@onready var confirm_no_button: Button = %ConfirmNoButton
@onready var notice: Notice = %Notice


func _ready() -> void:
	# The saved values first, so setting them does not count as a change.
	music_slider.set_value_no_signal(ProgressRepository.get_setting("music_volume"))
	sfx_slider.set_value_no_signal(ProgressRepository.get_setting("sfx_volume"))
	vibration_toggle.set_pressed_no_signal(ProgressRepository.get_setting("vibration"))
	_show_percent(music_value, music_slider.value)
	_show_percent(sfx_value, sfx_slider.value)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	vibration_toggle.toggled.connect(_on_vibration_toggled)
	erase_button.pressed.connect(confirm_panel.show)
	confirm_no_button.pressed.connect(confirm_panel.hide)
	confirm_yes_button.pressed.connect(_on_erase_confirmed)
	credits_button.pressed.connect(_on_credits_pressed)
	back_button.pressed.connect(_go_back)
	confirm_panel.hide()


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	_show_percent(music_value, value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	_show_percent(sfx_value, value)


func _on_vibration_toggled(active: bool) -> void:
	ProgressRepository.set_setting("vibration", active)
	if active:
		AudioManager.vibrate()  # a short buzz so the player feels it is on


func _show_percent(label: Label, value: float) -> void:
	label.text = "%d %%" % roundi(value * 100.0)


## "Borrar" on the confirmation: levels, grades and dialogues are erased; the settings stay.
func _on_erase_confirmed() -> void:
	confirm_panel.hide()
	if ProgressRepository.reset_progress() == OK:
		notice.show_message("Progreso borrado")
	else:
		notice.show_message("No se pudo guardar. Inténtalo de nuevo.")


func _on_credits_pressed() -> void:
	Credits.back_scene = Credits.SETTINGS_SCENE
	SceneTransition.change_scene(Credits.CREDITS_SCENE)


func _go_back() -> void:
	SceneTransition.change_scene(GameSession.MAIN_MENU_SCENE)


func _notification(what: int) -> void:
	# Android back button: closes the confirmation first, then returns to Inicio.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		if confirm_panel.visible:
			confirm_panel.hide()
		else:
			_go_back()
