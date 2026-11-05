"""Original music and sound effects of Defensa ESCOM (Block 11, v1.5).

Everything is synthesized from scratch by this script (no samples, no
downloaded audio), so the whole soundtrack belongs to the team.
Style: chiptune (pulse and triangle waves) with a soft bass, a quiet pad and
simple drums.

Output (run from the project root, needs numpy and ffmpeg):
    python tools/audio_src/make_audio.py
    -> audio/music/*.ogg   (songs; the looping ones loop in Godot)
    -> audio/sfx/*.wav     (short effects, mono)

How a song is written: every song is a list of bars. Each bar has a chord
(for the bass, the arpeggio and the pad) and a piece of melody written as
"NOTE:LENGTH" pairs, where LENGTH counts sixteenth notes (4 = one beat,
16 = one bar of 4/4) and "r" is a rest. Example: "E5:4 G5:4 C6:8".
"""

import os
import subprocess
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MUSIC_DIR = os.path.join(ROOT, "audio", "music")
SFX_DIR = os.path.join(ROOT, "audio", "sfx")
SR = 44100
RNG = np.random.default_rng(2026)  # fixed seed: the same files every time

NOTE_INDEX = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5,
              "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}

# Chord name -> (root note for the bass, intervals of the chord).
CHORD_SHAPES = {"": (0, 4, 7), "m": (0, 3, 7), "7": (0, 4, 7, 10), "m7": (0, 3, 7, 10)}


# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------

def midi(name):
    """'A4' -> 69, 'C#5' -> 73."""
    pitch, octave = name[:-1], int(name[-1])
    return 12 * (octave + 1) + NOTE_INDEX[pitch]


def freq(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def parse_chord(chord):
    """'Am' -> (57, (0, 3, 7)) with the root in octave 3."""
    root = chord[:2] if len(chord) > 1 and chord[1] in "#b" else chord[:1]
    shape = CHORD_SHAPES[chord[len(root):]]
    return 48 + NOTE_INDEX[root], shape


def parse_melody(text):
    """'E5:4 r:2 G5:2' -> [(64, 4), (None, 2), (67, 2)]."""
    notes = []
    for token in text.split():
        name, length = token.split(":")
        notes.append((None if name == "r" else midi(name), int(length)))
    return notes


def poly_blep(phase, dt):
    """Removes the harsh aliasing of the jumps of a sawtooth (PolyBLEP)."""
    out = np.zeros_like(phase)
    a = phase < dt
    x = phase[a] / dt[a]
    out[a] = x + x - x * x - 1.0
    b = phase > 1.0 - dt
    x = (phase[b] - 1.0) / dt[b]
    out[b] = x * x + x + x + 1.0
    return out


def saw(phase, dt):
    p = phase % 1.0
    return 2.0 * p - 1.0 - poly_blep(p, dt)


def pulse(phase, dt, duty):
    return 0.5 * (saw(phase, dt) - saw(phase + duty, dt))


def triangle(phase, steps=16):
    """NES-style triangle: quantized to a few levels, it sounds 'chip'."""
    p = phase % 1.0
    tri = 4.0 * np.abs(p - 0.5) - 1.0
    return np.round(tri * steps / 2) / (steps / 2)


def envelope(n, attack, decay, sustain, release):
    """ADSR in seconds; the note lasts n samples and the release goes after it."""
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    r = max(1, int(release * SR))
    env = np.full(n + r, sustain, dtype=np.float64)
    env[:a] = np.linspace(0.0, 1.0, a)[: min(a, n + r)]
    end_d = min(a + d, n)
    if end_d > a:
        env[a:end_d] = np.linspace(1.0, sustain, d)[: end_d - a]
    level = env[n - 1] if n > 0 else 0.0
    env[n:] = np.linspace(level, 0.0, r)
    return env


def one_pole_lowpass(signal, cutoff):
    """Very simple low-pass filter (softens the sound)."""
    from scipy.signal import lfilter
    x = np.exp(-2.0 * np.pi * cutoff / SR)
    return lfilter([1.0 - x], [1.0, -x], signal)


def bandpass(signal, low, high, order=2):
    from scipy.signal import butter, sosfilt
    sos = butter(order, [low, high], btype="band", fs=SR, output="sos")
    return sosfilt(sos, signal)


def highpass(signal, cutoff, order=2):
    from scipy.signal import butter, sosfilt
    sos = butter(order, cutoff, btype="high", fs=SR, output="sos")
    return sosfilt(sos, signal)


def add(buffer, start, sound):
    """Mixes a sound into a buffer (sounds that pass the end wrap to the start,
    so the release of the last notes of a loop is heard at its beginning)."""
    n = len(buffer)
    idx = (np.arange(len(sound)) + start) % n
    np.add.at(buffer, idx, sound)


# --------------------------------------------------------------------------
# Instruments (each returns a mono note)
# --------------------------------------------------------------------------

def inst_lead(note, seconds, duty=0.25, vibrato=0.12, bright=5200.0):
    n = int(seconds * SR)
    total = n + int(0.12 * SR)
    t = np.arange(total) / SR
    vib = 1.0 + vibrato / 100.0 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) * 4, 0, 1)
    f = freq(note) * vib
    dt = f / SR
    phase = np.cumsum(dt)
    tone = pulse(phase, dt, duty)
    tone = one_pole_lowpass(tone, bright)
    return tone * envelope(n, 0.006, 0.12, 0.7, 0.12)


