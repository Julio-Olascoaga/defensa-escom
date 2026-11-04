class_name DialogueData
extends Resource
## One conversation (one file in data/dialogues/).
## ProgressRepository remembers its id once it has been seen, so it is not repeated.

## Unique id ("w1_intro"). Do not change it once players have saved progress.
@export var id: String = ""
## Lines in the order they are shown.
@export var lines: Array[DialogueLine] = []
