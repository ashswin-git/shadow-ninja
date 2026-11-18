#!/usr/bin/env python3
"""Phase 1: pack the painted hero pose frames (assets/sprites/hero/*.png, original art from
tools/gen_char.py / art_src/hero2_*) into uniform-cell sprite sheets.

PLACEHOLDER IN-BETWEENS: only 4 run keys, 1 idle and 7+4 slash frames are painted. The extra
cells here are derived from those keys (passing-pose lift/squash, breathing scale, per-hit
regrouping) so the 8-run / 6-idle / 3x5-slash timing works in game now. Real painted
in-betweens are listed in docs/ART_NEEDS.md; drop them into the same cell layout and re-run.

Sheets (cells bottom-aligned, horizontally centred, 4 px transparent padding for the outline,
3 px under the feet like the single frames):
  hero_idle_sheet.png   6 x 1
  hero_run_sheet.png    8 x 1
  hero_slash_sheet.png  5 x 3   (row 0 = hit 1, row 1 = hit 2, row 2 = hit 3 finisher)
"""
from PIL import Image
import os, json
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "assets", "sprites", "hero")
PAD = 4

def load(k): return Image.open(os.path.join(SRC, k + ".png")).convert("RGBA")

def warp(img, sy=1.0, sx=1.0, lift=0):
    """scale around the feet (bottom centre); `lift` px of empty space under the feet"""
    w, h = img.size
    nw, nh = max(1, round(w * sx)), max(1, round(h * sy))
    r = img.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", (max(w, nw), nh + lift), (0, 0, 0, 0))
    out.alpha_composite(r, ((out.width - nw) // 2, 0))
    return out

def sheet(rows, name):
    frames = [f for r in rows for f in r]
    cw = max(f.width for f in frames) + PAD * 2
    ch = max(f.height for f in frames) + PAD * 2
    cols = max(len(r) for r in rows)
    out = Image.new("RGBA", (cw * cols, ch * len(rows)), (0, 0, 0, 0))
    for j, r in enumerate(rows):
        for i, f in enumerate(r):
            # bottom aligned: keep the painted 3 px foot pad, add PAD below so the sheet cell pad = 3+PAD
            out.alpha_composite(f, (i * cw + (cw - f.width) // 2, j * ch + ch - PAD - f.height))
    out.save(os.path.join(SRC, name))
    assert ch >= 128, name
    return {"cols": cols, "rows": len(rows), "cell": [cw, ch]}

meta = {}
idle = load("idle")
# 6-frame breathing loop: inhale (taller, narrower), hold, exhale
breath = [(1.0, 1.0), (1.012, 0.996), (1.024, 0.992), (1.03, 0.99), (1.018, 0.995), (1.006, 0.998)]
meta["idle"] = sheet([[warp(idle, sy, sx) for sy, sx in breath]], "hero_idle_sheet.png")
# 8-frame run: contact key, then a lifted passing in-between derived from the next key
run = [load("run%d" % i) for i in range(1, 5)]
cells = []
for i in range(4):
    cells.append(run[i])
    cells.append(warp(run[(i + 1) % 4], 1.03, 0.98, 5))
meta["run"] = sheet([cells], "hero_run_sheet.png")
# 3-hit slash combo, 5 frames each: windup, swing, contact, follow, recover
k = {n: load(n) for n in ["s_windup", "s_high", "s_contact", "s_through", "s_over", "s_follow", "s_recover",
                          "a_contact", "a_down", "a_follow"]}
hit1 = [k["s_windup"], k["s_high"], k["s_contact"], k["s_through"], k["s_follow"]]
hit2 = [k["s_follow"], k["s_over"], k["a_contact"], k["a_down"], k["s_recover"]]           # return backhand
hit3 = [warp(k["s_windup"], 0.94, 1.04), k["s_high"], k["s_through"], k["s_over"], k["a_follow"]]  # heavy finisher
meta["slash"] = sheet([hit1, hit2, hit3], "hero_slash_sheet.png")
json.dump(meta, open(os.path.join(SRC, "sheets.json"), "w"), indent=1)
print(json.dumps(meta))