def inst_soft_bass(note, seconds):
    """'Bajo suave': a sine with a little second harmonic and a rounded saw."""
    n = int(seconds * SR)
    total = n + int(0.08 * SR)
    t = np.arange(total) / SR
    f = freq(note)
    dt = np.full(total, f / SR)
    phase = np.cumsum(dt)
    body = np.sin(2 * np.pi * phase) + 0.25 * np.sin(4 * np.pi * phase)
    edge = one_pole_lowpass(saw(phase, dt), 420.0) * 0.6
    return (body + edge) * envelope(n, 0.008, 0.18, 0.75, 0.08)


def inst_tri_bass(note, seconds):
    n = int(seconds * SR)
    total = n + int(0.04 * SR)
    phase = np.cumsum(np.full(total, freq(note) / SR))
    return triangle(phase) * envelope(n, 0.003, 0.05, 0.9, 0.04)


def inst_arp(note, seconds, duty=0.125):
    n = int(seconds * SR)
    total = n + int(0.05 * SR)
    dt = np.full(total, freq(note) / SR)
    tone = pulse(np.cumsum(dt), dt, duty)
    tone = one_pole_lowpass(tone, 3800.0)
    return tone * envelope(n, 0.002, 0.08, 0.35, 0.05)


def inst_pad(notes, seconds):
    """Three detuned saws per note, filtered and with a slow attack."""
    n = int(seconds * SR)
    total = n + int(0.4 * SR)
    out = np.zeros(total)
    for note in notes:
        for detune in (-0.08, 0.0, 0.08):
            f = freq(note) * 2 ** (detune / 12)
            dt = np.full(total, f / SR)
            out += saw(np.cumsum(dt) + RNG.random(), dt)
    out = one_pole_lowpass(out, 1400.0) / (3 * len(notes))
    return out * envelope(n, 0.35, 0.3, 0.8, 0.4)


def drum_kick(level=1.0):
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    f = 50 + 110 * np.exp(-t * 28)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11)
    click = RNG.standard_normal(n) * np.exp(-t * 300) * 0.25
    return (body + click) * level


def drum_snare(level=1.0):
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    noise = bandpass(RNG.standard_normal(n), 1200, 7000) * np.exp(-t * 18)
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 30) * 0.5
    return (noise * 1.3 + tone) * level


def drum_hat(level=1.0, open_hat=False):
    n = int((0.18 if open_hat else 0.05) * SR)
    t = np.arange(n) / SR
    noise = highpass(RNG.standard_normal(n), 7000) * np.exp(-t * (14 if open_hat else 70))
    return noise * level


def drum_shaker(level=1.0):
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    env = np.minimum(t / 0.02, 1.0) * np.exp(-t * 40)
    return bandpass(RNG.standard_normal(n), 4000, 11000) * env * level


