class_name CampaignData
extends Resource
## The whole career: the 8 semesters (worlds) in the order they are played.
## There is only one file of this type, data/campaign.tres.
## Adding a world = creating its WorldData and adding it to this list.

## Worlds in order: index 0 is the first semester.
@export var worlds: Array[WorldData] = []
