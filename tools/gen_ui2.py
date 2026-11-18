# Original UI chrome for the NA2-style structural pass. CC0, in-repo.
# Layout language only — do not copy NA2 art.
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops
import math, random, os

R = "assets/ui/"
os.makedirs(R, exist_ok=True)
NA2 = "assets/na2/"

def save(im, name):
    im.save(R + name)
    print("wrote", name, im.size)

# ----- ornate silver chevrons (no disc) -----
def chevron(facing=1, w=320, h=216):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # design in a 160x108 space, then we draw at 2x
    cx, cy = w // 2, h // 2
    # outer arrow / kite frame
    if facing > 0:
        tip, back, top, bot = (w - 16, cy), (28, cy), (52, 18), (52, h - 18)
        mid_l, mid_r = (70, cy), (w - 70, cy)
    else:
        tip, back, top, bot = (16, cy), (w - 28, cy), (w - 52, 18), (w - 52, h - 18)
        mid_l, mid_r = (70, cy), (w - 70, cy)
    # flared wings
    if facing > 0:
        pts = [(back[0], cy), (top[0] - 8, 22), (w * 0.42, 14), (w * 0.62, 36),
               (tip[0] - 36, cy - 18), (tip[0], cy), (tip[0] - 36, cy + 18),
               (w * 0.62, h - 36), (w * 0.42, h - 14), (top[0] - 8, h - 22)]
        inner = [(back[0] + 22, cy), (w * 0.40, 36), (w * 0.58, 50),
                 (tip[0] - 50, cy - 8), (tip[0] - 28, cy), (tip[0] - 50, cy + 8),
                 (w * 0.58, h - 50), (w * 0.40, h - 36)]
    else:
        pts = [(back[0], cy), (top[0] + 8, 22), (w * 0.58, 14), (w * 0.38, 36),
               (tip[0] + 36, cy - 18), (tip[0], cy), (tip[0] + 36, cy + 18),
               (w * 0.38, h - 36), (w * 0.58, h - 14), (top[0] + 8, h - 22)]
        inner = [(back[0] - 22, cy), (w * 0.60, 36), (w * 0.42, 50),
                 (tip[0] + 50, cy - 8), (tip[0] + 28, cy), (tip[0] + 50, cy + 8),
                 (w * 0.42, h - 50), (w * 0.60, h - 36)]
    silver = (236, 240, 244, 255)
    rim = (200, 206, 214, 255)
    d.polygon(pts, fill=silver, outline=(24, 26, 30, 255))
    # hollow inner so the world shows through (cut-out decoration)
    cut = Image.new("L", (w, h), 0)
    ImageDraw.Draw(cut).polygon(inner, fill=255)
    # small diamond and arrow cutouts
    cd = ImageDraw.Draw(cut)
    if facing > 0:
        ax = w * 0.48
        cd.polygon([(ax, cy - 10), (ax + 16, cy), (ax, cy + 10), (ax - 10, cy)], fill=255)
        cd.polygon([(back[0] + 36, cy), (back[0] + 52, cy - 8), (back[0] + 52, cy + 8)], fill=255)
    else:
        ax = w * 0.52
        cd.polygon([(ax, cy - 10), (ax + 10, cy), (ax, cy + 10), (ax - 16, cy)], fill=255)
        cd.polygon([(back[0] - 36, cy), (back[0] - 52, cy - 8), (back[0] - 52, cy + 8)], fill=255)
    # apply cut to alpha
    r, g, b, a = im.split()
    a = ImageChops.subtract(a, cut)
    im = Image.merge("RGBA", (r, g, b, a))
    d = ImageDraw.Draw(im)
    # inner rim line
    d.line(pts + [pts[0]], fill=rim, width=3)
    return im

save(chevron(1), "chev_r.png")
save(chevron(-1), "chev_l.png")

# ----- HUD icons -----
def heart_icon():
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(32, 56), (8, 28), (8, 20), (16, 10), (28, 12), (32, 22), (36, 12), (48, 10), (56, 20), (56, 28)], fill=(200, 40, 48, 255), outline=(80, 10, 12, 255))
    d.ellipse([8, 10, 32, 36], fill=(200, 40, 48, 255))
    d.ellipse([32, 10, 56, 36], fill=(200, 40, 48, 255))
    d.ellipse([16, 16, 26, 26], fill=(240, 120, 120, 180))
    return im
save(heart_icon(), "hud_heart.png")

def gem_icon():
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(32, 6), (56, 26), (32, 58), (8, 26)], fill=(60, 190, 220, 255), outline=(20, 60, 80, 255))
    d.polygon([(32, 6), (44, 26), (32, 26), (20, 26)], fill=(140, 230, 245, 255))
    d.line([(20, 26), (44, 26)], fill=(20, 60, 80, 255), width=2)
    return im
save(gem_icon(), "hud_gem.png")

def gold_icon():
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([10, 20, 54, 48], radius=4, fill=(205, 162, 59, 255), outline=(90, 60, 16, 255), width=2)
    d.rounded_rectangle([16, 14, 48, 26], radius=3, fill=(230, 196, 90, 255), outline=(90, 60, 16, 255), width=2)
    d.line([(16, 34), (48, 34)], fill=(160, 110, 30, 255), width=2)
    return im
