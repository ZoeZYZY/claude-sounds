#!/usr/bin/env python3
"""
claude-sounds: generate_sounds.py
Regenerates all bundled theme sounds using Python's standard library only.
No external dependencies.

Usage: python3 scripts/generate_sounds.py
"""

import wave, struct, math, os, random

THEMES_DIR = os.path.join(os.path.dirname(__file__), "..", "themes")


# ──────────────────────────────────────────────────────────────
# Shared primitives
# ──────────────────────────────────────────────────────────────

def _write_wav(filename, frames, sample_rate):
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        f.writeframes(b''.join(frames))


def _clamp(val):
    return max(-32767, min(32767, int(val)))


def make_bell(filename, freq, duration=0.6, sample_rate=44100, volume=0.35):
    """Bell tone with harmonics and exponential decay."""
    frames = []
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        decay = math.exp(-t * 4)
        val = _clamp(volume * 32767 * decay * (
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
        val = _clamp(0.4 * 32767 * env * math.sin(2 * math.pi * freq * t))
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
            frames.append(struct.pack('<h', _clamp(0.4 * 32767 * env * math.sin(2 * math.pi * freq * t))))
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
        val = _clamp(0.5 * 32767 * env * math.sin(2 * math.pi * freq * t))
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
            frames.append(struct.pack('<h', _clamp(0.25 * 32767 * env * sq)))
    _write_wav(filename, frames, sample_rate)


# ──────────────────────────────────────────────────────────────
# Wuxia primitives 🗡️
# ──────────────────────────────────────────────────────────────

def make_gong(filename, freq=90, duration=2.2, sample_rate=44100, volume=0.38):
    """Deep resonant gong with slow decay — Chinese percussion."""
    frames = []
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        strike = math.exp(-t * 40) * 0.25          # impact transient
        d1 = math.exp(-t * 0.7)                    # fundamental, slow fade
        d2 = math.exp(-t * 2.5)                    # 2nd harmonic
        d3 = math.exp(-t * 5.0)                    # 3rd harmonic
        noise = (random.random() * 2 - 1) * strike
        val = _clamp(volume * 32767 * (
            0.5 * d1 * math.sin(2 * math.pi * freq * t) +
            0.25 * d2 * math.sin(2 * math.pi * freq * 2.08 * t) +
            0.15 * d3 * math.sin(2 * math.pi * freq * 3.1 * t) +
            0.05 * d2 * math.sin(2 * math.pi * freq * 4.3 * t) +
            noise
        ))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_pluck(filename, freq=293, duration=0.9, sample_rate=44100, volume=0.38):
    """Plucked string — guqin / pipa feel."""
    frames = []
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        d_slow = math.exp(-t * 4)
        d_fast = math.exp(-t * 14)
        val = _clamp(volume * 32767 * (
            0.55 * d_slow * math.sin(2 * math.pi * freq * t) +
            0.25 * d_fast * math.sin(2 * math.pi * freq * 2 * t) +
            0.12 * d_fast * math.sin(2 * math.pi * freq * 3 * t) +
            0.08 * d_fast * math.sin(2 * math.pi * freq * 4 * t)
        ))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_swish(filename, sample_rate=44100, volume=0.28):
    """Sword swish — high-to-low noise sweep."""
    frames = []
    duration = 0.28
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        env = math.sin(math.pi * t / duration) ** 0.6
        freq = 3500 * math.exp(-t * 9) + 150
        noise = random.random() * 2 - 1
        tone = math.sin(2 * math.pi * freq * t)
        val = _clamp(volume * 32767 * env * (0.65 * noise + 0.35 * tone))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_low_drum(filename, sample_rate=44100, volume=0.4):
    """Sharp taiko-style drum hit."""
    frames = []
    duration = 0.35
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        body = math.exp(-t * 15) * math.sin(2 * math.pi * 60 * t)
        attack = math.exp(-t * 80) * (random.random() * 2 - 1)
        val = _clamp(volume * 32767 * (0.7 * body + 0.3 * attack))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


# ──────────────────────────────────────────────────────────────
# Cute primitives 🌸
# ──────────────────────────────────────────────────────────────

def make_bubble_pop(filename, sample_rate=44100, volume=0.42):
    """Soft bubble pop — descending pip."""
    frames = []
    duration = 0.18
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        freq = 1200 + 600 * math.exp(-t * 18)
        env = math.exp(-t * 22)
        val = _clamp(volume * 32767 * env * math.sin(2 * math.pi * freq * t))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_sparkle(filename, sample_rate=44100, volume=0.32):
    """Sparkle — ascending arpeggio of high tones."""
    frames = []
    freqs = [2093, 2637, 3136, 3520, 4186]  # C7 E7 G7 A7 C8
    for freq in freqs:
        dur = 0.065
        n = int(sample_rate * dur)
        for i in range(n):
            t = i / sample_rate
            env = math.sin(math.pi * t / dur) ** 2
            val = _clamp(volume * 32767 * env * math.sin(2 * math.pi * freq * t))
            frames.append(struct.pack('<h', val))
        frames.extend([struct.pack('<h', 0)] * int(sample_rate * 0.015))
    _write_wav(filename, frames, sample_rate)


def make_boing(filename, sample_rate=44100, volume=0.35):
    """Cartoon spring boing — ascending pitch sweep."""
    frames = []
    duration = 0.45
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        freq = 280 + 1400 * (t / duration) ** 0.6
        env = math.sin(math.pi * t / duration) * math.exp(-t * 2.5)
        val = _clamp(volume * 32767 * env * math.sin(2 * math.pi * freq * t))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_cute_notify(filename, sample_rate=44100, volume=0.35):
    """Two-tone cute ping."""
    frames = []
    for freq in [1047, 1319]:  # C6, E6
        dur = 0.12
        n = int(sample_rate * dur)
        for i in range(n):
            t = i / sample_rate
            env = math.sin(math.pi * t / dur) ** 0.8
            val = _clamp(volume * 32767 * env * math.sin(2 * math.pi * freq * t))
            frames.append(struct.pack('<h', val))
        frames.extend([struct.pack('<h', 0)] * int(sample_rate * 0.03))
    _write_wav(filename, frames, sample_rate)


def make_cute_error(filename, sample_rate=44100, volume=0.35):
    """Sad descending tones."""
    frames = []
    for freq in [659, 523, 392]:  # E5 → C5 → G4
        dur = 0.14
        n = int(sample_rate * dur)
        for i in range(n):
            t = i / sample_rate
            env = math.exp(-t * 7)
            val = _clamp(volume * 32767 * env * math.sin(2 * math.pi * freq * t))
            frames.append(struct.pack('<h', val))
        frames.extend([struct.pack('<h', 0)] * int(sample_rate * 0.02))
    _write_wav(filename, frames, sample_rate)


# ──────────────────────────────────────────────────────────────
# Anime primitives ✨
# ──────────────────────────────────────────────────────────────

def make_powerup(filename, sample_rate=44100, volume=0.38):
    """Classic anime power-up — ascending sweep with harmonics."""
    frames = []
    duration = 0.55
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        freq = 180 + 2200 * (t / duration) ** 1.4
        attack = min(1.0, t * 16)
        release = math.exp(-max(0, t - 0.45) * 25)
        env = attack * release
        val = _clamp(volume * 32767 * env * (
            0.65 * math.sin(2 * math.pi * freq * t) +
            0.25 * math.sin(2 * math.pi * freq * 2 * t) +
            0.10 * math.sin(2 * math.pi * freq * 3 * t)
        ))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_magic_chime(filename, sample_rate=44100, volume=0.33):
    """Anime magic — high-freq tone with vibrato shimmer."""
    frames = []
    duration = 0.65
    base_freq = 1760  # A6
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        vib = 1 + 0.025 * math.sin(2 * math.pi * 9 * t)
        freq = base_freq * vib
        env = math.sin(math.pi * t / duration) ** 0.5 * math.exp(-t * 1.8)
        val = _clamp(volume * 32767 * env * (
            0.7 * math.sin(2 * math.pi * freq * t) +
            0.3 * math.sin(2 * math.pi * freq * 2 * t)
        ))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_anime_whoosh(filename, sample_rate=44100, volume=0.28):
    """Fast action whoosh — high to low sweep with noise."""
    frames = []
    duration = 0.22
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        freq = 2800 - 2400 * (t / duration) ** 0.7
        env = math.sin(math.pi * t / duration) ** 0.6
        noise = random.random() * 2 - 1
        tone = math.sin(2 * math.pi * freq * t)
        val = _clamp(volume * 32767 * env * (0.45 * noise + 0.55 * tone))
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_anime_error(filename, sample_rate=44100, volume=0.38):
    """Anime fail — descending buzzer."""
    frames = []
    duration = 0.5
    n = int(sample_rate * duration)
    for i in range(n):
        t = i / sample_rate
        freq = 600 - 400 * (t / duration)
        env = math.exp(-t * 3)
        sq = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        val = _clamp(volume * 32767 * env * sq * 0.5)
        frames.append(struct.pack('<h', val))
    _write_wav(filename, frames, sample_rate)


def make_anime_start(filename, sample_rate=44100, volume=0.36):
    """Anime episode start — three ascending synth notes."""
    frames = []
    for freq in [392, 523, 784]:  # G4, C5, G5
        dur = 0.14
        n = int(sample_rate * dur)
        for i in range(n):
            t = i / sample_rate
            env = math.sin(math.pi * t / dur) ** 0.7
            val = _clamp(volume * 32767 * env * (
                0.7 * math.sin(2 * math.pi * freq * t) +
                0.3 * math.sin(2 * math.pi * freq * 2 * t)
            ))
            frames.append(struct.pack('<h', val))
        frames.extend([struct.pack('<h', 0)] * int(sample_rate * 0.04))
    _write_wav(filename, frames, sample_rate)


# ──────────────────────────────────────────────────────────────
# Theme generators
# ──────────────────────────────────────────────────────────────

def generate_zen():
    d = os.path.join(THEMES_DIR, "zen")
    os.makedirs(d, exist_ok=True)
    make_bell(f"{d}/start.wav",      392, 1.2)
    make_bell(f"{d}/done.wav",       523, 0.8)
    make_bell(f"{d}/permission.wav", 659, 0.5)
    make_bell(f"{d}/notify.wav",     440, 0.4)
    make_water_drop(f"{d}/write.wav")
    make_bell(f"{d}/bash.wav",       330, 0.3)
    make_bell(f"{d}/subtask.wav",    494, 0.5)
    make_bell(f"{d}/error.wav",      196, 0.9)
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
    make_bell(f"{d}/start.wav",      349, 0.8)
    make_bell(f"{d}/done.wav",       440, 0.6)
    make_bell(f"{d}/permission.wav", 554, 0.4)
    make_bell(f"{d}/notify.wav",     392, 0.3)
    make_water_drop(f"{d}/write.wav")
    make_bell(f"{d}/bash.wav",       330, 0.2)
    make_bell(f"{d}/subtask.wav",    415, 0.4)
    make_bell(f"{d}/error.wav",      220, 0.7)
    print(f"  ✓ cafe ({len(os.listdir(d))} files)")


def generate_wuxia():
    d = os.path.join(THEMES_DIR, "wuxia")
    os.makedirs(d, exist_ok=True)
    make_gong(f"{d}/start.wav",      freq=75,  duration=2.5)   # opening gong
    make_pluck(f"{d}/done.wav",      freq=330, duration=1.0)   # guqin D string
    make_double_chirp(f"{d}/permission.wav")                   # alert
    make_bell(f"{d}/notify.wav",     freq=523, duration=0.5)   # small bell
    make_swish(f"{d}/write.wav")                               # brush/sword stroke
    make_low_drum(f"{d}/bash.wav")                             # drum hit
    make_pluck(f"{d}/subtask.wav",   freq=440, duration=0.6)   # shorter pluck
    make_gong(f"{d}/error.wav",      freq=55,  duration=1.8)   # deeper gong
    print(f"  ✓ wuxia ({len(os.listdir(d))} files)")


def generate_cute():
    d = os.path.join(THEMES_DIR, "cute")
    os.makedirs(d, exist_ok=True)
    make_sparkle(f"{d}/start.wav")                             # sparkle entrance
    make_boing(f"{d}/done.wav")                                # happy boing
    make_double_chirp(f"{d}/permission.wav")                   # two cute pips
    make_cute_notify(f"{d}/notify.wav")                        # two-tone ping
    make_bubble_pop(f"{d}/write.wav")                          # bubble pop
    make_bubble_pop(f"{d}/bash.wav")                           # lighter pop
    make_bell(f"{d}/subtask.wav",    freq=1047, duration=0.25) # high ping
    make_cute_error(f"{d}/error.wav")                          # sad descend
    print(f"  ✓ cute ({len(os.listdir(d))} files)")


def generate_anime():
    d = os.path.join(THEMES_DIR, "anime")
    os.makedirs(d, exist_ok=True)
    make_anime_start(f"{d}/start.wav")                         # 3-note ascend
    make_powerup(f"{d}/done.wav")                              # power-up sweep
    make_magic_chime(f"{d}/permission.wav")                    # magic shimmer
    make_magic_chime(f"{d}/notify.wav")                        # lighter shimmer
    make_anime_whoosh(f"{d}/write.wav")                        # action whoosh
    make_anime_whoosh(f"{d}/bash.wav")                         # lighter whoosh
    make_sparkle(f"{d}/subtask.wav")                           # sparkle finish
    make_anime_error(f"{d}/error.wav")                         # descending fail
    print(f"  ✓ anime ({len(os.listdir(d))} files)")


if __name__ == "__main__":
    print("Generating theme sounds...")
    generate_zen()
    generate_forest()
    generate_retro()
    generate_cafe()
    generate_wuxia()
    generate_cute()
    generate_anime()
    print("\nDone. All sounds written to themes/")
    print("Tip: run 'bash scripts/generate_voice_theme.sh' to generate the voice theme (macOS only)")
