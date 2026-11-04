class_name FxLimits
extends RefCounted
## Particle caps of Block 10, all in one place so they can be lowered for
## weak phones without searching the code. Numbers are particles per effect.
## The benchmark (scenes/debug/benchmark.tscn) runs 30 enemies at once with them.

## Café steam (continuous, inside the puppet scene: CPUParticles2D "Steam").
const STEAM := 5
## Smoke of a defender in the critical stage (continuous, one per defender).
const SMOKE := 6
## Pieces that fall when a defender changes damage stage (one-shot).
const DEBRIS := 8
## Paper bits when an enemy dies (one-shot).
const PAPER_BITS := 8
## Gold sparks when an enemy dies (one-shot; the boss multiplies them by its size, up to this).
const DEATH_SPARKS_MAX := 24
## Trail of a projectile (continuous, inside projectile.tscn).
const TRAIL := 6
## Code bits where a projectile hits (one-shot, besides the 1.0 blue sparks).
const HIT_BITS := 4
## Most one-shot bursts alive at the same time in the Effects node. When it is
## full, new bursts are skipped (the game logic never depends on them).
const MAX_BURSTS := 40
