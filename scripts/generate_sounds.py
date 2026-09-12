#!/usr/bin/env python3
"""Generate original short WAV samples for George (typing, hmm, throat-clear)."""

from __future__ import annotations

import math
import os
import random
import struct
import wave

SR = 44100
ROOT = os.path.join(os.path.dirname(__file__), "..", "George", "Resources", "Sounds")


def write_wav(path: str, samples: list[float]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32767)) for sample in samples
        )
        wav.writeframes(frames)


def key_click(seed: int) -> list[float]:
    rnd = random.Random(seed)
    duration = 0.024 + rnd.uniform(0.0, 0.016)
    count = int(SR * duration)
    freq = rnd.uniform(1700, 4300)
    decay = rnd.uniform(70, 170)
    mix = rnd.uniform(0.35, 0.65)
    samples = []
    for index in range(count):
        t = index / SR
        env = math.exp(-t * decay)
        noise = rnd.uniform(-1.0, 1.0)
        tone = math.sin(2 * math.pi * freq * t)
        click = (noise * (1 - mix) + tone * mix) * env
        samples.append(click * 0.85)
    return samples


def hum(seed: int) -> list[float]:
    rnd = random.Random(seed)
    duration = 0.42 + rnd.uniform(0.0, 0.28)
    count = int(SR * duration)
    base = rnd.uniform(110, 175)
    vibrato = rnd.uniform(4.2, 6.4)
    samples = []
    for index in range(count):
        t = index / SR
        attack = min(1.0, t / 0.05)
        release = min(1.0, (duration - t) / 0.08)
        env = attack * release
        freq = base * (1 + 0.03 * math.sin(2 * math.pi * vibrato * t))
        wave1 = math.sin(2 * math.pi * freq * t)
        wave2 = 0.35 * math.sin(2 * math.pi * freq * 2 * t)
        wave3 = 0.12 * math.sin(2 * math.pi * freq * 3 * t)
        nasel = 0.18 * math.sin(2 * math.pi * 240 * t) * env
        samples.append((wave1 + wave2 + wave3 + nasel) * env * 0.34)
    return samples


def throat(seed: int) -> list[float]:
    rnd = random.Random(seed)
    duration = 0.22 + rnd.uniform(0.0, 0.12)
    count = int(SR * duration)
    samples = []
    cutoff = rnd.uniform(700, 1400)
    for index in range(count):
        t = index / SR
        env = math.exp(-t * 9) * (1 if t > 0.012 else t / 0.012)
        scrape = rnd.uniform(-1.0, 1.0)
        # crude one-pole low-pass
        if samples:
            scrape = 0.25 * scrape + 0.75 * samples[-1] / max(env, 0.05)
        tone = math.sin(2 * math.pi * cutoff * t) * 0.15
        samples.append((scrape * 0.7 + tone) * env * 0.55)
    return samples


def main() -> None:
    typing_dir = os.path.join(ROOT, "typing")
    hmm_dir = os.path.join(ROOT, "hmm")
    throat_dir = os.path.join(ROOT, "throat")

    for index in range(1, 7):
        write_wav(os.path.join(typing_dir, f"typing-{index}.wav"), key_click(100 + index))
    for index in range(1, 4):
        write_wav(os.path.join(hmm_dir, f"hmm-{index}.wav"), hum(200 + index))
    for index in range(1, 3):
        write_wav(os.path.join(throat_dir, f"throat-{index}.wav"), throat(300 + index))

    print("Wrote typing, hmm, and throat samples.")


if __name__ == "__main__":
    main()
