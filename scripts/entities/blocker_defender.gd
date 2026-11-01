class_name BlockerDefender
extends Defender
## Firewall: lots of health (it comes from its DefenderType) to stop enemies.
## It needs no extra code: every defender blocks the enemy that bites it
## (see Enemy._defender_in_front()), and the Firewall simply lasts much longer
## because its resource gives it 1500 health.
