class_name WaveData
extends Resource
## One wave of a level: a calm time and then a list of spawn events.
## A wave only starts when the previous one has fully appeared
## and none of its enemies is left alive.

## Seconds of calm before the first enemy of this wave. In the first wave it
## gives the player time to place Cafés; in the others, a short break.
@export var start_delay: float = 15.0
## Enemies of the wave. Their order does not matter: WaveManager sorts them by time.
@export var events: Array[SpawnEvent] = []
