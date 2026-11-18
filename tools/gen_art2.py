# Original hero "Hakuro" (indigo-black hair, half-face oni-detail ninja mask, scarf collar, blue aura) + Kyoto backdrop. CC0, in-repo.
from PIL import Image, ImageDraw, ImageFilter
import math, random
R='assets/'; S=4
OUT=(12,12,20,255)
def P(pts): return [(x*S,y*S) for x,y in pts]
def hero(pose,path):
    im=Image.new('RGBA',(64*S,64*S)); d=ImageDraw.Draw(im)
    lean={'idle':0,'run':5,'jump':0,'dash':10,'wall':-3}[pose]
    coat=(28,30,46,255); trim=(60,190,200,255); hair=(34,30,72,255); skin=(238,214,196,255)
    # coat tails (split, trailing)
    tl=-6 if pose in('run','dash') else 0
    d.polygon(P([(25,38),(20+tl,58),(27,56),(31,44)]),fill=coat,outline=OUT,width=S)
    d.polygon(P([(33,44),(36,56),(42+tl*0.3,58),(39,38)]),fill=coat,outline=OUT,width=S)
    # legs
    if pose=='run': L=[[(28,44),(22,60),(27,61),(32,46)],[(34,44),(43,57),(46,53),(38,43)]]
    elif pose=='jump': L=[[(27,44),(24,54),(30,56),(33,45)],[(34,44),(41,49),(44,46),(38,42)]]
    elif pose=='dash': L=[[(30,42),(15,50),(17,55),(34,46)],[(36,42),(31,57),(36,58),(40,44)]]
    else: L=[[(28,44),(26,61),(31,61),(32,45)],[(33,44),(35,61),(40,61),(37,44)]]
    for l in L: d.polygon(P(l),fill=(20,20,30,255),outline=OUT,width=S)
    # torso coat with high collar
    x=lean*0.4
    d.polygon(P([(24+x,24),(40+x,24),(41,46),(23,46)]),fill=coat,outline=OUT,width=S)
    d.line(P([(32+x,26),(32,46)]),fill=trim,width=S)  # zipper trim
    d.polygon(P([(23+x,25),(26+x,19),(38+x,19),(41+x,25),(36+x,27),(28+x,27)]),fill=(150,32,40,255),outline=OUT,width=S)  # crimson wrap scarf
    d.polygon(P([(26+x,24),(16+x-lean*0.5,30),(19+x-lean*0.5,33),(29+x,26)]),fill=(150,32,40,255),outline=OUT,width=S)  # scarf tail
    # arms
    if pose=='dash': d.line(P([(38,30),(52,30)]),fill=coat,width=5*S); d.ellipse([51*S,27*S,57*S,33*S],fill=(120,200,255,255))
    elif pose=='jump': d.line(P([(26,28),(18,18)]),fill=coat,width=5*S)
    else: d.line(P([(40,28),(43,40)]),fill=coat,width=5*S)
    # head
    hx=32+lean*0.6
    d.ellipse([(hx-8)*S,7*S,(hx+8)*S,22*S],fill=skin,outline=OUT,width=S)
    # eyes (visible) + half-face mask over nose/mouth with oni fang detail
    d.rectangle([(hx-8)*S,11*S,(hx+8)*S,15*S],fill=(46,36,48,255))
    d.rectangle([(hx+1)*S,12.5*S,(hx+3)*S,13.5*S],fill=(90,200,255,255)); d.rectangle([(hx-4)*S,12.5*S,(hx-2)*S,13.5*S],fill=(90,200,255,255))
    d.chord([(hx-8)*S,8*S,(hx+8)*S,22*S],0,180,fill=(22,22,34,255))
    d.rectangle([(hx-8)*S,15*S,(hx+8)*S,16*S],fill=(22,22,34,255))
    for fx in (hx-4,hx+3): d.polygon(P([(fx,17),(fx+1.5,20),(fx+3,17)]),fill=(230,230,236,255))
    d.line(P([(hx-6,16),(hx+6,16)]),fill=(150,32,40,255),width=S)
    # white spiky hair, swept back (own silhouette: tall rear spikes)
    sp=[(hx-9,12),(hx-16,4),(hx-8,6),(hx-10,-2),(hx-2,4),(hx,-4),(hx+4,4),(hx+10,0),(hx+8,7),(hx+13,8),(hx+8,11)]
    d.polygon(P(sp),fill=hair,outline=(70,70,130,255),width=S)
    im=im.resize((64,64),Image.LANCZOS)
    # blue aura
    a=im.split()[3].filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(3))
    glow=Image.new('RGBA',(64,64),(80,170,255,0)); glow.putalpha(a.point(lambda v:int(v*0.55)))
    glow.alpha_composite(im); glow.save(R+path)
for p in ['idle','run','jump','dash','wall']: hero(p,f'sprites/player_{p}.png')
# Kyoto backdrop layers
W,H=1280,720
def grad(top,bot):
    im=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(im)
    for y in range(H):
        t=y/H; d.line([(0,y),(W,y)],fill=tuple(int(top[i]*(1-t)+bot[i]*t) for i in range(3))+(255,))
    return im
