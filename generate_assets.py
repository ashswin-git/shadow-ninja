import os
import wave
import struct
import math
from PIL import Image, ImageDraw

os.makedirs("assets/sprites", exist_ok=True)
os.makedirs("assets/backgrounds", exist_ok=True)
os.makedirs("assets/audio", exist_ok=True)

def create_player_sprite(filename, pose="idle"):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    # Silhouette style: dark body (#1a1a24), glowing red scarf (#ff2233)
    body_color = (20, 20, 28, 255)
    accent_color = (255, 40, 60, 255)
    eye_color = (255, 220, 50, 255)

    if pose == "idle":
        # Body / Torso
        draw.rectangle([24, 24, 40, 48], fill=body_color)
        # Head & Hood
        draw.ellipse([22, 12, 42, 32], fill=body_color)
        # Eyes
        draw.rectangle([32, 18, 38, 21], fill=eye_color)
        # Scarf flowing back
        draw.polygon([(26, 26), (8, 32), (24, 30)], fill=accent_color)
        # Limbs
        draw.rectangle([22, 48, 28, 60], fill=body_color)
        draw.rectangle([36, 48, 42, 60], fill=body_color)
    elif pose == "run":
        draw.rectangle([22, 26, 38, 50], fill=body_color)
        draw.ellipse([20, 14, 40, 34], fill=body_color)
        draw.rectangle([30, 20, 36, 23], fill=eye_color)
        draw.polygon([(24, 28), (4, 40), (22, 32)], fill=accent_color)
        # Running legs
        draw.rectangle([16, 50, 26, 62], fill=body_color)
        draw.rectangle([38, 48, 48, 60], fill=body_color)
    elif pose == "jump":
        draw.rectangle([24, 22, 40, 46], fill=body_color)
        draw.ellipse([22, 10, 42, 30], fill=body_color)
        draw.rectangle([32, 16, 38, 19], fill=eye_color)
        draw.polygon([(26, 24), (10, 16), (24, 28)], fill=accent_color)
        # Jumping tucked legs
        draw.rectangle([18, 46, 26, 56], fill=body_color)
        draw.rectangle([38, 44, 46, 54], fill=body_color)
    elif pose == "dash":
        draw.rectangle([18, 26, 46, 46], fill=body_color)
        draw.ellipse([28, 14, 48, 34], fill=body_color)
        draw.rectangle([38, 20, 44, 23], fill=eye_color)
        draw.polygon([(20, 30), (0, 36), (18, 34)], fill=accent_color)
        # Dash motion trail
        draw.rectangle([8, 32, 22, 40], fill=(255, 40, 60, 120))
    elif pose == "wall":
        draw.rectangle([24, 24, 40, 48], fill=body_color)
        draw.ellipse([20, 12, 40, 32], fill=body_color)
        draw.rectangle([26, 18, 32, 21], fill=eye_color)
        draw.polygon([(36, 26), (52, 20), (38, 30)], fill=accent_color)
        draw.rectangle([20, 48, 26, 60], fill=body_color)
        draw.rectangle([38, 48, 44, 60], fill=body_color)

    im.save(f"assets/sprites/{filename}")

create_player_sprite("player_idle.png", "idle")
create_player_sprite("player_run.png", "run")
create_player_sprite("player_jump.png", "jump")
create_player_sprite("player_dash.png", "dash")
create_player_sprite("player_wall.png", "wall")

# Shuriken
im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.polygon([(12, 2), (15, 9), (22, 12), (15, 15), (12, 22), (9, 15), (2, 12), (9, 9)], fill=(200, 210, 230, 255))
draw.ellipse([9, 9, 15, 15], fill=(40, 40, 50, 255))
im.save("assets/sprites/shuriken.png")

# Kunai
im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.polygon([(2, 16), (28, 12), (28, 20)], fill=(220, 220, 240, 255))
draw.rectangle([24, 14, 30, 18], fill=(100, 100, 110, 255))
im.save("assets/sprites/kunai.png")

# Enemy Patrol (Red Samurai / Ninja)
im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.rectangle([22, 24, 42, 50], fill=(80, 20, 20, 255))
draw.ellipse([20, 12, 44, 32], fill=(60, 15, 15, 255))
draw.rectangle([26, 18, 38, 22], fill=(255, 100, 0, 255))
draw.rectangle([22, 50, 28, 62], fill=(40, 10, 10, 255))
draw.rectangle([36, 50, 42, 62], fill=(40, 10, 10, 255))
im.save("assets/sprites/enemy_patrol.png")

# Enemy Ranged
im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.rectangle([22, 24, 42, 50], fill=(40, 40, 80, 255))
draw.ellipse([20, 12, 44, 32], fill=(30, 30, 60, 255))
draw.rectangle([26, 18, 38, 22], fill=(0, 200, 255, 255))
# Bow / Staff
draw.arc([12, 16, 32, 52], 270, 90, fill=(150, 100, 50, 255), width=3)
im.save("assets/sprites/enemy_ranged.png")

