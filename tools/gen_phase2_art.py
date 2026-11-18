#!/usr/bin/env python3
"""Phase 2: key the original painted enemy / boss pose sheets (art_src/p2_*.jpg, generated
for this project on flat green) into uniform 4-frame strips in assets/sprites/p2/.
Frame order per strip: 0 idle, 1 move, 2 windup, 3 attack (see docs/ART_NEEDS.md).
Hurt / die / alert / recover are procedural on top of these frames."""
import os, numpy as np
from PIL import Image
from scipy import ndimage as ndi
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..")
SRC = os.path.join(ROOT, "art_src"); OUT = os.path.join(ROOT, "assets", "sprites", "p2")
# name -> target figure height in px (art stored at 1.5x; game draws at 1/1.5)
JOBS = {"oni_brute": 250, "kitsune_archer": 220, "shadow_assassin": 215, "bomb_monk": 215,
        "crow_scout": 150, "boss_gorrah": 330, "boss_vey": 330}

def key(path):
    a = np.asarray(Image.open(path).convert("RGB"), np.float32)
    bd = np.concatenate([a[:6].reshape(-1, 3), a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    bg = np.median(bd, 0)
    d = np.sqrt(((a - bg) ** 2).sum(-1))
    gd = a[..., 1] - np.maximum(a[..., 0], a[..., 2]); bgd = bg[1] - max(bg[0], bg[2])
    soft = np.clip((d - 40) / 35, 0, 1) * 0.5 + np.clip((bgd - gd - 10) / 25, 0, 1) * 0.5
    soft = np.maximum(soft, np.clip((d - 60) / 30, 0, 1))
    m = soft > 0.5
    m = ndi.binary_opening(m, iterations=1)
    m = ndi.binary_closing(m, iterations=1)
    core = ndi.binary_erosion(m, iterations=2)
    alpha = np.where(m, np.maximum(ndi.gaussian_filter(soft, 0.6), core), 0)
    alpha = ndi.gaussian_filter(alpha, 0.5)
    out = a.copy(); lim = np.maximum(out[..., 0], out[..., 2])
    spill = (out[..., 1] > lim + 4) & ndi.binary_dilation(~core, iterations=3)
    out[..., 1] = np.where(spill, lim + 4, out[..., 1])
    return np.concatenate([out, (alpha * 255)[..., None]], -1).astype(np.uint8), m

for name, th in JOBS.items():
    rgba, m = key(os.path.join(SRC, "p2_%s.jpg" % name))
    W = m.shape[1]
    lab, n = ndi.label(m)
    sizes = ndi.sum(m, lab, range(1, n + 1))
    groups = [np.zeros_like(m) for _ in range(4)]
    for i in range(n):
        if sizes[i] < 60: continue
        ys, xs = np.nonzero(lab == i + 1)
        groups[min(3, int(xs.mean() / (W / 4)))] |= (lab == i + 1)
    frames = []
    for g in groups:
        ys, xs = np.nonzero(g)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        f = rgba[y0:y1, x0:x1].copy(); f[..., 3] = np.where(g[y0:y1, x0:x1], f[..., 3], 0)
        frames.append(Image.fromarray(f, "RGBA"))
    # one scale for the whole strip (from the idle frame) so poses keep relative size
    s = th / frames[0].height
    frames = [f.resize((max(1, round(f.width * s)), max(1, round(f.height * s))), Image.LANCZOS) for f in frames]
    cw = max(f.width for f in frames) + 8; ch = max(f.height for f in frames) + 3 + 4
    strip = Image.new("RGBA", (cw * 4, ch), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.alpha_composite(f, (i * cw + (cw - f.width) // 2, ch - 3 - f.height))
    strip.save(os.path.join(OUT, name + ".png"))
    print(name, strip.size, "cell", cw, ch)
