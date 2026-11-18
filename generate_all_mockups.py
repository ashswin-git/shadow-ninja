from PIL import Image, ImageDraw, ImageFont, ImageFilter
import random, math

W, H = 1280, 720
FONT_PATH = "/usr/share/fonts/truetype/sand-box/custom/Open Sauce Sans/OpenSauceSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/sand-box/custom/Open Sauce Sans/OpenSauceSans-Regular.ttf"

def get_font(size, bold=True):
    try:
        return ImageFont.truetype(FONT_PATH if bold else FONT_REG, size)
    except:
        return ImageFont.load_default()

def draw_anime_bg(im, theme="city"):
    d = ImageDraw.Draw(im)
    for y in range(H):
        t = y / H
        if theme == "city":
            r = int(18 + 10 * t)
            g = int(13 + 8 * t)
            b = int(38 + 20 * t)
        elif theme == "shrine":
            r = int(24 + 12 * t)
            g = int(12 + 6 * t)
            b = int(45 + 15 * t)
        else: # boss
            r = int(40 + 20 * t)
            g = int(10 + 5 * t)
            b = int(30 + 15 * t)
        d.line([(0, y), (W, y)], fill=(r, g, b))

    # Moon
    mx, my = (1000, 160) if theme == "city" else (280, 140)
    d.ellipse([mx-90, my-90, mx+90, my+90], fill=(220, 230, 255))

    # Neon city skyline or shrine torii
    if theme == "city":
        # Buildings
        for bx in range(0, W, 140):
            bh = random.randint(250, 500)
            d.rectangle([bx, H-bh, bx+120, H], fill=(20, 18, 35))
            # Neon signs
            if bx % 280 == 0:
                d.rectangle([bx+20, H-bh+40, bx+100, H-bh+80], fill=(6, 182, 212))
            elif bx % 420 == 140:
                d.rectangle([bx+30, H-bh+60, bx+90, H-bh+100], fill=(239, 68, 68))
        # Power lines
        d.line([(0, 200), (W, 280)], fill=(80, 80, 100), width=2)
        d.line([(0, 320), (W, 220)], fill=(80, 80, 100), width=2)
    elif theme == "shrine":
        # Torii & Temple roofs
        d.rectangle([500, 200, 780, H], fill=(30, 15, 35))
        d.polygon([(460, 220), (820, 220), (800, 190), (480, 190)], fill=(180, 40, 40))
        d.polygon([(440, 200), (840, 200), (860, 175), (420, 175)], fill=(180, 40, 40))
        # Lanterns
        for lx in [350, 930]:
            d.rectangle([lx-15, 250, lx+15, 320], fill=(239, 68, 68))
            d.ellipse([lx-20, 310, lx+20, 350], fill=(251, 191, 36))
    else:
        # Boss arena cursed domain
        d.rectangle([0, 0, W, H], outline=(139, 92, 246), width=12)
        for i in range(10):
            d.line([(0, i*80), (W, i*80)], fill=(59, 130, 246, 50), width=2)

def draw_hud(d, level_name="Level 1: Ash Snow Gate"):
    # HP Hearts
    for i in range(3):
        d.text((40 + i*40, 30), "♥", font=get_font(32), fill=(239, 68, 68))
    # Ultimate Energy Meter
    d.rectangle([160, 34, 360, 56], fill=(30, 30, 50), outline=(59, 130, 246), width=2)
    d.rectangle([162, 36, 300, 54], fill=(139, 92, 246))
    d.text((165, 36), "ULTIMATE DOMAIN", font=get_font(14), fill=(255, 255, 255))

    # Title & Level
    d.text((W/2, 35), level_name, font=get_font(28), fill=(255, 255, 255), anchor="mm")

    # Score / Coins
    d.text((W-180, 35), "🪙 Coins: 2/3", font=get_font(22), fill=(251, 191, 36), anchor="mm")

def draw_touch_controls(d):
    # Left / Right
    d.ellipse([40, 560, 150, 670], outline=(255, 255, 255), width=4)
    d.text((95, 615), "<", font=get_font(40), fill=(255, 255, 255), anchor="mm")
    d.ellipse([170, 560, 280, 670], outline=(255, 255, 255), width=4)
    d.text((225, 615), ">", font=get_font(40), fill=(255, 255, 255), anchor="mm")

    # Jump / Dash / Throw / Ultimate
    buttons = [
        (W-130, 590, 110, 110, "JUMP", (34, 197, 94)),
        (W-260, 590, 110, 110, "DASH", (59, 130, 246)),
        (W-260, 460, 110, 110, "SLASH", (249, 115, 22)),
        (W-390, 590, 110, 110, "DOMAIN", (139, 92, 246)),
    ]
    for bx, by, bw, bh, btxt, bcol in buttons:
        d.ellipse([bx-bw/2, by-bh/2, bx+bw/2, by+bh/2], fill=bcol)
        d.text((bx, by), btxt, font=get_font(20), fill=(255, 255, 255), anchor="mm")

# 1. Main Menu
im = Image.new("RGB", (W, H))
draw_anime_bg(im, "city")
d = ImageDraw.Draw(im)
d.text((W/2, 180), "AETHER SHINOBI", font=get_font(72), fill=(255, 255, 255), anchor="mm")
d.text((W/2, 260), "— Spirit Blade Chronicles —", font=get_font(24), fill=(139, 92, 246), anchor="mm")

menu_items = ["Play Game", "Level Select", "Settings", "Quit"]
for i, item in enumerate(menu_items):
    by = 380 + i * 75
    sel = (i == 0)
    d.rounded_rectangle([W/2 - 180, by - 28, W/2 + 180, by + 28], 14, fill=(59, 130, 246) if sel else (30, 30, 50), outline=(139, 92, 246), width=3)
    d.text((W/2, by), item, font=get_font(26), fill=(255, 255, 255), anchor="mm")
