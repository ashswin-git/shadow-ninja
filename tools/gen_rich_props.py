#!/usr/bin/env python3
"""Rich art pass: weather particle sprites (snow flake, ember) + bespoke DOMAIN cast SFX (original, procedural)."""
import math, os, wave, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
os.makedirs("assets/fx", exist_ok=True)
S = 128
# snow flake: soft core + 6 thin arms with side twigs, drawn 4x and downsampled to 32 px
im = Image.new("L", (S, S), 0); d = ImageDraw.Draw(im); c = S / 2
for k in range(6):
    a = k * math.pi / 3; x1, y1 = c + math.cos(a) * 54, c + math.sin(a) * 54
    d.line([(c, c), (x1, y1)], fill=255, width=6)
    for f in (0.45, 0.7):
        bx, by = c + math.cos(a) * 54 * f, c + math.sin(a) * 54 * f
        for s in (-1, 1):
            d.line([(bx, by), (bx + math.cos(a + s * 0.8) * 16, by + math.sin(a + s * 0.8) * 16)], fill=255, width=4)
d.ellipse([c - 12, c - 12, c + 12, c + 12], fill=255)
glow = im.filter(ImageFilter.GaussianBlur(6))
a = np.maximum(np.asarray(im, np.float32), np.asarray(glow, np.float32) * 0.8)
rgb = np.full((S, S, 3), 255, np.uint8)
Image.fromarray(np.dstack([rgb, a.astype(np.uint8)]), "RGBA").resize((32, 32), Image.LANCZOS).save("assets/fx/flake.png")
# ember: hot core + soft halo (white core tinted by particle colour)
yy, xx = np.mgrid[0:64, 0:64]; r = np.hypot(xx - 32, yy - 32) / 32
al = np.clip(np.exp(-r * r * 9) + np.exp(-r * r * 2.2) * 0.45, 0, 1)
core = np.clip(1 - r * 3, 0, 1)
rgb = np.dstack([np.full_like(r, 1.0), 0.75 + 0.25 * core, 0.45 + 0.55 * core])
Image.fromarray((np.dstack([rgb, al]) * 255).astype(np.uint8), "RGBA").resize((24, 24), Image.LANCZOS).save("assets/fx/ember.png")
# DOMAIN cast: low temple gong + rising shimmer + air whoosh, 2.2 s
SR = 44100; t = np.arange(int(SR * 2.2)) / SR; rng = np.random.default_rng(9)
gong = sum(np.sin(2 * np.pi * f * t + p) * a for f, a, p in [(73.4, 1, 0), (146.8, 0.5, 1), (220.5, 0.35, 2), (277, 0.25, 3), (415, 0.12, 4)])
gong *= np.exp(-t * 1.6) * (1 - np.exp(-t * 60))
sweep = np.sin(2 * np.pi * np.cumsum(400 + 1800 * t / 2.2) / SR) * np.exp(-((t - 0.9) / 0.5) ** 2) * 0.25
sweep += np.sin(2 * np.pi * np.cumsum(603 + 2700 * t / 2.2) / SR) * np.exp(-((t - 1.0) / 0.45) ** 2) * 0.15
n = rng.standard_normal(len(t)); n = np.convolve(n, np.ones(40) / 40, "same")
whoosh = n * np.exp(-((t - 0.35) / 0.22) ** 2) * 1.6
sig = gong * 0.7 + sweep + whoosh
st = np.stack([sig, np.roll(sig, int(SR * 0.006))], 1); st /= np.abs(st).max() / 0.9
with wave.open("/tmp/_domain.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((st * 32767).astype(np.int16).tobytes())
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", "/tmp/_domain.wav", "-c:a", "libvorbis", "-q:a", "6", "assets/audio/sfx/domain.ogg"], check=True)
print("ok")
