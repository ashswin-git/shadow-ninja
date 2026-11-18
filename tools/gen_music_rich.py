#!/usr/bin/env python3
"""Rich art pass: 8 longer, stereo, arranged procedural loops (original; koto/flute/taiko/shakuhachi-style synths).
44.1 kHz stereo, intro/A/B/A' sections, counter-melody, ping-pong delay + convolution reverb, OGG Vorbis q6.
Reuses the instrument primitives of tools/gen_music.py."""
import os, sys, wave, subprocess
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
import gen_music as gm
SR = 44100; gm.SR = SR
OUT = "assets/audio/music"

def reverb(x, secs=2.2, wet=0.28, seed=0):
    rng = np.random.default_rng(seed); n = int(SR * secs)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * 3.2)
    ir[:int(SR * 0.012)] = 0; ir /= np.sqrt((ir ** 2).sum())
    L = len(x); N = 1 << (L + n).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, N) * np.fft.rfft(ir, N), N)
    y = y[:L] + np.concatenate([y[L:L + n], np.zeros(max(0, L - n))])[:L]   # wrap tail -> seamless
    return x * (1 - wet) + y * wet * 0.6

def delay(x, t, fb=0.35, mix=0.25):
    d = int(SR * t); y = x.copy()
    for k in range(1, 5): y += np.roll(x, d * k) * (fb ** k) * mix / fb
    return y

