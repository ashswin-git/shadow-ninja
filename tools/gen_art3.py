# Phase 4 original art: aura, portrait, icon buttons, snow rim, painted fog, foreground silhouettes. CC0.
from PIL import Image, ImageDraw, ImageFilter
import math, random
R='assets/'; random.seed(7)
a=Image.new('RGBA',(96,96)); d=ImageDraw.Draw(a); d.ellipse([18,8,78,92],fill=(70,160,255,110)); a.filter(ImageFilter.GaussianBlur(10)).save(R+'sprites/aura.png')
# portrait: circle frame, zoomed head of hero
hero=Image.open(R+'sprites/player_idle.png').crop((14,0,50,36)).resize((180,180),Image.NEAREST)
p=Image.new('RGBA',(200,200)); d=ImageDraw.Draw(p); d.ellipse([0,0,199,199],fill=(30,40,80,255)); 
p.alpha_composite(hero,(10,14)); m=Image.new('L',(200,200)); ImageDraw.Draw(m).ellipse([0,0,199,199],fill=255)
out=Image.new('RGBA',(200,200)); out.paste(p,(0,0),m); d=ImageDraw.Draw(out); d.ellipse([2,2,197,197],outline=(110,190,255,255),width=8); out.save(R+'ui/portrait.png')
S=128; W=(255,255,255,235)
def icon(name,fn):
    im=Image.new('RGBA',(S*2,S*2)); d=ImageDraw.Draw(im); fn(d); im.resize((S,S),Image.LANCZOS).save(R+f'ui/btn_{name}.png')
icon('left',lambda d:d.polygon([(70,128),(170,50),(170,206)],fill=W))
icon('right',lambda d:d.polygon([(186,128),(86,50),(86,206)],fill=W))
icon('jump',lambda d:(d.polygon([(128,40),(210,140),(160,140),(160,210),(96,210),(96,140),(46,140)],fill=W)))
def slash(d):
    d.arc([30,30,226,226],200,330,fill=W,width=22); d.line([(70,200),(190,70)],fill=W,width=14)
icon('slash',slash)
def dash(d):
    d.polygon([(120,60),(220,128),(120,196)],fill=W)
    for i,y in enumerate([80,128,176]): d.line([(30+i*10,y),(110,y)],fill=W,width=14)
icon('dash',dash)
def dom(d):
    d.ellipse([40,40,216,216],outline=W,width=16); d.ellipse([96,96,160,160],fill=W)
    for k in range(6):
        a=k*math.pi/3; d.line([(128+70*math.cos(a),128+70*math.sin(a)),(128+110*math.cos(a+0.5),128+110*math.sin(a+0.5))],fill=W,width=10)
icon('domain',dom)
icon('kunai',lambda d:(d.polygon([(200,56),(150,140),(120,110)],fill=W),d.line([(135,125),(60,200)],fill=W,width=16),d.ellipse([40,190,80,230],outline=W,width=10)))
# snow rim with drips
r=Image.new('RGBA',(64,16)); d=ImageDraw.Draw(r); d.rounded_rectangle([0,2,63,9],4,fill=(245,248,255,255))
for x in [8,30,50]: d.polygon([(x,8),(x+6,8),(x+3,14)],fill=(225,235,250,255))
d.line([(0,3),(63,3)],fill=(255,255,255,255)); r.save(R+'sprites/snow_rim.png')
# painted fog (brushy horizontal strokes)
f=Image.new('RGBA',(1280,720)); d=ImageDraw.Draw(f)
for i in range(70):
    x=random.randint(-200,1280); y=random.randint(380,620); w=random.randint(200,500)
    d.ellipse([x,y,x+w,y+random.randint(20,50)],fill=(225,205,230,random.randint(10,26)))
f=f.filter(ImageFilter.GaussianBlur(14)); f.save(R+'backgrounds/bg_fog.png')
# foreground silhouettes: dark grass/bamboo at bottom edge and hanging branch at top
g=Image.new('RGBA',(1600,720)); d=ImageDraw.Draw(g); C=(0,0,0,255)
for x in range(0,1600,6):
    h=random.randint(10,40) if (x//300)%2==0 else random.randint(0,14)
    d.polygon([(x,720),(x+3,720-h),(x+7,720)],fill=C)
for x0 in [120,900]:
    d.rectangle([x0,560,x0+18,720],fill=C); d.rectangle([x0+40,600,x0+52,720],fill=C)
    for y in range(570,720,40): d.polygon([(x0+9,y),(x0+70,y+14),(x0+9,y+8)],fill=C)
d.line([(1250,0),(1330,60),(1450,80),(1600,70)],fill=C,width=14)
for x in range(1300,1600,30):
    d.ellipse([x,50+random.randint(0,30),x+40,80+random.randint(0,30)],fill=(0,0,0,255))
    d.ellipse([x+10,70,x+24,84],fill=(0,0,0,255))
g.save(R+'backgrounds/fg_silhouette.png')
print('ok')
# Boss arena: moonlit temple courtyard, red sky
W,H=1280,720
sky=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(sky)
for y in range(H):
    t=y/H; d.line([(0,y),(W,y)],fill=(int(40+150*t),int(6+20*t),int(14+16*t),255))
for i in range(60): d.point((random.randint(0,W),random.randint(0,200)),fill=(255,200,200,140))
sky.save(R+'backgrounds/boss_sky.png')
far=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(far)
x0=640  # main hall
d.rectangle([x0-260,330,x0+260,520],fill=(40,10,18,255))
d.polygon([(x0-340,350),(x0-200,270),(x0+200,270),(x0+340,350),(x0+260,340),(x0-260,340)],fill=(20,6,12,255))
d.polygon([(x0-220,270),(x0-120,210),(x0+120,210),(x0+220,270)],fill=(20,6,12,255))
for c in range(-220,240,55): d.rectangle([x0+c,350,x0+c+12,520],fill=(120,20,24,255))
d.rectangle([0,500,W,H],fill=(30,10,16,255))
far.save(R+'backgrounds/boss_far.png')
near=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(near); C=(18,6,10,255)
def stone_lantern(x):
    d.rectangle([x-8,560,x+8,640],fill=C); d.rectangle([x-22,530,x+22,560],fill=C); d.rectangle([x-12,538,x+12,552],fill=(255,170,80,255))
    d.polygon([(x-34,532),(x,505),(x+34,532)],fill=C); d.rectangle([x-20,636,x+20,646],fill=C)
for x in [160,400,880,1120]: stone_lantern(x)
for x in [40,1210]:
    d.rectangle([x,380,x+30,640],fill=C); d.ellipse([x-90,300,x+120,420],fill=(24,8,14,255))
d.rectangle([0,640,W,H],fill=(26,10,16,255))
for x in range(0,W,64): d.line([(x,640),(x+40,H)],fill=(40,16,22,255),width=2)
near.save(R+'backgrounds/boss_near.png')
print('boss ok')