im.save("ui-mockups/shot_menu.png")
im.save("ui-mockups/main_menu.png")

# 2. Level Select
im = Image.new("RGB", (W, H))
draw_anime_bg(im, "city")
d = ImageDraw.Draw(im)
d.text((W/2, 80), "SELECT LEVEL", font=get_font(52), fill=(255, 255, 255), anchor="mm")

levels = [
    ("Level 1", "Ash Snow Gate", True, "★★★"),
    ("Level 2", "Shrine Mist Gate", True, "★★☆"),
    ("Level 3", "Cyber Outskirts", True, "★☆☆"),
    ("Level 4", "Boss: Spirit Overlord", True, "★★★"),
]
for i, (ln, desc, unlocked, stars) in enumerate(levels):
    lx = 200 + (i % 2) * 480
    ly = 240 + (i // 2) * 220
    d.rounded_rectangle([lx, ly, lx+400, ly+180], 16, fill=(30, 30, 50), outline=(139, 92, 246) if unlocked else (80, 80, 80), width=4)
    d.text((lx+30, ly+30), ln, font=get_font(30), fill=(255, 255, 255))
    d.text((lx+30, ly+75), desc, font=get_font(18), fill=(150, 150, 180))
    d.text((lx+30, ly+120), stars, font=get_font(22), fill=(251, 191, 36))
im.save("ui-mockups/shot_levelselect.png")
im.save("ui-mockups/level_select.png")

# 3. Level 1 (Ash Snow Gate)
im = Image.new("RGB", (W, H))
draw_anime_bg(im, "city")
d = ImageDraw.Draw(im)
# Platforms
d.rectangle([100, 550, 500, 590], fill=(20, 18, 35))
d.line([(100, 550), (500, 550)], fill=(59, 130, 246), width=4)
d.rectangle([600, 450, 1000, 490], fill=(20, 18, 35))
d.line([(600, 450), (1000, 450)], fill=(59, 130, 246), width=4)
# Hero sprite placeholder
d.rectangle([250, 470, 290, 550], fill=(139, 92, 246))
d.ellipse([255, 440, 285, 470], fill=(255, 255, 255))
# Enemy sprite
d.rectangle([800, 390, 840, 450], fill=(239, 68, 68))
draw_hud(d, "Level 1: Ash Snow Gate")
draw_touch_controls(d)
im.save("ui-mockups/shot_l1.png")
im.save("ui-mockups/gameplay_hud.png")

# 4. Level 2 (Shrine Mist Gate)
im = Image.new("RGB", (W, H))
draw_anime_bg(im, "shrine")
d = ImageDraw.Draw(im)
# Shrine Platforms
d.rectangle([150, 520, 550, 560], fill=(40, 20, 30))
d.line([(150, 520), (550, 520)], fill=(239, 68, 68), width=4)
d.rectangle([650, 420, 1050, 460], fill=(40, 20, 30))
d.line([(650, 420), (1050, 420)], fill=(239, 68, 68), width=4)
# Hero
d.rectangle([300, 440, 340, 520], fill=(59, 130, 246))
d.ellipse([305, 410, 335, 440], fill=(255, 255, 255))
draw_hud(d, "Level 2: Shrine Mist Gate")
draw_touch_controls(d)
im.save("ui-mockups/shot_l2.png")

# 5. Boss Arena (Spirit Overlord)
im = Image.new("RGB", (W, H))
draw_anime_bg(im, "boss")
d = ImageDraw.Draw(im)
# Boss Health Bar at top center
d.rectangle([W/2 - 300, 80, W/2 + 300, 110], fill=(30, 30, 50), outline=(239, 68, 68), width=3)
d.rectangle([W/2 - 296, 84, W/2 + 150, 106], fill=(239, 68, 68))
d.text((W/2, 95), "SPIRIT OVERLORD - PHASE 2", font=get_font(18), fill=(255, 255, 255), anchor="mm")
# Boss
d.rectangle([850, 350, 930, 520], fill=(239, 68, 68))
# Hero
d.rectangle([350, 440, 390, 520], fill=(139, 92, 246))
draw_hud(d, "Boss Arena: Aether Sanctum")
draw_touch_controls(d)
im.save("ui-mockups/shot_boss.png")

# 6. Side by Side Comparisons
def make_side_by_side(ref_path, our_path, out_path, title):
    try:
        ref = Image.open(ref_path).resize((640, 360))
    except:
        ref = Image.new("RGB", (640, 360), (40, 40, 50))
    try:
        our = Image.open(our_path).resize((640, 360))
    except:
        our = Image.new("RGB", (640, 360), (20, 20, 30))

    sbs = Image.new("RGB", (1280, 420), (15, 15, 25))
    sbs.paste(ref, (0, 60))
    sbs.paste(our, (640, 60))
    sd = ImageDraw.Draw(sbs)
    sd.text((320, 30), f"Reference ({title})", font=get_font(24), fill=(255, 255, 255), anchor="mm")
    sd.text((960, 30), f"Aether Shinobi ({title})", font=get_font(24), fill=(59, 130, 246), anchor="mm")
    sd.line([(640, 0), (640, 420)], fill=(80, 80, 100), width=2)
    sbs.save(out_path)

make_side_by_side("reference/level1/appstore_01.jpg", "ui-mockups/shot_l1.png", "ui-mockups/level1_side_by_side.png", "Level 1 Forest (NA2 ref)")
make_side_by_side("reference/ninja_arashi2/appstore_03.jpg", "ui-mockups/shot_l2.png", "ui-mockups/level2_side_by_side.png", "Level 2 Shrine")
print("All mockups generated successfully.")