save(gold_icon(), "hud_gold.png")

# ----- diamond stage node + boss emblem -----
def diamond(locked=False, boss=False):
    im = Image.new("RGBA", (160, 160), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c, s = 80, 62
    pts = [(c, c - s), (c + s, c), (c, c + s), (c - s, c)]
    fill = (18, 20, 26, 240) if not locked else (12, 12, 16, 230)
    if boss:
        fill = (40, 16, 18, 245)
    d.polygon(pts, fill=fill, outline=(210, 200, 170, 255) if not locked else (90, 90, 100, 200))
    # inner diamond
    s2 = 50
    pts2 = [(c, c - s2), (c + s2, c), (c, c + s2), (c - s2, c)]
    d.polygon(pts2, outline=(140, 130, 100, 180) if not locked else (60, 60, 70, 160))
    if boss:
        # original oni-mask mark (not a copy): simple horned oval
        d.ellipse([c - 22, c - 16, c + 22, c + 22], outline=(210, 180, 140, 255), width=3)
        d.polygon([(c - 16, c - 12), (c - 22, c - 28), (c - 8, c - 14)], fill=(210, 180, 140, 255))
        d.polygon([(c + 16, c - 12), (c + 22, c - 28), (c + 8, c - 14)], fill=(210, 180, 140, 255))
        d.ellipse([c - 12, c - 2, c - 4, c + 8], fill=(200, 40, 40, 255))
        d.ellipse([c + 4, c - 2, c + 12, c + 8], fill=(200, 40, 40, 255))
    return im
save(diamond(False), "node_diamond.png")
save(diamond(True), "node_lock.png")
save(diamond(False, True), "node_boss.png")

# ----- home icon -----
def home():
    im = Image.new("RGBA", (96, 96), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(48, 14), (84, 46), (12, 46)], fill=(236, 236, 240, 255))
    d.rectangle([24, 46, 72, 84], fill=(236, 236, 240, 255))
    d.rectangle([40, 60, 56, 84], fill=(30, 32, 40, 255))
    return im
save(home(), "icon_home.png")

# ----- wood panel / button plate / book pages -----
def grain(w, h, base, seed=1):
    im = Image.new("RGB", (w, h), base)
    rnd = random.Random(seed)
    px = im.load()
    for y in range(h):
        for x in range(w):
            n = int(8 * math.sin(x / 18.0 + y / 70.0) + 6 * math.sin(y / 9.0 + x / 40.0))
            n += rnd.randint(-5, 5)
            r, g, b = px[x, y]
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n // 2)), max(0, min(255, b + n // 3)))
    # rings
    d = ImageDraw.Draw(im, "RGBA")
    for k in range(6):
        cx, cy = w // 2 + k * 8, h // 2
        d.ellipse([cx - 80 - k * 30, cy - 80 - k * 30, cx + 80 + k * 30, cy + 80 + k * 30], outline=base + (30,), width=1)
    return im

wood = grain(512, 640, (72, 52, 34), 3)
# darker edge
d = ImageDraw.Draw(wood)
d.rectangle([0, 0, 511, 639], outline=(40, 28, 16), width=10)
d.rectangle([8, 8, 503, 631], outline=(110, 86, 52), width=3)
save(wood.convert("RGBA"), "wood_panel.png")

page_l = grain(480, 640, (118, 100, 70), 7)
d = ImageDraw.Draw(page_l)
d.rectangle([0, 0, 479, 639], outline=(70, 52, 30), width=8)
save(page_l.convert("RGBA"), "book_page_l.png")

page_r = grain(480, 640, (42, 38, 34), 11)
d = ImageDraw.Draw(page_r)
d.rectangle([0, 0, 479, 639], outline=(70, 52, 30), width=8)
save(page_r.convert("RGBA"), "book_page_r.png")

# metal/wood button plate
btn = grain(400, 80, (50, 42, 34), 5)
d = ImageDraw.Draw(btn)
d.rectangle([0, 0, 399, 79], outline=(160, 140, 100), width=3)
d.rectangle([4, 4, 395, 75], outline=(30, 24, 18), width=1)
# corner flourishes
for x, y, dx, dy in [(10, 10, 1, 1), (389, 10, -1, 1), (10, 69, 1, -1), (389, 69, -1, -1)]:
    d.line([(x, y), (x + 12 * dx, y)], fill=(200, 180, 120), width=2)
    d.line([(x, y), (x, y + 12 * dy)], fill=(200, 180, 120), width=2)
save(btn.convert("RGBA"), "wood_btn.png")

btn_gold = grain(400, 80, (90, 68, 28), 9)
d = ImageDraw.Draw(btn_gold)
d.rectangle([0, 0, 399, 79], outline=(220, 190, 110), width=3)
save(btn_gold.convert("RGBA"), "wood_btn_gold.png")

