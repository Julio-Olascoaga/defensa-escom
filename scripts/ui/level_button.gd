class_name LevelButton
extends Button
## One level of the level select. LevelSelect creates one per LevelData of
## the world, in code, and calls setup(). It shows the number, the name and
## the best grade of the level, or a padlock if it is still locked.
## LevelSelect decides what a tap does.

const BUTTON_SIZE := Vector2(250, 170)
const PADLOCK_TEXTURE := preload("res://art/ui/padlock.png")
const COLOR_OPEN := Color("6c1d45")
const COLOR_LOCKED := Color("3a3846")
const COLOR_BORDER := Color("f2b33d")
const COLOR_GRADE := Color("39e58c")

var level: LevelData
## Position of the level in the world (0 = "Nivel 1").
var level_index := 0
var unlocked := false
## Best grade saved (6 to 10), 0 = never won.
var grade := 0


func setup(level_data: LevelData, index: int, is_unlocked: bool, best_grade: int) -> void:
	level = level_data
	level_index = index
	unlocked = is_unlocked
	grade = best_grade
	name = "Level%d" % (index + 1)
	custom_minimum_size = BUTTON_SIZE
	focus_mode = Control.FOCUS_NONE
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_theme_font_size_override("font_size", 22)
	var level_name := level.display_name if level else "?"
	if not unlocked:
		text = "Nivel %d\n%s" % [index + 1, level_name]
		icon = PADLOCK_TEXTURE
		expand_icon = true
		vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_theme_constant_override("icon_max_width", 56)
		add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	elif grade > 0:
		text = "Nivel %d\n%s\nCalificación: %d" % [index + 1, level_name, grade]
	else:
		text = "Nivel %d\n%s\nSin calificación" % [index + 1, level_name]
	_apply_style()


func _apply_style() -> void:
	for style_name in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		var bg := COLOR_OPEN if unlocked else COLOR_LOCKED
		style.bg_color = bg.lightened(0.1) if style_name == "hover" else bg
		style.border_color = COLOR_GRADE if grade > 0 else (COLOR_BORDER if unlocked else Color("6c6a78"))
		style.set_border_width_all(4)
		style.set_corner_radius_all(16)
		style.set_content_margin_all(10)
		add_theme_stylebox_override(style_name, style)