DRUMS = {"k": drum_kick, "s": drum_snare, "h": drum_hat, "o": lambda lv: drum_hat(lv, True),
         "x": drum_shaker}


# --------------------------------------------------------------------------
# Song renderer
# --------------------------------------------------------------------------

def render_song(song):
    """Returns a stereo float array of the whole song (one loop)."""
    bpm = song["bpm"]
    step = 60.0 / bpm / 4.0                     # seconds of one sixteenth
    bars = song["bars"]
    tail = song.get("tail_steps", 0)            # extra time for songs that do not loop
    total_steps = 16 * len(bars) + tail
    n = int(round(total_steps * step * SR))
    lead = np.zeros(n)
    harmony = np.zeros(n)
    bass = np.zeros(n)
    drums = np.zeros(n)
    lead_cfg = song.get("lead", {})
    lead_volume = song.get("lead_volume", 0.32)

    for bar_index, (chord_text, melody) in enumerate(bars):
        bar_start = bar_index * 16
        chords = chord_text.split()
        steps_per_chord = 16 // len(chords)
        # Melody
        position = bar_start
        for note, length in parse_melody(melody):
            if note is not None:
                sound = inst_lead(note, length * step * 0.92, **lead_cfg)
                add(lead, int(position * step * SR), sound * lead_volume)
            position += length
        # Harmony, bass and arpeggio, chord by chord
        for c, chord in enumerate(chords):
            root, shape = parse_chord(chord)
            chord_start = bar_start + c * steps_per_chord
            if song.get("pad", 0) > 0:
                pad_notes = [root + 12 + i for i in shape[:3]]
                add(harmony, int(chord_start * step * SR),
                    inst_pad(pad_notes, steps_per_chord * step) * song["pad"])
            for offset, interval, length in song["bass_pattern"]:
                if offset >= steps_per_chord:
                    continue
                note = root - 12 + interval
                start = int((chord_start + offset) * step * SR)
                maker = inst_tri_bass if song.get("chip_bass") else inst_soft_bass
                add(bass, start, maker(note, length * step * 0.95) * song.get("bass_volume", 0.45))
            arp = song.get("arp")
            if arp:
                tones = [root + 12 + i for i in shape] + [root + 24]
                for s in range(0, steps_per_chord, arp["every"]):
                    note = tones[(s // arp["every"]) % len(tones)] + arp.get("octave", 12)
                    start = int((chord_start + s) * step * SR)
                    add(harmony, start, inst_arp(note, arp["every"] * step * 0.8) * arp["volume"])
        # Drums: one 16-step pattern string per instrument
        pattern = song.get("drums_for_bar", lambda i: song.get("drums", {}))(bar_index)
        for name, row in pattern.items():
            for s, ch in enumerate(row):
                if ch != ".":
                    level = {"X": 1.0, "x": 0.6, "-": 0.35}[ch] * song.get("drum_volume", 0.4)
                    add(drums, int((bar_start + s) * step * SR), DRUMS[name](level))

    # A little echo on the lead (stereo: left and right echoes differ), so it
    # sounds wider without a real reverb.
    delay = int(step * 3 * SR)
    echo_l = np.roll(lead, delay) * 0.22
    echo_r = np.roll(lead, delay * 2) * 0.16
    left = lead * 0.95 + echo_l + harmony * 0.9 + bass + drums * 0.95
    right = lead * 0.95 + echo_r + harmony * 1.0 + bass + drums
    if tail == 0:
        pass  # a loop: everything that passed the end already wrapped to the start
    stereo = np.stack([left, right], axis=1)
    return master(stereo)


def master(signal, target_rms_db=-20.0, max_peak=0.8):
    """Soft limiter, then every song at the same loudness (RMS of -20 dBFS),
    which leaves room for the effects on top. Never louder than max_peak."""
    signal = signal / (np.max(np.abs(signal)) + 1e-9)
    signal = np.tanh(signal * 1.4) / np.tanh(1.4)
    rms = np.sqrt(np.mean(signal ** 2))
    gain = 10 ** (target_rms_db / 20) / rms
    gain = min(gain, max_peak / np.max(np.abs(signal)))
    return signal * gain


# --------------------------------------------------------------------------
# The songs
# --------------------------------------------------------------------------

SONGS = {}

# Menu: "Explanada" — calm and friendly, C major.
SONGS["menu"] = {
    "bpm": 96,
    "lead": {"duty": 0.5, "vibrato": 0.18, "bright": 3600.0},
    "lead_volume": 0.30,
    "pad": 0.55,
    "bass_pattern": [(0, 0, 6), (6, 0, 2), (8, 7, 4), (12, 12, 4)],
    "bass_volume": 0.42,
    "arp": {"every": 2, "volume": 0.09, "octave": 12},
    "drum_volume": 0.30,
    "drums": {"k": "X.......x.......", "s": "....x.......x...", "x": "x.x.x.x.x.x.x.x."},
    "bars": [
        ("C", "E5:4 G5:4 C6:6 B5:2"),
        ("Am", "A5:8 G5:4 E5:4"),
        ("F", "F5:4 A5:4 C6:4 A5:4"),
        ("G", "G5:12 r:4"),
        ("C", "E5:4 G5:4 C6:6 D6:2"),
        ("Am", "E6:8 D6:4 C6:4"),
        ("F G", "A5:4 C6:4 B5:4 G5:4"),
        ("C", "C6:12 r:4"),
        ("F", "A5:2 C6:2 F6:4 E6:4 C6:4"),
        ("G", "D6:8 B5:4 G5:4"),
        ("Em", "G5:2 B5:2 E6:4 D6:4 B5:4"),
        ("Am", "C6:8 A5:4 E5:4"),
        ("F", "F5:4 A5:4 C6:4 F6:4"),
        ("G", "E6:4 D6:4 B5:4 G5:4"),
        ("C", "C6:4 E6:4 G6:4 E6:4"),
        ("G", "D6:12 r:4"),
    ],
}

# World 1: "Primer semestre en ESCOM" — upbeat, G major.
SONGS["world_1"] = {
    "bpm": 126,
    "lead": {"duty": 0.25, "vibrato": 0.12, "bright": 5200.0},
    "lead_volume": 0.30,
    "pad": 0.35,
    "bass_pattern": [(0, 0, 2), (2, 12, 2), (4, 0, 2), (6, 12, 2),
                     (8, 0, 2), (10, 12, 2), (12, 7, 2), (14, 12, 2)],
    "bass_volume": 0.40,
    "arp": {"every": 2, "volume": 0.07, "octave": 12},
    "drum_volume": 0.36,
    "drums": {"k": "X.....x.X.......", "s": "....X.......X..x", "h": "x-x-x-x-x-x-x-x-"},
    "bars": [
        ("G", "G5:2 B5:2 D6:3 B5:1 G5:2 A5:2 B5:4"),
        ("D", "A5:2 F#5:2 D5:4 A5:2 B5:2 A5:4"),
        ("Em", "G5:2 E5:2 B4:4 E5:2 G5:2 B5:4"),
        ("C", "C6:3 B5:1 A5:2 G5:2 E5:8"),
        ("G", "G5:2 B5:2 D6:3 B5:1 G5:2 A5:2 B5:4"),
        ("D", "D6:2 E6:2 F#6:4 E6:2 D6:2 A5:4"),
        ("C", "E6:2 D6:2 C6:2 B5:2 A5:2 G5:2 E5:4"),
        ("D", "F#5:4 A5:4 D6:8"),
        ("Em", "B5:4 E6:4 D6:2 B5:2 G5:4"),
        ("C", "C6:4 E6:4 D6:2 C6:2 G5:4"),
        ("G", "B5:2 D6:2 G6:4 F#6:2 E6:2 D6:4"),
        ("D", "A5:4 D6:4 F#6:4 A6:4"),
        ("Em", "G6:3 F#6:1 E6:4 B5:4 E6:4"),
        ("C", "E6:3 D6:1 C6:4 G5:4 C6:4"),
        ("Am", "C6:2 B5:2 A5:2 G5:2 A5:4 C6:4"),
        ("D", "D6:8 r:4 A5:2 B5:2"),
    ],
}

# World 2: "Silencio en la Biblioteca" — quieter and a bit mysterious, D minor (dorian).
SONGS["world_2"] = {
    "bpm": 108,
    "lead": {"duty": 0.5, "vibrato": 0.22, "bright": 2900.0},
    "lead_volume": 0.30,
    "pad": 0.6,
    "bass_pattern": [(0, 0, 4), (6, 7, 2), (8, 12, 4), (12, 7, 4)],
    "bass_volume": 0.42,
    "arp": {"every": 4, "volume": 0.08, "octave": 24},
    "drum_volume": 0.26,
    "drums": {"k": "X.........x.....", "s": "........x.......", "x": "x.xxx.xxx.xxx.xx"},
    "bars": [
        ("Dm", "A5:6 F5:2 D5:4 E5:4"),
        ("C", "G5:6 E5:2 C5:4 E5:4"),
        ("Bb", "F5:4 D5:4 F5:4 Bb5:4"),
        ("C", "A5:8 G5:8"),
        ("Dm", "A5:6 F5:2 D5:4 A5:4"),
        ("C", "C6:6 B5:2 G5:4 E5:4"),
        ("Bb", "D6:4 C6:4 Bb5:4 F5:4"),
        ("A", "E5:4 C#6:4 A5:8"),
        ("Gm", "G5:4 Bb5:4 D6:6 C6:2"),
        ("Dm", "A5:8 F5:4 D5:4"),
        ("Bb", "F5:2 G5:2 Bb5:4 D6:4 C6:4"),
        ("C", "E6:6 D6:2 C6:8"),
        ("Gm", "D6:4 Bb5:4 G5:4 Bb5:4"),
        ("A", "C#6:4 E6:4 A6:8"),
        ("Dm", "F6:4 E6:4 D6:4 A5:4"),
        ("A", "C#6:4 E5:4 A5:8"),
    ],
}

# Boss: "El Examen Final" — fast and tense, A minor.
SONGS["boss"] = {
    "bpm": 150,
    "lead": {"duty": 0.25, "vibrato": 0.1, "bright": 6000.0},
    "lead_volume": 0.30,
    "pad": 0.3,
    "chip_bass": True,
    "bass_pattern": [(i, 0 if i % 4 == 0 else (12 if i % 4 == 2 else 0), 2) for i in range(0, 16, 2)],
    "bass_volume": 0.55,
    "arp": {"every": 1, "volume": 0.045, "octave": 12},
    "drum_volume": 0.42,
    "drums": {"k": "X..xX..xX..xX.x.", "s": "....X.......X...", "h": "xxxxxxxxxxxxxxxx"},
    "bars": [
        ("Am", "A5:2 A5:2 C6:2 A5:2 E6:4 D6:2 C6:2"),
        ("Am", "B5:2 C6:2 B5:2 A5:2 G5:4 A5:4"),
        ("F", "F5:2 A5:2 C6:2 F6:2 E6:4 C6:4"),
        ("G", "D6:2 B5:2 G5:2 B5:2 D6:4 G6:4"),
        ("Am", "A6:4 G6:2 E6:2 A6:4 G6:2 E6:2"),
        ("Am", "C6:2 D6:2 E6:4 D6:2 C6:2 B5:4"),
        ("F", "C6:4 A5:4 F5:4 A5:4"),
        ("E", "G#5:4 B5:4 E6:8"),
        ("Dm", "F6:4 E6:2 D6:2 A5:4 D6:4"),
        ("Am", "E6:4 C6:2 A5:2 E5:4 A5:4"),
        ("F", "F5:2 A5:2 C6:2 F6:2 A6:4 F6:4"),
        ("E", "G#6:4 E6:4 B5:4 G#5:4"),
        ("Dm", "D6:2 F6:2 A6:4 G6:2 F6:2 E6:4"),
        ("F", "C6:2 F6:2 A6:4 G6:2 F6:2 C6:4"),
        ("E", "B5:2 D6:2 E6:4 G#6:4 B6:4"),
        ("E", "E6:2 r:2 E6:2 r:2 E6:2 G#6:2 B6:4"),
    ],
}

# Victory jingle (does not loop).
SONGS["victory"] = {
    "bpm": 140,
    "lead": {"duty": 0.25, "vibrato": 0.15, "bright": 6000.0},
    "lead_volume": 0.34,
    "pad": 0.5,
    "bass_pattern": [(0, 0, 4), (4, 7, 4), (8, 12, 8)],
    "bass_volume": 0.42,
    "arp": {"every": 1, "volume": 0.06, "octave": 12},
    "drum_volume": 0.4,
    "drums_for_bar": lambda i: ({"k": "X.......X.......", "s": "....X.....X.X.X.", "h": "x.x.x.x.x.x.x.x."}
                                if i < 2 else {"k": "X...............", "o": "X..............."}),
    "tail_steps": 12,
    "bars": [
        ("C", "C5:2 E5:2 G5:2 C6:2 E6:2 G6:2 E6:4"),
        ("F G", "F6:4 E6:2 D6:2 B5:2 C6:2 D6:4"),
        ("C", "C6:2 G5:2 C6:2 E6:2 G6:8"),
    ],
}

# Defeat jingle (does not loop): a funny "reprobado".
SONGS["defeat"] = {
    "bpm": 100,
    "lead": {"duty": 0.5, "vibrato": 0.6, "bright": 3000.0},
    "lead_volume": 0.36,
    "pad": 0.35,
    "chip_bass": True,
    "bass_pattern": [(0, 0, 4)],
    "bass_volume": 0.5,
    "drum_volume": 0.3,
    "drums_for_bar": lambda i: {"k": "X..............."},
    "tail_steps": 8,
    "bars": [
        ("C", "G5:4 F#5:4 F5:4 r:4"),
        ("C#", "E5:16"),
    ],
}

LOOPING = ["menu", "world_1", "world_2", "boss"]


# --------------------------------------------------------------------------
# Sound effects
# --------------------------------------------------------------------------

def tone_sweep(f0, f1, seconds, shape="square", duty=0.5, curve=1.0):
    n = int(seconds * SR)
    t = np.linspace(0, 1, n)
    f = f0 + (f1 - f0) * t ** curve
    dt = f / SR
    phase = np.cumsum(dt)
    if shape == "square":
        return pulse(phase, dt, duty)
    if shape == "tri":
        return triangle(phase, 32)
    return np.sin(2 * np.pi * phase)


def decay(n, rate):
    return np.exp(-np.arange(n) / SR * rate)


def sfx_place():
    """Colocar: soft 'thump' with a little pop on top."""
    thump = tone_sweep(180, 70, 0.16, "sine") * decay(int(0.16 * SR), 22)
    pop = tone_sweep(500, 900, 0.07, "square", 0.25) * decay(int(0.07 * SR), 45) * 0.35
    out = np.zeros(int(0.18 * SR))
    out[: len(thump)] += thump
    out[int(0.02 * SR): int(0.02 * SR) + len(pop)] += pop
    return out


def sfx_collect():
    """Recoger energía: two quick notes up, like a coin."""
    a = tone_sweep(988, 988, 0.06, "square", 0.25) * decay(int(0.06 * SR), 10)
    b = tone_sweep(1319, 1319, 0.2, "square", 0.25) * decay(int(0.2 * SR), 16)
    return np.concatenate([a, b])


def sfx_shoot():
    """Disparar (Laptop): short digital 'pew'."""
    return tone_sweep(1500, 420, 0.1, "square", 0.25, 0.5) * decay(int(0.1 * SR), 24)


def sfx_hit():
    """Impactar: small crunchy noise and a tiny thump."""
    n = int(0.09 * SR)
    noise = bandpass(RNG.standard_normal(n), 900, 5000) * decay(n, 55)
    thump = tone_sweep(220, 90, 0.09, "sine") * decay(n, 40) * 0.6
    return noise + thump


def sfx_bite():
    """Morder: two quick 'chomps'."""
    def chomp():
        n = int(0.07 * SR)
        crunch = bandpass(RNG.standard_normal(n), 300, 2200) * decay(n, 45)
        jaw = tone_sweep(160, 90, 0.07, "square", 0.5) * decay(n, 50) * 0.3
        return crunch + jaw
    gap = np.zeros(int(0.05 * SR))
    return np.concatenate([chomp(), gap, chomp() * 0.8])


def sfx_die():
    """Morir: falling tone with a paper 'poof'."""
    n = int(0.42 * SR)
    fall = tone_sweep(700, 110, 0.42, "square", 0.5, 0.6) * decay(n, 7) * 0.45
    poof = bandpass(RNG.standard_normal(n), 600, 6000) * decay(n, 12) * 0.7
    return fall + poof


def sfx_extraordinario():
    """Extraordinario: rising whoosh with a bell on top."""
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    whoosh = RNG.standard_normal(n)
    cutoff = np.linspace(500, 6000, n)
    whoosh = one_pole_lowpass(whoosh, 3000) * np.sin(np.pi * t / t[-1]) * 0.6
    bell = np.zeros(n)
    for f, a in ((880, 1.0), (1760, 0.4), (2637, 0.25)):
        bell += np.sin(2 * np.pi * f * t) * a
    bell *= np.exp(-t * 4) * 0.5
    start = int(0.25 * SR)
    out = whoosh.copy()
    out[start:] += bell[: n - start]
    del cutoff
    return out


def sfx_button():
    """Botón: soft click."""
    n = int(0.05 * SR)
    return tone_sweep(1100, 700, 0.05, "tri") * decay(n, 70)


def sfx_director_bip():
    """Voz de Her Mosso: a low, friendly 'bip' (the game changes its pitch a little per letter)."""
    n = int(0.075 * SR)
    t = np.arange(n) / SR
    f = 155.0
    dt = np.full(n, f / SR)
    phase = np.cumsum(dt)
    voice = 0.6 * triangle(phase, 32) + 0.4 * pulse(phase, dt, 0.35)
    # a soft 'vowel' (formant around 700 Hz) so it sounds like a voice, not a beep
    voice = voice * 0.5 + bandpass(voice, 450, 1100) * 1.2
    env = np.minimum(t / 0.006, 1.0) * np.exp(-t * 22)
    return voice * env


SFX = {
    "place": sfx_place,
    "collect": sfx_collect,
    "shoot": sfx_shoot,
    "hit": sfx_hit,
    "bite": sfx_bite,
    "die": sfx_die,
    "extraordinario": sfx_extraordinario,
    "button": sfx_button,
    "director_bip": sfx_director_bip,
}

# Loudness of each effect (peak, 0..1). The frequent ones are quieter.
SFX_PEAK = {"shoot": 0.35, "hit": 0.45, "bite": 0.55, "button": 0.5, "director_bip": 0.5,
            "collect": 0.6, "place": 0.7, "die": 0.6, "extraordinario": 0.75}


# --------------------------------------------------------------------------
# Writing the files
# --------------------------------------------------------------------------

def write_wav(path, samples, channels):
    data = np.clip(samples, -1.0, 1.0)
    pcm = (data * 32767).astype("<i2")
    with wave.open(path, "wb") as f:
        f.setnchannels(channels)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())


def write_ogg(path, stereo):
    tmp = path + ".tmp.wav"
    write_wav(tmp, stereo, 2)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis",
                    "-q:a", "5", path], check=True)
    os.remove(tmp)


def main():
    os.makedirs(MUSIC_DIR, exist_ok=True)
    os.makedirs(SFX_DIR, exist_ok=True)
    for name, song in SONGS.items():
        audio = render_song(song)
        write_ogg(os.path.join(MUSIC_DIR, name + ".ogg"), audio)
        print("music", name, "%.1f s" % (len(audio) / SR))
    for name, maker in SFX.items():
        sound = maker()
        sound = sound / (np.max(np.abs(sound)) + 1e-9) * SFX_PEAK[name]
        fade = min(len(sound), int(0.004 * SR))
        sound[-fade:] *= np.linspace(1, 0, fade)  # no click at the end
        write_wav(os.path.join(SFX_DIR, name + ".wav"), sound, 1)
        print("sfx", name, "%.2f s" % (len(sound) / SR))


if __name__ == "__main__":
    main()
