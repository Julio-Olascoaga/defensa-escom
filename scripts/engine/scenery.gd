class_name Scenery
extends Node2D
## The living part of the background (Block 11). It sits right above the
## Background sprite of game.tscn and does two things when a level starts:
##   1. Puts the hour of the level on everything of the game world with its
##      CanvasModulate (Daylight): a warm tint in the afternoon, a blue and
##      darker one at night. The UI is in CanvasLayers, so it is not tinted.
##   2. Adds the decorations of the world (WorldData.scenery). Inside that
##      scene, nodes in the group "day_only" (the pigeons) are hidden at night,
##      and nodes in the group "night_only" (windows and lamps) only appear
##      at night, turning on little by little.

## Tint of each hour. White = the colors of the picture as they are.
const DAYLIGHT := {
	LevelData.TimeOfDay.MORNING: Color(1.0, 1.0, 1.0),
	LevelData.TimeOfDay.AFTERNOON: Color(1.0, 0.87, 0.74),
	LevelData.TimeOfDay.NIGHT: Color(0.6, 0.65, 0.9),
}
## Seconds the night lights take to turn on.
const LIGHTS_ON_TIME := 1.5

@onready var daylight: CanvasModulate = $Daylight


func setup(world: WorldData, time_of_day: LevelData.TimeOfDay) -> void:
	daylight.color = DAYLIGHT[time_of_day]
	if world.scenery:
		add_child(world.scenery.instantiate())
	var night := time_of_day == LevelData.TimeOfDay.NIGHT
	for node: CanvasItem in get_tree().get_nodes_in_group("day_only"):
		node.visible = not night
	for light: CanvasItem in get_tree().get_nodes_in_group("night_only"):
		light.visible = night
		if night:
			light.modulate.a = 0.0
			create_tween().tween_property(light, "modulate:a", 1.0, LIGHTS_ON_TIME)
