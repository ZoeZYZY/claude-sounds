#!/usr/bin/env python3
"""
claude-sounds: generate_sounds.py
Regenerates all bundled theme sounds using Python's standard library only.
No external dependencies.

Usage: python3 scripts/generate_sounds.py
"""

import wave, struct, math, os

THEMES_DIR = os.path.join(os.path.dirname(__file__), "..", "themes")


def make_bell(filename, freq, duration=0.6, sample_rate=44100, volume=0.35):
    """Bell tone with harmonics and exponential decay."""
    frames = []
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        decay = math.exp(-t * 4)
        val = int(volume * 32767 * decay * (
            0.6 * math.sin(2 * math.pi * freq * t) +
            0.3 * math.sin(2 * math.pi * freq * 2.76 * t) +
            0.1 * math.sin(2 * math.pi * freq * 5.4 * t)
        ))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_chirp(filename, sample_rate=44100):
    """Bird-like chirp: frequency sweep 1200→6000 Hz."""
    frames = []
    dur = 0.25
    n = int(sample_rate * dur)
    for i in range(n):
        t = i / sample_rate
        freq = 1200 + 4800 * (t / dur) ** 0.5
        env = math.sin(math.pi * t / dur) ** 0.5
        val = int(0.4 * 32767 * env * math.sin(2 * math.pi * freq * t))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_double_chirp(filename, sample_rate=44100):
    """Two quick chirps — attention signal."""
    frames = []
    for _ in range(2):
        dur, n = 0.2, int(sample_rate * 0.2)
        for i in range(n):
            t = i / sample_rate
            freq = 1200 + 4800 * (t / dur) ** 0.5
            env = math.sin(math.pi * t / dur) ** 0.5
            frames.append(struct.pack('<h', int(0.4 * 32767 * env * math.sin(2 * math.pi * freq * t))))
        frames.extend([struct.pack('<h', 0)] * int(sample_rate * 0.08))
    _write_wav(filename, frames, sample_rate)


def make_water_drop(filename, sample_rate=44100):
    """Descending frequency blip — water drop."""
    frames = []
    dur = 0.3
    n = int(sample_rate * dur)
    for i in range(n):
        t = i / sample_rate
        freq = 1600 * math.exp(-t * 8)
        env = math.exp(-t * 12)
        val = int(0.5 * 32767 * env * math.sin(2 * math.pi * freq * t))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_retro_seq(filename, notes, duration_each=0.1, sample_rate=44100):
    """Sequence of square-wave notes for 8-bit feel."""
    frames = []
    for freq in notes:
        n = int(sample_rate * duration_each)
        for i in range(n):
            t = i / sample_rate
            env = max(0.0, 1.0 - t / duration_each * 1.5)
            sq = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
            frames.append(struct.pack('<h', int(0.25 * 32767 * env * sq)))
    _write_wav(filename, frames, sample_rate)


def _write_wav(filename, frames, sample_rate):
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(frames))


def generate_zen():
    d = os.path.join(THEMES_DIR, "zen")
    os.makedirs(d, exist_ok=True)
    make_bell(f"{d}/start.wav",      392, 1.2)   # G4 opening bell
    make_bell(f"{d}/done.wav",       523, 0.8)   # C5 completion
    make_bell(f"{d}/permission.wav", 659, 0.5)   # E5 attention
    make_bell(f"{d}/notify.wav",     440, 0.4)   # A4 soft notice
    make_water_drop(f"{d}/write.wav")
    make_bell(f"{d}/bash.wav",       330, 0.3)   # E4 subtle
    make_bell(f"{d}/subtask.wav",    494, 0.5)   # B4
    make_bell(f"{d}/error.wav",      196, 0.9)   # G3 low gong
    print(f"  ✓ zen ({len(os.listdir(d))} files)")


def generate_forest():
    d = os.path.join(THEMES_DIR, "forest")
    os.makedirs(d, exist_ok=True)
    make_chirp(f"{d}/start.wav")
    make_chirp(f"{d}/done.wav")
    make_double_chirp(f"{d}/permission.wav")
    make_bell(f"{d}/notify.wav",  880, 0.3)
    make_water_drop(f"{d}/write.wav")
    make_bell(f"{d}/bash.wav",    660, 0.2)
    make_chirp(f"{d}/subtask.wav")
    make_bell(f"{d}/error.wav",   150, 0.8)
    print(f"  ✓ forest ({len(os.listdir(d))} files)")


def generate_retro():
    d = os.path.join(THEMES_DIR, "retro")
    os.makedirs(d, exist_ok=True)
    make_retro_seq(f"{d}/start.wav",      [523, 659, 784, 1047], 0.1)
    make_retro_seq(f"{d}/done.wav",       [784, 1047], 0.15)
    make_retro_seq(f"{d}/permission.wav", [880, 660, 880, 660], 0.08)
    make_retro_seq(f"{d}/notify.wav",     [659], 0.1)
    make_retro_seq(f"{d}/write.wav",      [523], 0.08)
    make_retro_seq(f"{d}/bash.wav",       [440], 0.08)
    make_retro_seq(f"{d}/subtask.wav",    [523, 784], 0.1)
    make_retro_seq(f"{d}/error.wav",      [330, 277, 220, 185], 0.1)
    print(f"  ✓ retro ({len(os.listdir(d))} files)")


def generate_cafe():
    d = os.path.join(THEMES_DIR, "cafe")
    os.makedirs(d, exist_ok=True)
    make_bell(f"{d}/start.wav",      349, 0.8)   # F4 warm
    make_bell(f"{d}/done.wav",       440, 0.6)   # A4
    make_bell(f"{d}/permission.wav", 554, 0.4)   # C#5
    make_bell(f"{d}/notify.wav",     392, 0.3)   # G4
    make_water_drop(f"{d}/write.wav")
    make_bell(f"{d}/bash.wav",       330, 0.2)
    make_bell(f"{d}/subtask.wav",    415, 0.4)   # G#4
    make_bell(f"{d}/error.wav",      220, 0.7)   # A3
    print(f"  ✓ cafe ({len(os.listdir(d))} files)")


if __name__ == "__main__":
    print("Generating theme sounds...")
    generate_zen()
    generate_forest()
    generate_retro()
    generate_cafe()
    print("\nDone. All sounds written to themes/")
