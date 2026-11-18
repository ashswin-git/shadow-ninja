# Original procedural art for Aether Shinobi (CC0, made in-repo). Supersampled PIL.
from PIL import Image, ImageDraw, ImageFilter
import math, random, os
R='assets/'
S=4
def canvas(w,h): return Image.new('RGBA',(w*S,h*S),(0,0,0,0))
def fin(im,w,h,p): im.resize((w,h),Image.LANCZOS).save(R+p)
def P(pts): return [(x*S,y*S) for x,y in pts]
def E(d,b,fill=None,outline=None,width=0): d.ellipse([v*S for v in b],fill=fill,outline=outline,width=width*S)
OUT=(14,10,22,255)
def ninja(pose, cloth=(38,34,58,255), scarf=(214,48,62,255), skin=(246,214,190,255), eye=(80,200,255,255), path='sprites/player_idle.png', blade=True, w=64,h=64, hood=True):
    im=canvas(w,h); d=ImageDraw.Draw(im)
    lean={'idle':0,'run':6,'jump':0,'dash':12,'wall':-4}[pose]
    # scarf trailing
    sw=[(30,22),(20+lean*-0.5,20),(8,24 if pose!='dash' else 18),(4,30 if pose=='idle' else 22),(14,26),(28,26)]
    d.polygon(P(sw),fill=scarf,outline=OUT,width=S)
    # legs
    if pose=='run': legs=[[(28,44),(22,58),(27,60),(33,46)],[(34,44),(42,56),(46,52),(38,43)]]
    elif pose=='jump': legs=[[(27,44),(24,54),(30,56),(33,45)],[(34,44),(40,50),(44,47),(38,42)]]
    elif pose=='dash': legs=[[(30,42),(16,52),(18,56),(34,46)],[(36,42),(30,56),(35,57),(40,44)]]
    else: legs=[[(27,44),(25,60),(31,60),(32,45)],[(33,44),(35,60),(41,60),(38,44)]]
    for l in legs: d.polygon(P(l),fill=cloth,outline=OUT,width=S)
    # torso
    t=[(24+lean*0.3,26),(40+lean*0.5,26),(40,46),(24,46)]
    d.polygon(P(t),fill=cloth,outline=OUT,width=S)
    d.rectangle([24*S,38*S,40*S,41*S],fill=scarf)  # obi belt
    # katana on back / held
    if blade:
        if pose in('dash','run'): d.line(P([(40,34),(60,28)]),fill=(220,230,240,255),width=2*S); d.line(P([(36,35),(41,34)]),fill=(90,60,30,255),width=3*S)
        else: d.line(P([(22,46),(42,18)]),fill=(200,210,225,255),width=2*S); d.line(P([(20,49),(24,44)]),fill=(90,60,30,255),width=3*S)
    # head
    hx=32+lean*0.6
    E(d,(hx-11,8,hx+11,30),fill=cloth if hood else skin,outline=OUT,width=1)
    # face band
    d.rectangle([(hx-9)*S,15*S,(hx+10)*S,22*S],fill=skin)
    E(d,(hx+1,16,hx+6,21),fill=eye); E(d,(hx+3,16.5,hx+5,18.5),fill=(255,255,255,255))
    d.line(P([(hx,15),(hx+8,14)]),fill=OUT,width=S)
    # headband tails
    d.line(P([(hx-10,13),(hx-18,10),(hx-22,14)]),fill=scarf,width=2*S)
    d.rectangle([(hx-11)*S,11*S,(hx+11)*S,14*S],fill=scarf)
    # arms
    if pose=='jump': d.line(P([(28,30),(20,20)]),fill=cloth,width=4*S)
    fin(im,w,h,path)
os.makedirs(R+'sprites',exist_ok=True); os.makedirs(R+'ui',exist_ok=True)
for p in ['idle','run','jump','dash','wall']: ninja(p,path=f'sprites/player_{p}.png')
# enemies: oni foot soldier and archer (original)
def oni(path,col,ranged):
    im=canvas(64,64); d=ImageDraw.Draw(im)
    d.polygon(P([(18,58),(22,30),(42,30),(46,58)]),fill=(50,40,46,255),outline=OUT,width=S)
    d.rectangle([20*S,40*S,44*S,44*S],fill=(150,120,60,255))
    E(d,(18,8,46,34),fill=col,outline=OUT,width=1)
    d.polygon(P([(22,12),(18,2),(26,10)]),fill=(240,230,200,255),outline=OUT,width=S)
    d.polygon(P([(42,12),(46,2),(38,10)]),fill=(240,230,200,255),outline=OUT,width=S)
    E(d,(24,17,30,23),fill=(255,230,80,255)); E(d,(34,17,40,23),fill=(255,230,80,255))
    d.line(P([(26,28),(38,28)]),fill=OUT,width=2*S)
    if ranged: d.arc([44*S,14*S,62*S,54*S],-80,80,fill=(110,70,30,255),width=2*S)
    else: d.line(P([(48,56),(56,20)]),fill=(110,70,30,255),width=3*S); d.polygon(P([(56,20),(53,10),(60,12)]),fill=(210,215,225,255))
    fin(im,64,64,path)