# ----- winged boss-bar caps (left/right) -----
def wing(side=1):
    im = Image.new("RGBA", (80, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    if side < 0:
        pts = [(78, 8), (20, 2), (4, 20), (20, 38), (78, 32), (70, 20)]
    else:
        pts = [(2, 8), (60, 2), (76, 20), (60, 38), (2, 32), (10, 20)]
    d.polygon(pts, fill=(90, 22, 22, 255), outline=(200, 170, 110, 255))
    # inner metal
    d.polygon([(p[0] + side * 8, p[1]) for p in pts[1:5]], fill=(140, 36, 36, 255))
    return im
save(wing(-1), "boss_cap_l.png")
save(wing(1), "boss_cap_r.png")

# ----- act previews from existing original parallax -----
def preview(theme, name):
    W, H = 960, 360
    layers = ["sky", "far", "rays", "mid", "near"]
    out = Image.new("RGBA", (W, H), (20, 24, 32, 255))
    for L in layers:
        p = os.path.join(NA2, f"{theme}_{L}.png")
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert("RGBA").resize((1280, 720), Image.LANCZOS)
        crop = im.crop((160, 180, 1120, 540)).resize((W, H), Image.LANCZOS)
        out = Image.alpha_composite(out, crop)
    # mist grade
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    for y in range(H):
        a = int(40 + 50 * (y / H))
        gd.line([(0, y), (W, y)], fill=(8, 10, 16, a))
    out = Image.alpha_composite(out, g)
    # frame
    d = ImageDraw.Draw(out)
    d.rectangle([0, 0, W - 1, H - 1], outline=(40, 36, 32), width=10)
    d.rectangle([8, 8, W - 9, H - 9], outline=(170, 150, 110), width=3)
    save(out, name)

preview("snow", "preview_act1.png")
preview("forest", "preview_act2.png")
preview("boss", "preview_act3.png")

# ----- simple original hub tile art -----
def tile(kind):
    im = Image.new("RGBA", (480, 200), (18, 22, 30, 255))
    d = ImageDraw.Draw(im)
    # mist
    for i in range(8):
        d.ellipse([i * 60 - 20, 80, i * 60 + 140, 220], fill=(80, 100, 110, 30))
    if kind == "skills":
        # seated silhouette + soft aura (original)
        d.ellipse([70, 40, 190, 180], fill=(80, 40, 120, 50))
        d.polygon([(130, 70), (110, 130), (150, 130)], fill=(10, 10, 14, 255))
        d.ellipse([114, 48, 146, 82], fill=(10, 10, 14, 255))
        d.polygon([(90, 150), (130, 128), (170, 150), (130, 170)], fill=(10, 10, 14, 255))
    elif kind == "shop":
        d.rectangle([80, 70, 200, 160], fill=(20, 16, 14, 255))
        d.polygon([(70, 80), (140, 40), (210, 80)], fill=(30, 22, 16, 255))
        d.rectangle([125, 110, 155, 160], fill=(200, 160, 80, 255))
        d.ellipse([128, 80, 152, 104], fill=(220, 80, 50, 255))  # lantern
    elif kind == "artifact":
        d.ellipse([70, 30, 210, 170], outline=(160, 200, 210, 255), width=6)
        d.ellipse([110, 70, 170, 130], fill=(40, 80, 90, 255))
        for a in range(8):
            ang = a * math.pi / 4
            x, y = 140 + int(58 * math.cos(ang)), 100 + int(58 * math.sin(ang))
            d.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(20, 20, 24, 255), outline=(160, 200, 210, 200))
    else:  # challenge
        d.polygon([(80, 150), (140, 50), (200, 150)], fill=(16, 16, 20, 255))  # hill
        d.polygon([(150, 110), (170, 70), (190, 110), (210, 80), (200, 130), (150, 130)], fill=(160, 30, 30, 255))  # banner
        d.ellipse([124, 40, 156, 72], fill=(16, 16, 20, 255))
        d.polygon([(120, 70), (140, 110), (160, 70)], fill=(16, 16, 20, 255))
    d.rectangle([0, 0, 479, 199], outline=(80, 70, 55), width=2)
    return im
for k in ("skills", "shop", "artifact", "challenge"):
    save(tile(k), f"hub_{k}.png")

# story painting
st = Image.open(R + "preview_act1.png").resize((640, 280), Image.LANCZOS)
save(st, "hub_story.png")

# gold arrow for act select
def arrow(dir=1):
    im = Image.new("RGBA", (80, 120), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    if dir > 0:
        pts = [(8, 16), (72, 60), (8, 104), (18, 60)]
    else:
        pts = [(72, 16), (8, 60), (72, 104), (62, 60)]
    d.polygon(pts, fill=(205, 162, 59, 255), outline=(90, 60, 16, 255))
    return im
save(arrow(-1), "arrow_act_l.png")
save(arrow(1), "arrow_act_r.png")

# stone currency strip
strip = grain(1280, 56, (32, 34, 38), 2).convert("RGBA")
d = ImageDraw.Draw(strip)
d.rectangle([0, 0, 1279, 55], outline=(20, 20, 22), width=2)
save(strip, "currency_bar.png")

print("ok")