# Bosses
def create_boss_sprite(filename, color):
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    # Big imposing boss silhouette
    draw.rectangle([40, 36, 88, 100], fill=color)
    draw.ellipse([36, 16, 92, 60], fill=color)
    # Glowing evil eyes
    draw.rectangle([50, 30, 60, 36], fill=(255, 0, 0, 255))
    draw.rectangle([68, 30, 78, 36], fill=(255, 0, 0, 255))
    # Horns / spikes
    draw.polygon([(42, 20), (30, 2), (52, 16)], fill=color)
    draw.polygon([(86, 20), (98, 2), (76, 16)], fill=color)
    # Armor plates
    draw.rectangle([48, 50, 80, 70], fill=(50, 50, 60, 255))
    im.save(f"assets/sprites/{filename}")

create_boss_sprite("boss1.png", (100, 30, 30, 255))
create_boss_sprite("boss2.png", (30, 80, 50, 255))
create_boss_sprite("boss3.png", (60, 30, 90, 255))

# Tile (Cliff / Stone Block)
im = Image.new("RGBA", (32, 32), (30, 30, 40, 255))
draw = ImageDraw.Draw(im)
draw.rectangle([0, 0, 32, 4], fill=(50, 50, 70, 255))
draw.rectangle([0, 0, 4, 32], fill=(50, 50, 70, 255))
im.save("assets/sprites/tile.png")

# Spike
im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.polygon([(0, 32), (16, 0), (32, 32)], fill=(180, 180, 200, 255))
im.save("assets/sprites/spike.png")

# Saw blade
im = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.ellipse([4, 4, 44, 44], fill=(120, 120, 130, 255))
draw.ellipse([16, 16, 32, 32], fill=(60, 60, 70, 255))
for i in range(8):
    angle = i * math.pi / 4
    x1 = 24 + math.cos(angle) * 22
    y1 = 24 + math.sin(angle) * 22
    x2 = 24 + math.cos(angle + 0.3) * 16
    y2 = 24 + math.sin(angle + 0.3) * 16
    draw.polygon([(24, 24), (int(x1), int(y1)), (int(x2), int(y2))], fill=(200, 200, 210, 255))
im.save("assets/sprites/saw.png")

# Coin / Star
im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.ellipse([4, 4, 28, 28], fill=(255, 210, 40, 255))
draw.ellipse([10, 10, 22, 22], fill=(255, 240, 120, 255))
im.save("assets/sprites/coin.png")

# Checkpoint
im = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.rectangle([14, 0, 18, 64], fill=(100, 100, 120, 255))
draw.ellipse([6, 4, 26, 24], fill=(100, 200, 255, 255))
im.save("assets/sprites/checkpoint.png")

# Portal (Level Exit)
im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.ellipse([8, 8, 56, 56], fill=(120, 40, 255, 255))
draw.ellipse([16, 16, 48, 48], fill=(200, 150, 255, 255))
im.save("assets/sprites/portal.png")

# Parallax Backgrounds
def create_bg(filename, color1, color2):
    im = Image.new("RGBA", (512, 512), color1)
    draw = ImageDraw.Draw(im)
    for i in range(20):
        y = 250 + i * 15
        draw.rectangle([0, y, 512, y + 15], fill=color2)
    im.save(f"assets/backgrounds/{filename}")

create_bg("bg_sky.png", (15, 10, 30, 255), (35, 20, 50, 255))
create_bg("bg_mountains.png", (0, 0, 0, 0), (25, 20, 40, 255))
create_bg("bg_trees.png", (0, 0, 0, 0), (10, 25, 30, 255))

# Moon
im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
draw = ImageDraw.Draw(im)
draw.ellipse([16, 16, 112, 112], fill=(255, 240, 200, 255))
im.save("assets/backgrounds/bg_moon.png")

# Audio synthesis (WAV files)
def create_wav(filename, freq=440, duration=0.2, wave_type="sine"):
    sample_rate = 22050
    num_samples = int(sample_rate * duration)
    with wave.open(f"assets/audio/{filename}", "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        data = bytearray()
        for i in range(num_samples):
            t = i / sample_rate
            if wave_type == "sine":
                val = math.sin(2 * math.pi * freq * t)
            elif wave_type == "noise":
                import random
                val = random.uniform(-1, 1)
            elif wave_type == "sweep":
                f = freq * (1.0 - t / duration)
                val = math.sin(2 * math.pi * f * t)
            # Envelope
            env = 1.0 - (i / num_samples)
            sample = int(val * 32767 * env * 0.5)
            data.extend(struct.pack("<h", sample))
        wav_file.writeframes(data)

create_wav("jump.wav", freq=300, duration=0.15, wave_type="sweep")
create_wav("dash.wav", freq=600, duration=0.2, wave_type="noise")
create_wav("shuriken.wav", freq=880, duration=0.1, wave_type="sweep")
create_wav("hit.wav", freq=120, duration=0.2, wave_type="noise")
create_wav("coin.wav", freq=1200, duration=0.15, wave_type="sine")
create_wav("boss_roar.wav", freq=80, duration=0.6, wave_type="sweep")
create_wav("win.wav", freq=523.25, duration=0.5, wave_type="sine")
create_wav("click.wav", freq=440, duration=0.05, wave_type="sine")

print("Generated all assets successfully!")