sky=grad((44,32,78),(240,150,120)); d=ImageDraw.Draw(sky)
random.seed(3)
for i in range(80): d.point((random.randint(0,W),random.randint(0,250)),fill=(255,255,255,150))
sky.save(R+'backgrounds/bg_sky.png')
moon=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(moon); d.ellipse([1000,120,1110,230],fill=(255,236,214,230)); moon.save(R+'backgrounds/bg_moon.png')
# far: hills + five-story pagoda + temple roofs
far=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(far)
pts=[(0,H)]+[(x,430-60*math.sin(x/210)-30*math.sin(x/77)) for x in range(0,W+1,20)]+[(W,H)]; d.polygon(pts,fill=(92,70,110,255))
def pagoda(x0,base,col,roof):
    for k in range(5):
        w=70-k*10; y=base-k*46
        d.rectangle([x0-w*0.55,y-34,x0+w*0.55,y],fill=col)
        d.polygon([(x0-w-14,y-30),(x0-w*0.4,y-46),(x0+w*0.4,y-46),(x0+w+14,y-30),(x0+w*0.6,y-36),(x0-w*0.6,y-36)],fill=roof)
    d.line([(x0,base-5*46-10),(x0,base-5*46-60)],fill=roof,width=4)
pagoda(330,470,(70,52,82,255),(52,38,62,255))
for x0 in [700,880]:
    d.rectangle([x0-70,430,x0+70,480],fill=(70,52,82,255)); d.polygon([(x0-110,440),(x0-60,400),(x0+60,400),(x0+110,440)],fill=(52,38,62,255))
far.save(R+'backgrounds/bg_mountains.png')
# near: bamboo grove + machiya street + torii row
near=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(near)
for i in range(26):
    x=random.randint(0,W); col=(40,70,60,255)
    d.rectangle([x,200,x+9,620],fill=col)
    for y in range(230,620,48): d.line([(x,y),(x+9,y)],fill=(28,50,44,255),width=2)
    for k in range(3): d.polygon([(x+5,220+k*60),(x+40,232+k*60),(x+5,226+k*60)],fill=(46,86,66,255))
for i,x0 in enumerate(range(40,W,170)):  # machiya houses
    d.rectangle([x0,520,x0+150,640],fill=(58,36,30,255))
    for xx in range(x0+6,x0+150,8): d.line([(xx,540),(xx,600)],fill=(80,52,40,255),width=3)  # lattice
    d.polygon([(x0-14,528),(x0+8,500),(x0+142,500),(x0+164,528)],fill=(34,30,38,255))
    d.rectangle([x0+60,560,x0+90,600],fill=(255,190,110,255))  # lit window
for x0 in [520,600,680]:  # torii row
    c=(196,48,40,255); d.rectangle([x0,470,x0+8,640],fill=c); d.rectangle([x0+56,470,x0+64,640],fill=c)
    d.polygon([(x0-12,462),(x0+76,462),(x0+70,472),(x0-6,472)],fill=(26,22,26,255)); d.rectangle([x0-2,484,x0+66,490],fill=c)
d.rectangle([0,632,W,H],fill=(36,28,34,255))
near.save(R+'backgrounds/bg_trees.png')
# mist + petal + paper lantern + stone lantern checkpoint
mist=Image.new('RGBA',(W,200)); d=ImageDraw.Draw(mist)
for i in range(40): x=random.randint(-100,W); y=random.randint(60,160); d.ellipse([x,y,x+260,y+60],fill=(235,225,240,22))
mist.filter(ImageFilter.GaussianBlur(12)).save(R+'backgrounds/bg_mist.png')
pe=Image.new('RGBA',(12*S,12*S)); d=ImageDraw.Draw(pe); d.ellipse([1*S,3*S,11*S,9*S],fill=(255,182,206,255)); pe.resize((12,12),Image.LANCZOS).save(R+'sprites/petal.png')
la=Image.new('RGBA',(24*S,44*S)); d=ImageDraw.Draw(la)
d.line([12*S,0,12*S,8*S],fill=(30,30,30,255),width=S); d.ellipse([2*S,8*S,22*S,40*S],fill=(230,70,50,255),outline=(60,20,20,255),width=S)
for y in [16,24,32]: d.line([4*S,y*S,20*S,y*S],fill=(150,40,30,255),width=S)
d.ellipse([7*S,16*S,17*S,32*S],fill=(255,210,120,160))
la.resize((24,44),Image.LANCZOS).save(R+'sprites/paper_lantern.png')
glow=Image.new('RGBA',(128,128)); d=ImageDraw.Draw(glow); d.ellipse([20,20,108,108],fill=(255,170,80,120)); glow.filter(ImageFilter.GaussianBlur(18)).save(R+'sprites/glow.png')
# app icon refresh
ic=grad((40,30,80),(70,140,230)).resize((512,512)); n=Image.open(R+'sprites/player_idle.png').resize((420,420),Image.NEAREST); ic.alpha_composite(n,(46,50)); ic.save(R+'ui/icon_512.png'); ic.resize((192,192),Image.LANCZOS).save(R+'ui/icon_192.png')
print('ok')