oni('sprites/enemy_patrol.png',(196,72,60,255),False)
oni('sprites/enemy_ranged.png',(70,110,170,255),True)
def boss(path,col,acc):
    im=canvas(128,128); d=ImageDraw.Draw(im)
    d.polygon(P([(24,124),(34,52),(94,52),(104,124)]),fill=col,outline=OUT,width=2*S)
    d.polygon(P([(30,56),(10,44),(34,70)]),fill=acc,outline=OUT,width=S); d.polygon(P([(98,56),(118,44),(94,70)]),fill=acc,outline=OUT,width=S)
    E(d,(38,10,90,62),fill=(230,220,210,255),outline=OUT,width=2)
    d.polygon(P([(44,18),(36,0),(54,14)]),fill=acc,outline=OUT,width=S); d.polygon(P([(84,18),(92,0),(74,14)]),fill=acc,outline=OUT,width=S)
    d.polygon(P([(46,30),(58,34),(46,38)]),fill=(255,60,60,255)); d.polygon(P([(82,30),(70,34),(82,38)]),fill=(255,60,60,255))
    d.line(P([(50,50),(78,50)]),fill=OUT,width=3*S)
    d.line(P([(108,120),(120,30)]),fill=(200,210,230,255),width=4*S)
    fin(im,128,128,path)
boss('sprites/boss1.png',(70,80,110,255),(160,200,230,255))
boss('sprites/boss2.png',(100,90,80,255),(200,150,80,255))
boss('sprites/boss3.png',(60,60,70,255),(150,90,200,255))
# coin (spirit koban)
im=canvas(32,32); d=ImageDraw.Draw(im)
E(d,(3,5,29,27),fill=(240,190,50,255),outline=(120,70,10,255),width=2); E(d,(8,9,24,23),outline=(255,235,140,255),width=1)
d.rectangle([14*S,12*S,18*S,20*S],fill=(150,90,20,255)); fin(im,32,32,'sprites/coin.png'); fin(im,48,48,'ui/coin_icon.png')
# heart icons
def heart(path,fill):
    im=canvas(48,48); d=ImageDraw.Draw(im)
    pts=[(24+16*math.sin(t)**3, 22-(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))) for t in [i/60*2*math.pi for i in range(60)]]
    d.polygon(P(pts),fill=fill,outline=(40,10,20,255),width=2*S)
    if fill[3]: E(d,(12,12,19,19),fill=(255,255,255,170))
    fin(im,48,48,path)
heart('ui/heart_full.png',(230,50,70,255)); heart('ui/heart_empty.png',(60,40,55,200))
# tile: stone with snow
im=canvas(64,32); d=ImageDraw.Draw(im)
d.rectangle([0,0,64*S,32*S],fill=(62,58,74,255))
for i in range(0,64,16): d.line(P([(i,10),(i,32)]),fill=(40,36,50,255),width=S)
d.line(P([(0,21),(64,21)]),fill=(40,36,50,255),width=S)
d.rectangle([0,0,64*S,8*S],fill=(232,238,248,255))
for x in range(0,64,8): E(d,(x-2,5,x+7,11),fill=(232,238,248,255))
fin(im,64,32,'sprites/tile.png')
# spike / saw / checkpoint / portal / shuriken / kunai
im=canvas(32,32); d=ImageDraw.Draw(im)
for x in range(0,32,8): d.polygon(P([(x,32),(x+4,8),(x+8,32)]),fill=(170,175,190,255),outline=OUT,width=S)
fin(im,32,32,'sprites/spike.png')
im=canvas(32,32); d=ImageDraw.Draw(im)
for k in range(4):
    a=k*math.pi/2; d.polygon(P([(16,16),(16+15*math.cos(a),16+15*math.sin(a)),(16+6*math.cos(a+0.9),16+6*math.sin(a+0.9))]),fill=(190,200,215,255),outline=OUT,width=S)
