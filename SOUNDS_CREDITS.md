# Sound Credits

All sounds in this repository are **original synthesized audio** generated with Python's
built-in `wave` module using mathematical waveform synthesis (sine waves, square waves,
frequency sweeps, and envelope shaping).

No external audio samples were used. All sounds are released under **CC0 1.0 Universal**
(Public Domain Dedication) — the same license as this project.

## Generation Method

Sounds were generated using `scripts/generate_sounds.py`, which uses only Python's
standard library (`wave`, `struct`, `math`). No external dependencies.

To regenerate all sounds:
```bash
python3 scripts/generate_sounds.py
```

## Theme Descriptions

### `zen` 🎋
Bell-like tones with harmonic overtones and exponential decay, inspired by singing bowls.
Frequencies chosen from natural harmonic series (G4, A4, B4, C5, E5, G3).

### `forest` 🌲  
Frequency-sweep chirps (bird-like) and descending water drop tones.
Chirps sweep from 1200 Hz to 6000 Hz with sine envelope.

### `retro` 🕹️
Square wave synthesis at game-console frequencies.
Sequences inspired by classic 8-bit notification sounds.

### `cafe` ☕
Warm bell tones in the lower register (F4–A4) with longer decay.
