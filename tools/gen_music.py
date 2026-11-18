#!/usr/bin/env python3
"""Phase 5: original procedural music (no samples, no third-party material).
Koto = Karplus-Strong pluck, shakuhachi = breathy sine with vibrato, taiko = pitch-dropping
sine + noise, plus a drone pad. Each track is a seamless loop (tails wrap to the start).
Output: assets/audio/music/<track>.ogg (mono 22.05 kHz Vorbis). Deterministic (fixed seeds)."""
import numpy as np, subprocess, os, wave
SR = 22050
OUT = "assets/audio/music"

def ks(freq, dur, bright=0.5, rng=None):
	n = int(SR * dur); p = max(2, int(SR / freq))
	buf = (rng.random(p) * 2 - 1) * 0.6
	out = np.zeros(n)
	for i in range(n):
		out[i] = buf[i % p]
		buf[i % p] = 0.5 * (buf[i % p] + buf[(i + 1) % p]) * (0.994 + 0.005 * bright)
	return out * np.exp(-np.linspace(0, 3.0, n))

def flute(freq, dur, rng):
	t = np.arange(int(SR * dur)) / SR
	vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 2, 0, 1)
	ph = 2 * np.pi * np.cumsum(freq * vib) / SR
	tone = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
	noise = np.convolve(rng.standard_normal(len(t)), np.ones(12) / 12, "same") * 0.12
	env = np.clip(t / 0.12, 0, 1) * np.clip((dur - t) / 0.25, 0, 1)
	return (tone + noise) * env * 0.35

def taiko(dur, pitch=90, rng=None, amp=1.0):
	t = np.arange(int(SR * dur)) / SR
	f = pitch * (0.55 + 0.45 * np.exp(-t * 18))
	body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)
	hit = rng.standard_normal(len(t)) * np.exp(-t * 60) * 0.35
	return (body + hit) * amp

def click(dur=0.08, rng=None, amp=0.3):
	t = np.arange(int(SR * dur)) / SR
	return np.sin(2 * np.pi * 1700 * t) * np.exp(-t * 90) * amp + rng.standard_normal(len(t)) * np.exp(-t * 150) * amp * 0.4

def pad(freqs, dur):
	t = np.arange(int(SR * dur)) / SR
	s = sum(np.sin(2 * np.pi * f * t + i) for i, f in enumerate(freqs)) / len(freqs)
	return s * (0.55 + 0.45 * np.sin(2 * np.pi * t / dur)) * 0.18

def place(buf, sig, at):
	i = int(at * SR) % len(buf)
	end = i + len(sig)
	if end <= len(buf): buf[i:end] += sig
	else:
		k = len(buf) - i; buf[i:] += sig[:k]; buf[:end - len(buf)] += sig[k:]   # wrap tail -> seamless loop

def hz(note): return 440.0 * 2 ** ((note - 69) / 12)

SCALES = {"yo": [0, 2, 5, 7, 9], "insen": [0, 1, 5, 7, 10], "hira": [0, 2, 3, 7, 8]}

def deg(root, scale, d):
	s = SCALES[scale]; return root + 12 * (d // 5) + s[d % 5]

def track(name, bpm, bars, root, scale, seed, melody="koto", drums="light", padroot=None):
	rng = np.random.default_rng(seed)
	beat = 60.0 / bpm; L = bars * 4 * beat
	buf = np.zeros(int(L * SR))
	pr = padroot if padroot is not None else root - 12
	for b in range(0, bars, 2):
		place(buf, pad([hz(pr), hz(pr + 7), hz(pr + 12)], beat * 8), b * 4 * beat)
	# ostinato (koto, 8ths)
	ost = [0, 2, 4, 2, 1, 3, 4, 3]
	for b in range(bars):
		shift = [0, 0, 3, 1][b % 4]
		for k in range(8):
			n = deg(root - 12, scale, ost[k] + shift)
			place(buf, ks(hz(n), beat * 1.5, 0.3, rng) * 0.32, (b * 4 + k * 0.5) * beat)
	# melody: random walk on the scale, phrase repeats every 4 bars with a variation
	phrase = []
	d = 5
	for i in range(8):
		d = int(np.clip(d + rng.choice([-2, -1, 1, 1, 2, 0]), 3, 9)); phrase.append((d, rng.choice([1, 1, 2, 0.5, 1.5])))
	for b4 in range(0, bars, 4):
		t = b4 * 4 * beat; end = (b4 + 4) * 4 * beat
		for j, (dd, ln) in enumerate(phrase):
			if t >= end: break
			if b4 % 8 == 4 and j > 4: dd = max(3, dd - 2)
			n = deg(root, scale, dd); ln = min(ln * beat, end - t)
			sig = flute(hz(n), ln * 1.1, rng) if melody == "flute" else ks(hz(n), ln * 2.2, 0.8, rng) * 0.6
			place(buf, sig, t); t += ln
	# percussion
	for b in range(bars):
		for k in range(4):
			at = (b * 4 + k) * beat
			if drums == "light":
				if k == 0: place(buf, taiko(1.0, 80, rng, 0.55), at)
				if k == 2: place(buf, click(0.08, rng, 0.18), at)
			elif drums == "mid":
				if k in (0, 2): place(buf, taiko(1.0, 85, rng, 0.6), at)
				place(buf, click(0.08, rng, 0.14), at + beat / 2)
			elif drums == "heavy":
				place(buf, taiko(0.8, 70 if k % 2 == 0 else 95, rng, 0.75), at)
				if k == 3: place(buf, taiko(0.5, 120, rng, 0.45), at + beat / 2)
				place(buf, click(0.06, rng, 0.12), at + beat / 2)
	buf /= max(1e-6, np.abs(buf).max()) / 0.85
	os.makedirs(OUT, exist_ok=True)
	wav = "/tmp/_m_%s.wav" % name
	with wave.open(wav, "wb") as w:
		w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((buf * 32767).astype(np.int16).tobytes())
	subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "0", "-ac", "1", "-ar", str(SR), "%s/%s.ogg" % (OUT, name)], check=True)
	print(name, "%.1fs" % L, os.path.getsize("%s/%s.ogg" % (OUT, name)), "bytes")

if __name__ == "__main__":
	track("menu", 72, 8, 62, "yo", 1, melody="flute", drums="none")
	track("act1", 90, 12, 64, "yo", 2, melody="koto", drums="light")
	track("act2", 84, 12, 62, "insen", 3, melody="flute", drums="mid")
	track("act3", 104, 16, 60, "hira", 4, melody="koto", drums="mid")
	track("boss", 132, 16, 57, "insen", 5, melody="koto", drums="heavy")