E(d,(13,13,19,19),fill=OUT); fin(im,32,32,'sprites/shuriken.png'); fin(im,32,32,'sprites/saw.png')
im=canvas(32,32); d=ImageDraw.Draw(im); d.line(P([(2,16),(24,16)]),fill=(200,205,220,255),width=3*S); d.polygon(P([(24,12),(31,16),(24,20)]),fill=(200,205,220,255)); fin(im,32,32,'sprites/kunai.png')
im=canvas(32,64); d=ImageDraw.Draw(im)  # stone lantern checkpoint
d.rectangle([12*S,30*S,20*S,62*S],fill=(110,105,120,255),outline=OUT,width=S); d.polygon(P([(4,22),(16,12),(28,22)]),fill=(90,85,100,255),outline=OUT,width=S)
d.rectangle([9*S,22*S,23*S,30*S],fill=(255,180,80,255),outline=OUT,width=S); fin(im,32,64,'sprites/checkpoint.png')
im=canvas(64,96); d=ImageDraw.Draw(im)  # torii portal
red=(200,40,40,255)
d.rectangle([12*S,20*S,18*S,96*S],fill=red,outline=OUT,width=S); d.rectangle([46*S,20*S,52*S,96*S],fill=red,outline=OUT,width=S)
d.polygon(P([(0,10),(64,10),(60,18),(4,18)]),fill=(30,26,30,255)); d.rectangle([6*S,26*S,58*S,31*S],fill=red,outline=OUT,width=S)
E(d,(20,36,44,90),fill=(120,220,255,120)); fin(im,64,96,'sprites/portal.png')
# parallax backgrounds 1280x720 (drawn at 1x, large)
random.seed(7)
def grad(top,bot,w=1280,h=720):
    im=Image.new('RGBA',(w,h)); d=ImageDraw.Draw(im)
    for y in range(h):
        t=y/h; d.line([(0,y),(w,y)],fill=tuple(int(top[i]*(1-t)+bot[i]*t) for i in range(3))+(255,))
    return im
sky=grad((26,30,64),(196,140,150)); d=ImageDraw.Draw(sky)
for i in range(120): x,y=random.randint(0,1280),random.randint(0,300); d.point((x,y),fill=(255,255,255,random.randint(80,220)))
sky.save(R+'backgrounds/bg_sky.png')
moon=Image.new('RGBA',(1280,720),(0,0,0,0)); d=ImageDraw.Draw(moon)
d.ellipse([980,150,1100,270],fill=(255,240,220,235)); moon=moon.filter(ImageFilter.GaussianBlur(1)); moon.save(R+'backgrounds/bg_moon.png')
def ridge(base,amp,col,seed,snow=False):
    random.seed(seed); im=Image.new('RGBA',(1280,720),(0,0,0,0)); d=ImageDraw.Draw(im)
    pts=[(0,720)]; y=base
    for x in range(0,1281,40):
        y=base-abs(math.sin(x/170+seed))*amp-random.randint(0,amp//4); pts.append((x,y))
    pts.append((1280,720)); d.polygon(pts,fill=col)
    if snow:
        for (x,y) in pts[1:-1]:
            if y<base-amp*0.7: d.polygon([(x-18,y+14),(x,y),(x+18,y+14)],fill=(225,230,245,255))
    return im
ridge(470,220,(70,70,110,255),1,True).save(R+'backgrounds/bg_mountains.png')
tr=ridge(600,60,(36,40,66,255),3); d=ImageDraw.Draw(tr)
for i in range(18):
    x=random.randint(0,1280); h=random.randint(120,220); d.rectangle([x-4,600-h+40,x+4,620],fill=(30,32,52,255))
    for k in range(4): d.polygon([(x-40+k*6,600-h+60+k*30),(x,600-h+k*30),(x+40-k*6,600-h+60+k*30)],fill=(32,46,62,255))
# pagoda silhouette
x0=260
for k in range(4): d.rectangle([x0-50+k*8,520-k*50,x0+50-k*8,560-k*50],fill=(28,30,48,255)); d.polygon([(x0-75+k*8,522-k*50),(x0,500-k*50),(x0+75-k*8,522-k*50)],fill=(22,24,40,255))
tr.save(R+'backgrounds/bg_trees.png')
# app icon 512
ic=grad((40,30,80),(200,60,80),512,512)
n=Image.open(R+'sprites/player_idle.png').resize((400,400),Image.NEAREST); ic.alpha_composite(n,(56,70))
ic.save(R+'ui/icon_512.png'); ic.resize((192,192),Image.LANCZOS).save(R+'ui/icon_192.png')
print('ok')
