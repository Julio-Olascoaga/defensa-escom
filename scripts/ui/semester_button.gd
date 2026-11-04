class_name SemesterButton
extends Button
## One semester (world) of the career map. CareerMap creates one per world of
## campaign.worlds, in code, and calls setup(). The button only SHOWS the state;
## CareerMap decides what a tap does.
##   LOCKED    grey, with a padlock ("Bloqueado" or "Próximamente")
##   AVAILABLE pulses gently with a Tween ("Disponible")
##   PASSED    green, shows the average of the semester ("Promedio 9.2")

enum State { LOCKED, AVAILABLE, PASSED }

const BUTTON_SIZE := Vector2(210, 250)
const ICON_WIDTH := 96
const PADLOCK_TEXTURE := preload("res://art/ui/padlock.png")
const STATE_ICONS := {
	State.LOCKED: preload("res://art/ui/semester_locked.png"),
	State.AVAILABLE: preload("res://art/ui/semester_available.png"),
	State.PASSED: preload("res://art/ui/semester_passed.png"),
}
## Background and border of each state.
const STATE_COLORS := {
	State.LOCKED: [Color("3a3846"), Color("6c6a78")],
	State.AVAILABLE: [Color("6c1d45"), Color("f2b33d")],
	State.PASSED: [Color("1f5a3a"), Color("39e58c")],
}
## Pulse of an available semester: maximum scale and seconds of each half.
const PULSE_SCALE := 1.06
const PULSE_TIME := 0.7

var world: WorldData
## Position of the world in campaign.worlds.
var world_index := 0
var state := State.LOCKED
var pulse_tween: Tween
var padlock: TextureRect


## average is only used when the state is PASSED.
func setup(world_data: WorldData, index: int, button_state: State, average: float) -> void:
	world = world_data
	world_index = index
	state = button_state
	name = "Semester%d" % (index + 1)
	custom_minimum_size = BUTTON_SIZE
	focus_mode = Control.FOCUS_NONE
	icon = STATE_ICONS[state]
	expand_icon = true
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_constant_override("icon_max_width", ICON_WIDTH)
	add_theme_font_size_override("font_size", 20)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text = "%s\n%s" % [world.display_name, status_text(average)]
	_apply_style()
	if state == State.LOCKED:
		_add_padlock()
		add_theme_color_override("font_color", Color(1, 1, 1, 0.6))


## Last line of the button.
func status_text(average: float) -> String:
	match state:
		State.PASSED:
			return "Promedio %.1f" % average if average > 0.0 else "Aprobado"
		State.AVAILABLE:
			return "Disponible"
	return "Próximamente" if not world.available or world.levels.is_empty() else "Bloqueado"


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	if state == State.AVAILABLE:
		_start_pulse()


func _apply_style() -> void:
	var colors: Array = STATE_COLORS[state]
	for style_name in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = colors[0].lightened(0.1) if style_name == "hover" else colors[0]
		style.border_color = colors[1]
		style.set_border_width_all(4)
		style.set_corner_radius_all(20)
		style.set_content_margin_all(12)
		add_theme_stylebox_override(style_name, style)


## Padlock in the top-right corner of a locked semester.
func _add_padlock() -> void:
	padlock = TextureRect.new()
	padlock.name = "Padlock"
	padlock.texture = PADLOCK_TEXTURE
	padlock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	padlock.custom_minimum_size = Vector2(56, 56)
	padlock.size = Vector2(56, 56)
	padlock.position = Vector2(BUTTON_SIZE.x - 64, 8)
	padlock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(padlock)


## The available semester grows and shrinks a little, forever.
func _start_pulse() -> void:
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "scale", Vector2.ONE * PULSE_SCALE, PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(self, "scale", Vector2.ONE, PULSE_TIME).set_trans(Tween.TRANS_SINE)