def track(name, bpm, bars, root, scale, seed, lead="flute", counter="koto", drums="light", mood=1.0):
    rng = np.random.default_rng(seed)
    beat = 60.0 / bpm; L = bars * 4 * beat; n = int(L * SR)
    bus = {k: np.zeros(n) for k in ("pad", "ost", "lead", "cnt", "drm", "bass")}
    pr = root - 24
    sec = lambda b: 0 if b < bars * 0.125 else (1 if b < bars * 0.5 else (2 if b < bars * 0.8 else 3))   # intro/A/B/A'
    prog = [0, 0, 3, 1] if scale != "hira" else [0, 3, 0, 4]
    for b in range(0, bars, 2):
        sh = gm.deg(pr, scale, prog[(b // 2) % 4] + 5) - pr - 12
        gm.place(bus["pad"], gm.pad([gm.hz(pr + 12 + sh), gm.hz(pr + 19 + sh), gm.hz(pr + 24 + sh), gm.hz(pr + 31 + sh)], beat * 8), b * 4 * beat)
        gm.place(bus["bass"], gm.ks(gm.hz(pr + sh), beat * 3, 0.15, rng) * 0.5, b * 4 * beat)
        gm.place(bus["bass"], gm.ks(gm.hz(pr + sh + 7), beat * 2, 0.15, rng) * 0.35, (b * 4 + 3) * beat)
    ost = [0, 2, 4, 2, 1, 3, 4, 3]
    for b in range(bars):
        if sec(b) == 0 and b % 2: continue
        shift = prog[(b // 2) % 4]
        for k in range(8):
            if sec(b) == 2 and k % 2: continue
            nn = gm.deg(root - 12, scale, ost[k] + shift)
            gm.place(bus["ost"], gm.ks(gm.hz(nn), beat * 1.5, 0.3, rng) * 0.3, (b * 4 + k * 0.5) * beat)
    def phrase(seed2, lo, hi):
        r2 = np.random.default_rng(seed2); d = (lo + hi) // 2; p = []
        for i in range(10):
            d = int(np.clip(d + r2.choice([-2, -1, 1, 1, 2, 0, -1]), lo, hi)); p.append((d, r2.choice([1, 1, 2, 0.5, 0.5, 1.5])))
        return p
    A, B, C = phrase(seed * 7, 3, 9), phrase(seed * 7 + 1, 5, 11), phrase(seed * 7 + 2, 0, 6)
    def play(busn, ph, b0, b1, inst, oct=0, amp=1.0):
        t = b0 * 4 * beat; end = b1 * 4 * beat; j = 0
        while t < end:
            dd, ln = ph[j % len(ph)]; j += 1
            ln = min(ln * beat, end - t); nn = gm.deg(root + oct, scale, dd)
            if ln < 0.06: break
            if inst == "flute": sig = gm.flute(gm.hz(nn), ln * 1.1, rng) * 0.9
            else: sig = gm.ks(gm.hz(nn), ln * 2.2, 0.8, rng) * 0.6
            gm.place(bus[busn], sig * amp, t); t += ln
    bA0, bB0, bA1 = int(bars * 0.125), int(bars * 0.5), int(bars * 0.8)
    play("lead", A, bA0, bB0, lead)
    play("lead", B, bB0, bA1, lead, 0, 0.9)
    play("cnt", C, bB0, bA1, counter, -12, 0.55)
    play("lead", A, bA1, bars, lead)
    play("cnt", C, bA1, bars, counter, -12, 0.4)
    for b in range(bars):
        s = sec(b)
        for k in range(4):
            at = (b * 4 + k) * beat
            if drums == "none" or s == 0 and drums != "heavy": continue
            if drums == "light":
                if k == 0: gm.place(bus["drm"], gm.taiko(1.0, 80, rng, 0.55), at)
                if k == 2: gm.place(bus["drm"], gm.click(0.08, rng, 0.18), at)
                if s == 2 and k == 3: gm.place(bus["drm"], gm.taiko(0.6, 110, rng, 0.35), at + beat / 2)
            elif drums == "mid":
                if k in (0, 2): gm.place(bus["drm"], gm.taiko(1.0, 85, rng, 0.6), at)
                gm.place(bus["drm"], gm.click(0.08, rng, 0.14), at + beat / 2)
            else:
                gm.place(bus["drm"], gm.taiko(0.8, 70 if k % 2 == 0 else 95, rng, 0.75), at)
                if k == 3 or s == 2: gm.place(bus["drm"], gm.taiko(0.5, 120, rng, 0.45), at + beat / 2)
                gm.place(bus["drm"], gm.click(0.06, rng, 0.12), at + beat / 2)
    for k in bus: bus[k] /= max(1e-6, np.abs(bus[k]).max())
    pan = {"pad": (0.8, 0.8), "bass": (0.75, 0.75), "ost": (0.9, 0.45), "lead": (0.55, 0.9), "cnt": (0.85, 0.5), "drm": (0.8, 0.8)}
    vol = {"pad": 0.42 * mood, "bass": 0.45, "ost": 0.4, "lead": 0.55, "cnt": 0.32, "drm": 0.6 if drums != "none" else 0}
    Lc = np.zeros(n); Rc = np.zeros(n)
    for k, x in bus.items():
        if k == "lead": x = delay(x, beat * 0.75, 0.4, 0.3)
        Lc += x * vol[k] * pan[k][0]; Rc += np.roll(x, int(SR * 0.004) if k in ("ost", "cnt") else 0) * vol[k] * pan[k][1]
    Lc = reverb(Lc, 2.4, 0.3, seed); Rc = reverb(Rc, 2.4, 0.3, seed + 1)
    st = np.stack([Lc, Rc], 1); st /= np.abs(st).max() / 0.89
    wav = "/tmp/_mr_%s.wav" % name
    with wave.open(wav, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((st * 32767).astype(np.int16).tobytes())
    os.makedirs(OUT, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6", "%s/%s.ogg" % (OUT, name)], check=True)
    print(name, "%.1fs" % L, os.path.getsize("%s/%s.ogg" % (OUT, name)), "bytes")

if __name__ == "__main__":
    T = dict(
        menu=(72, 24, 62, "yo", 1, "flute", "koto", "none"),
        act1=(90, 32, 64, "yo", 2, "koto", "flute", "light"),
        act2=(84, 28, 62, "insen", 3, "flute", "koto", "mid"),
        act3=(104, 40, 60, "hira", 4, "koto", "flute", "mid"),
        boss_rin=(132, 44, 57, "insen", 5, "koto", "flute", "heavy"),
        boss_gorrah=(120, 40, 52, "hira", 6, "koto", "koto", "heavy"),
        boss_vey=(126, 40, 59, "insen", 7, "flute", "koto", "heavy"),
        victory=(96, 8, 67, "yo", 8, "flute", "koto", "light"))
    for k in (sys.argv[1:] or T): track(k, *T[k])
